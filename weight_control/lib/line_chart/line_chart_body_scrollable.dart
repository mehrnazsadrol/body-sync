import 'calculate_interval.dart';
import '../layout/custom_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/data_handler.dart';
import 'line_chart_dot_painter.dart';
import 'line_chart_tooltip_painter.dart';
import 'line_chart_path_creator.dart';

class LineChartBodyScrollable extends StatefulWidget {
  final CalculateInterval calculateInterval;
  final List<MapEntry<DateTime, int>> data;

  LineChartBodyScrollable({required this.calculateInterval, required this.data});

  @override
  _LineChartBodyScrollableState createState() => _LineChartBodyScrollableState();
}

class _LineChartBodyScrollableState extends State<LineChartBodyScrollable> {
  Offset? _touchPosition;
  final GlobalKey _widgetKey = GlobalKey();
  double? widgetHeight;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widgetHeight = getWidgetHeight();
      print('widgetHeight: $widgetHeight');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      print('No data available');
      return Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Color(0xFFfff4ee),
          border: Border.all(color: Color(0xFFfff4ee)),
        ),
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    final dataHandler = Provider.of<DataHandler>(context);
    final size = Size(
      MediaQuery.of(context).size.width * 0.85,
      MediaQuery.of(context).size.height * 0.5,
    );

    final double widthPerDay = widget.calculateInterval.getWidthPerDay(size);
    final DateTime earliestDate = dataHandler.getEarliestDate(widget.data);
    final double totalWidth = widthPerDay * (DateTime.now().difference(earliestDate).inDays + 2);

    final pathCreator = LineChartPathCreator(
      size: Size(totalWidth, size.height),
      widthPerDay: widthPerDay,
      data: widget.data,
      earliestDate: earliestDate,
    );

    final Path? areaPath = pathCreator.createPath();

    final List<Offset> points = pathCreator.getPoints();
    final List<Offset> quadraticBezierPoints = pathCreator.getQuadraticBezierPoints();


    if (areaPath == null) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Color(0xFFfff4ee),
          border: Border.all(color: Color(0xFFfff4ee)),
        ),
      );
    }

    return Container(
      key: _widgetKey,
      width: totalWidth,
      height: size.height,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFfff4ee)),
      ),
      child: Stack ( 
        children: [
          Listener(
            onPointerDown: (details) {
              if (areaPath.contains(details.localPosition)) {
                double? y = pathCreator.getYForX(details.localPosition.dx);
                print('y: $y');
                setState(() {
                  if (y != null) {
                    _touchPosition = Offset(details.localPosition.dx, y);
                  }
                });
              }
            },
            onPointerUp: (details) {
              setState(() {
                _touchPosition = null;
              });
            },
            child: ClipPath(
              clipper: _AreaClipper(areaPath), // Use the path to clip the contents
              child: CustomGridBackground(
                width: totalWidth,
                height: size.height,
                colors: [
                  Color(0xff7fd1ae), 
                  Color(0xff7fd1ae), 
                  Color(0xff7fd1ae), 
                  Color(0xffFF9B82), 
                  Color(0xFFfd536a)
                ],
              ),
            ),
          ),
          CustomPaint(
            painter: LineChartDotPainter(
              points: points,
              quadraticBezierPoints: quadraticBezierPoints,
              data: widget.data,
            ),
          ),
          if (_touchPosition != null)
            CustomPaint(
              painter: TooltipPainter(
                height: widgetHeight!,
                touchPosition: _touchPosition!,
                value: pathCreator.getValueForY(_touchPosition!.dy)
              ),
            ),
        ],
      ),
    );
  }

  double getWidgetHeight() {
    final RenderBox renderBox = _widgetKey.currentContext?.findRenderObject() as RenderBox;
    return renderBox.size.height;
  }
}



class _AreaClipper extends CustomClipper<Path> {
  final Path path;

  _AreaClipper(this.path);

  @override
  Path getClip(Size size) {
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}


import 'calculate_interval.dart';
import '../layout/custom_background.dart';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/data_handler.dart';

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


class TooltipPainter extends CustomPainter {
  double height;
  final Offset touchPosition;
  final int value;
  final formattedText;

  TooltipPainter({
    required this.height,
    required this.touchPosition,
    required this.value}) : formattedText = value<0 ? 'No data' : value.toStringAsFixed(0);



  @override
  void paint(Canvas canvas, Size size) {

    print('touchPosition: $touchPosition, value: $value');

    Paint linePaint = Paint()
      ..color = Color(0xFFd5626a)
      ..strokeWidth = 2.0;

    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: formattedText,
        style: TextStyle(color:Color.fromARGB(255, 255, 255, 255), fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.layout(
            minWidth: 0,
            maxWidth: 80,
    );
    final offset = Offset(touchPosition.dx - textPainter.width -5  , touchPosition.dy - 30);


    final rect = Rect.fromLTWH(
      offset.dx - 5,
      offset.dy - 5,
      textPainter.width + 10,
      textPainter.height + 10,
    );
    Paint rectPaint = Paint()
      ..color = Color(0xFFd5626a)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, rectPaint);
    textPainter.paint(canvas, offset);

    print('size.height, touchPosition.dy: ${height}, ${touchPosition.dy}');
    canvas.drawLine(
      Offset(touchPosition.dx, height+12),
      Offset(touchPosition.dx, touchPosition.dy),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
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

class LineChartPathCreator {
  final List<MapEntry<DateTime, int>> data;
  final Size size;
  final double widthPerDay;
  final DateTime earliestDate;
  final List<Offset> points = [];
  final List<Offset> quadraticBezierPoints = [];
  final double maxY;
   
  List<Offset> getQuadraticBezierPoints() {
    return quadraticBezierPoints;
  }

  List<Offset> getPoints() {
    return points;
  }

  LineChartPathCreator({
    required this.size,
    required this.data,
    required this.widthPerDay,
    required this.earliestDate,
  }) : maxY = data.isNotEmpty ? (data.map((entry) => entry.value).reduce((a, b) => a > b ? a : b) * 1.2) : 1 * 1.2;

  double? getYForX(double x) {
    print('getYForX - x: $x');
    print('quadraticBezierPoints: $quadraticBezierPoints');
    int idx = 0;
    if (quadraticBezierPoints.isEmpty) {
      return -1;
    }

    Offset currpoint = quadraticBezierPoints[idx];
    print('currpoint: $currpoint');
    double currX = currpoint.dx;
    while(idx < quadraticBezierPoints.length-1 && x > currX) {
      print('currX: $currX');
      idx++;
      currX = quadraticBezierPoints[idx].dx;
    }
    print('idx: $idx');
    if (x == quadraticBezierPoints[idx].dx) {
      return quadraticBezierPoints[idx].dy;
    }
    if (idx == quadraticBezierPoints.length-1) {
      Offset nextPoint = points[idx];
      Offset currpoint = quadraticBezierPoints[idx];
      double slope = (nextPoint.dy - currpoint.dy) / (nextPoint.dx - currpoint.dx);
      double y = slope * (x - currpoint.dx) + currpoint.dy;
      return y;
    }
    Offset? startPoint;
    Offset? controlpoint;
    Offset? endpoint;
    //now we know x is betewen idx-1 and idx and controll is point[idx]
    if (x == points[idx].dx) {
      return points[idx].dy;
    } else {
      startPoint = quadraticBezierPoints[idx - 1];
      controlpoint = points[idx];
      endpoint = quadraticBezierPoints[idx];

      double a = startPoint.dx - 2 * controlpoint.dx + endpoint.dx;
      double b = 2 * (controlpoint.dx - startPoint.dx);
      double c = startPoint.dx - x;

      double discriminant = b * b - 4 * a * c;
      if (discriminant < 0) {
        print('discriminant < 0');
        return -1;
      } 


      double sqrtDiscriminant = sqrt(discriminant);
      print('sqrtDiscriminant: $sqrtDiscriminant');

      // Two possible values of t
      double t1 = (-b + sqrtDiscriminant) / (2 * a);
      double t2 = (-b - sqrtDiscriminant) / (2 * a);
      print('t1: $t1, t2: $t2');
      // Choose the value of t that's between 0 and 1
      double t = (t1 >= 0 && t1 <= 1) ? t1 : t2;

      if (t < 0 || t > 1) {
        print('no valid t');
        return -1;
      }

      // Compute y(t)
      double y = pow((1 - t), 2) * startPoint.dy +
          2 * (1 - t) * t * controlpoint.dy +
          pow(t, 2) * endpoint.dy;

      return y;
    }
  }


  int getValueForY(double y) {
    if (y < 0) {
      return y.toInt();
    } else {
      return (((size.height - y) / size.height) * maxY).toInt();
    }
  }

  Path? createPath() {
    final Path areaPath = Path();
    print('createPath');
    points.add(Offset(0, size.height));

    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final int daysFromStart = entry.key.difference(earliestDate).inDays+1;
      final double x = daysFromStart * widthPerDay;
      final double y = size.height  - (entry.value / maxY) * size.height;
      points.add(Offset(x, y));
    }
    Offset? previousPoint;
    Offset? currentPoint;
    Offset? nextPoint;
    for (int i = 0; i < points.length; i++) { 
      final point = points[i];
      if (i == 0) {
        areaPath.moveTo(point.dx, point.dy);
        quadraticBezierPoints.add(point);
      } else if (i < points.length - 1) {
        previousPoint = points[i - 1];
        currentPoint = points[i];
        nextPoint = points[i + 1];

        final controlPoint = currentPoint;
        final endPoint = Offset(
          (currentPoint.dx + nextPoint.dx) / 2,
          (currentPoint.dy + nextPoint.dy) / 2,
        );

        quadraticBezierPoints.add(endPoint);

        areaPath.quadraticBezierTo(
          controlPoint.dx, controlPoint.dy,
          endPoint.dx, endPoint.dy,
        );
      } else {
        areaPath.lineTo(point.dx, point.dy);
      }
    }

    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();

    return areaPath;
  }

}


class LineChartDotPainter extends CustomPainter {
  final List<Offset> points;
  final List<Offset> quadraticBezierPoints;
  final List<MapEntry<DateTime, int>> data;

  LineChartDotPainter({
    required this.points,
    required this.quadraticBezierPoints,
    required this.data,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final redPaint = Paint()
      ..color = Color(0xFFd5626a)
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: Color(0xFFd5626a),
      fontSize: 12,
    );
    // Draw red dots for points
    for (var point in points) {
      if (!quadraticBezierPoints.contains(point)) {
        canvas.drawCircle(point, 3.0, redPaint);
      }
      int idx = points.indexOf(point);
      if(idx> 0) {
        MapEntry<DateTime, int> entry = data[idx-1];
        int date = entry.key.day;
        int value = entry.value;
        final textSpan = TextSpan(
            text: '${value}',
            style: textStyle,
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(
            minWidth: 0,
            maxWidth: 80,
          );
          final offset = Offset(point.dx - textPainter.width, point.dy - 20);
          textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
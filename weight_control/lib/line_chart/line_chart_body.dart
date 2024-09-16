import 'package:flutter/material.dart';
import 'calculate_interval.dart';
import '../custom_background.dart';
import 'dart:ui'; // Add this import

class LineChartBody extends StatelessWidget {
  final CalculateInterval calculateInterval;
  final Map<DateTime, int> data;

  LineChartBody({required this.calculateInterval, required this.data});

  @override
  Widget build(BuildContext context) {
    final intervalData = calculateInterval.getInterval();
    final int totalDays = intervalData['totalDays']!;
    final DateTime intervalStartDate = DateTime.parse(intervalData['intervalStartDate']!);
    
    final RenderBox containerBox = context.findRenderObject() as RenderBox;
    final Offset containerPosition = containerBox.localToGlobal(Offset.zero);


    final pathCreator = LineChartPathCreator(
      totalDays: totalDays,
      intervalStartDate: intervalStartDate,
      data: data,
      containerPosition: containerPosition,
    );

    final size = Size(
      MediaQuery.of(context).size.width * 0.85,
      MediaQuery.of(context).size.height * 0.5,
    );

    final Path? areaPath = pathCreator.createPath(size);

    if (areaPath == null) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Color.fromRGBO(102, 102, 102, 0.587),
          border: Border.all(color: Color.fromRGBO(102, 102, 102, 0.587)),
        ),
      );
    }

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Color.fromRGBO(102, 102, 102, 0.587),
        border: Border.all(color: Color.fromRGBO(102, 102, 102, 0.587)),
      ),
      child: Stack(
        children: [
          ClipPath(
            clipper: _AreaClipper(areaPath),
            child: CustomGridBackground(
              width: size.width,
              height: size.height,
              colors: [Color(0xFF14293A), Color(0xff3B9C8D), Color(0xffD8B06E), Color(0xffF1A292)]
            ),
          ),
        ],
      ),
    );
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



    // return Container(
    //   key: _containerKey,
    //   width: MediaQuery.of(context).size.width * 0.85,
    //   height: 5, // Define a height for the X-axis painter
    //   decoration: BoxDecoration(
    //     border: Border.all(color: Color.fromARGB(255, 163, 122, 238)), // Add a border
    //   ),
    //   child: CustomPaint(
    //     painter: LineChartPainter(
    //       totalDays: totalDays,
    //       intervalStartDate: intervalStartDate,
    //       data: widget.data, 
    //       containerKey: _containerKey
    //     ),
    //   )
    // );

class LineChartPathCreator {
  final int totalDays;
  final Map<DateTime, int> data;
  final DateTime intervalStartDate;
  final Offset containerPosition;

  LineChartPathCreator({
    required this.totalDays,
    required this.intervalStartDate,
    required this.data,
    required this.containerPosition,
  });

  Path? createPath(Size size) {
    final double spacing = size.width / totalDays;
    final List<Offset> points = [];

    final int maxValue = data.values.isNotEmpty ? data.values.reduce((a, b) => a > b ? a : b) : 1;
    final double maxY = 1.2 * maxValue;

    final double containerStartX = containerPosition.dx;

    final filteredData = data.entries.where((entry) => entry.key.isAfter(intervalStartDate)).toList();

    if (filteredData.isNotEmpty) {
      final Path areaPath = Path();
      areaPath.moveTo(containerStartX, size.height);

      for (var entry in filteredData) {
        final int daysFromStart = entry.key.difference(intervalStartDate).inDays;
        final double x = containerStartX + daysFromStart * spacing;
        final double y = size.height - (entry.value / maxY) * size.height;
        points.add(Offset(x, y));
        areaPath.lineTo(x, y);
      }

      areaPath.lineTo(points.last.dx, size.height);
      areaPath.close();
      return areaPath;
    }
    return null;
  }
}




















class LineChartPainter extends CustomPainter {
  final int totalDays;
  final Map<DateTime, int> data;
  final DateTime intervalStartDate;
  final GlobalKey containerKey;
  Path? areaPath;

  LineChartPainter({
    required this.totalDays,
    required this.intervalStartDate,
    required this.data,
    required this.containerKey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // final paint = Paint()
    //   ..color = Colors.blue
    //   ..strokeWidth = 2.0
    //   ..style = PaintingStyle.stroke;

    // final pointPaint = Paint()
    //   ..color = Colors.red
    //   ..strokeWidth = 4.0
    //   ..style = PaintingStyle.fill;

    final double spacing = size.width / totalDays;
    final List<Offset> points = [];


    final int maxValue = data.values.isNotEmpty ? data.values.reduce((a, b) => a > b ? a : b) : 1;
    final double maxY = 1.3 * maxValue;

    final RenderBox containerBox = containerKey.currentContext!.findRenderObject() as RenderBox;
    final Offset containerPosition = containerBox.localToGlobal(Offset.zero);
    final double containerStartX = containerPosition.dx;

    final filteredData = data.entries.where((entry) => entry.key.isAfter(intervalStartDate)).toList();

    if (filteredData.isNotEmpty) {
      areaPath = Path();
      areaPath!.moveTo(containerStartX, size.height);

      for (var entry in filteredData) {
        final int daysFromStart = entry.key.difference(intervalStartDate).inDays;
        final double x = containerStartX + daysFromStart * spacing;
        final double y = size.height - (entry.value / maxY) * size.height;
        points.add(Offset(x, y));
        areaPath!.lineTo(x, y);
      }

      areaPath!.lineTo(points.last.dx, size.height);
      areaPath!.close();
    }


    // for (int i = 0; i < points.length - 1; i++) {
    //   canvas.drawLine(points[i], points[i + 1], paint);
    // }


    // for (final point in points) {
    //   canvas.drawCircle(point, 4.0, pointPaint);
    // }
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

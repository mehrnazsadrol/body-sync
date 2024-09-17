import 'calculate_interval.dart';
import '../layout/custom_background.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

class LineChartBodyScrollable extends StatelessWidget {
  final CalculateInterval calculateInterval;
  final List<MapEntry<DateTime, int>> data;

  LineChartBodyScrollable({required this.calculateInterval, required this.data});

  @override
  Widget build(BuildContext context) {
    final size = Size(
      MediaQuery.of(context).size.width * 0.85,
      MediaQuery.of(context).size.height * 0.5,
    );

    final double widthPerDay = calculateInterval.getWidthPerDay(size);
    final DateTime earliestDate = data[0].key;
    final double totalWidth = widthPerDay * (DateTime.now().difference(earliestDate).inDays + 2);

    final pathCreator = LineChartPathCreator(
      widthPerDay: widthPerDay,
      data: data,
      earliestDate: earliestDate,
    );

    final Path? areaPath = pathCreator.createPath(Size(totalWidth, size.height)); 
    final List<Offset> points = pathCreator.getPoints();


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
      width: totalWidth,
      height: size.height,
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFfff4ee)),
      ),
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

class LineChartPathCreator {
  final List<MapEntry<DateTime, int>> data;
  final double widthPerDay;
  final DateTime earliestDate;
  final List<Offset> points = [];


  LineChartPathCreator({
    required this.data,
    required this.widthPerDay,
    required this.earliestDate,
  });



  Path? createPath(Size size) {

    final int maxValue = data.isNotEmpty ? data.map((entry) => entry.value).reduce((a, b) => a > b ? a : b) : 1;
    final double maxY = 1.2 * maxValue;

    final Path areaPath = Path();
    points.add(Offset(0, size.height));

    for (int i = 0; i < data.length; i++) {
      final entry = data[i];
      final int daysFromStart = entry.key.difference(earliestDate).inDays;
      final double x = daysFromStart * widthPerDay;
      final double y = size.height  - (entry.value / maxY) * size.height;
      points.add(Offset(x, y));
    }

    Offset? previousPoint;
    Offset? currentPoint;
    Offset? nextPoint;
    areaPath.moveTo(0, size.height);
    for (int i = 0; i < points.length; i++) { 
      final point = points[i];
      if (i == 0) {
        areaPath.moveTo(point.dx, point.dy);
      } else if (i < points.length - 1) {
        previousPoint = points[i - 1];
        currentPoint = points[i];
        nextPoint = points[i + 1];

        final controlPoint = currentPoint;
        final endPoint = Offset(
          (currentPoint.dx + nextPoint.dx) / 2,
          (currentPoint.dy + nextPoint.dy) / 2,
        );

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

  List<Offset> getPoints() {
    return points;
  }
}
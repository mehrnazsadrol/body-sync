import 'package:flutter/material.dart';
import '../calculate_interval.dart';
import '../../layout/custom_background.dart';
import 'dart:ui';

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
          color: Color(0xFFfff4ee),
          border: Border.all(color: Color(0xFFfff4ee)),
        ),
      );
    }

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Color(0xFFfff4ee),
        border: Border.all(color: Color(0xFFfff4ee)),
      ),
      child: Stack(
        children: [
          ClipPath(
            clipper: _AreaClipper(areaPath),
            child: CustomGridBackground(
              width: size.width,
              height: size.height,
              colors: [Color(0xff7fd1ae), Color(0xff7fd1ae),Color(0xff7fd1ae), Color(0xffFF9B82), Color(0xFFfd536a)]
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
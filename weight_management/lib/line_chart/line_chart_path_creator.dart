import 'dart:math';
import 'package:flutter/material.dart';

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
    int idx = 0;
    if (quadraticBezierPoints.isEmpty) {
      return -1;
    }

    Offset currpoint = quadraticBezierPoints[idx];
    double currX = currpoint.dx;
    while(idx < quadraticBezierPoints.length-1 && x > currX) {
      idx++;
      currX = quadraticBezierPoints[idx].dx;
    }

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

      double a = startPoint.dx - (2 * controlpoint.dx) + endpoint.dx;
      double b = 2 * (controlpoint.dx - startPoint.dx);
      double c = startPoint.dx - x;

      double discriminant = b * b - 4 * a * c;
      double t;
      if (a == 0) {
        t = -c / b;
      } else {
        if (discriminant < 0) {
          return -1;
        }


        double sqrtDiscriminant = sqrt(discriminant);

        // Two possible values of t
        double t1 = (-b + sqrtDiscriminant) / (2 * a);
        double t2 = (-b - sqrtDiscriminant) / (2 * a);

        // Choose the value of t that's between 0 and 1
        t = (t1 >= 0 && t1 <= 1) ? t1 : t2;
      }
      if (t < 0 || t > 1) {
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
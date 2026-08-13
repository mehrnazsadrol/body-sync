import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:body_sync/line_chart/calculate_interval.dart';

void main() {
  group('CalculateInterval', () {
    test('defaults to the most zoomed-in level', () {
      final calculateInterval = CalculateInterval();

      expect(calculateInterval.interval, 3);
      expect(calculateInterval.totalDays, 20);
    });

    test('maps zoom levels to interval and total days', () {
      final calculateInterval = CalculateInterval();

      calculateInterval.setZoomLevel(0.6);
      expect(calculateInterval.interval, 30);
      expect(calculateInterval.totalDays, 180);

      calculateInterval.setZoomLevel(0.4);
      expect(calculateInterval.interval, 60);
      expect(calculateInterval.totalDays, 365);

      calculateInterval.setZoomLevel(0.2);
      expect(calculateInterval.interval, 90);
      expect(calculateInterval.totalDays, 540);

      calculateInterval.setZoomLevel(0.05);
      expect(calculateInterval.interval, 120);
      expect(calculateInterval.totalDays, 730);
    });

    test('getWidthPerDay divides the available width across total days', () {
      final calculateInterval = CalculateInterval();

      expect(calculateInterval.getWidthPerDay(const Size(200, 100)), 200 / 20);
    });

    test('getInterval exposes interval, totalDays and start date', () {
      final calculateInterval = CalculateInterval();
      final intervalData = calculateInterval.getInterval();

      expect(intervalData['interval'], 3);
      expect(intervalData['totalDays'], 20);
      expect(intervalData['intervalStartDate'], isA<String>());
    });
  });
}

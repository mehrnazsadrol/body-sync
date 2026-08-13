import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'theme.dart';
import 'package:intl/intl.dart';

class LineChartWithCustomBackground extends StatelessWidget {
  final List<Color> _colors = [
    Color(0xFF14293A),
    Color(0xff3B9C8D),
    Color(0xffD8B06E),
    Color(0xffF1A292),
  ];

  final List<Color> _colors2 = [
    Color(0xFF2AC4D2),
    Color(0xff4CE3CE),
    Color(0xffFCE9BA),
  ];

  final List<FlSpot> allSpots;
  final DateTime startDate;

  LineChartWithCustomBackground({
    required this.allSpots,
    required this.startDate,
  });

  String formatMonthDay(double value) {
    final DateTime date = startDate.add(Duration(days: value.toInt()));
    final DateFormat formatter = DateFormat('MMM d');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: AppTheme.darkGreen3, width: 1),
              ),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 30, // Adjust the interval for three months view
                    getTitlesWidget: (value, meta) {
                      return Text(
                        formatMonthDay(value),
                        style: const TextStyle(
                          color: AppTheme.darkGreen3,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: allSpots,
                  isCurved: true,
                  barWidth: 0,
                  aboveBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: _colors2,
                      begin: Alignment.topRight,
                      end: Alignment.center,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: _colors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  dotData: const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

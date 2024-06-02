import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'custom_grid_background.dart'; // Adjust the path as needed

class LineChartWithCustomBackground extends StatelessWidget {
  final LineChartData lineChartData;

  LineChartWithCustomBackground({Key? key, required this.lineChartData}) : super(key: key);

  final List<Color> _colors = [
    Color(0xFFFDC63A),
    Color(0xff51C5AC),
    Color(0xffFC8B98),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomGridBackground(
            width: double.infinity, // Fill the available width
            height: double.infinity, // Fill the available height
            colors: _colors,
          ),
        ),
        Positioned.fill(
          child: LineChart(
            lineChartData,
          ),
        ),
      ],
    );
  }
}

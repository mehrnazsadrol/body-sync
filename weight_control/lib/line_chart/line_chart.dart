import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:weight_control/line_chart/calculate_interval.dart';
import 'dart:convert';
import 'line_chart_x_axios.dart';
import 'line_chart_body.dart';
import 'calculate_interval.dart';

class CustomLineChart extends StatefulWidget {
  @override
  _LineChartState createState() => _LineChartState();
}

class _LineChartState extends State<CustomLineChart> with TickerProviderStateMixin {
  late CalculateInterval calculateInterval;
  double _zoomLevel = 1.0;
  Map<DateTime, int> data = {};
  late AnimationController _animationController;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();
    calculateInterval = CalculateInterval(initialZoomLevel: _zoomLevel);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _zoomAnimation = Tween<double>(begin: _zoomLevel, end: _zoomLevel).animate(_animationController)
      ..addListener(() {
        setState(() {
          _zoomLevel = _zoomAnimation.value;
          calculateInterval.setZoomLevel(_zoomLevel);
        });
      });
    loadJsonData().then((parsedData) {
      setState(() {
        data = parsedData;
      });
    });
  }

    @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }


  void _onScaleUpdate(ScaleUpdateDetails details) {
    double scaleFactor = 0.01; // Adjust this value to control sensitivity
    double newZoomLevel = _zoomLevel + (details.scale - 1) * scaleFactor;
    newZoomLevel = newZoomLevel.clamp(0.0, 1.0);

    setState(() {
      _zoomLevel = newZoomLevel;
      calculateInterval.setZoomLevel(_zoomLevel);
    });
  }

  Future<Map<DateTime, int>> loadJsonData() async {
  final String response = await rootBundle.loadString('assets/caloriesData.json');
  final data = await json.decode(response);
  Map<DateTime, int> parsedData = {};

  for (var entry in data['data']) {
    DateTime date = DateTime.parse(entry['date']);
    int calorie = entry['calories'];
    parsedData[date] = calorie;
  }

  return parsedData;
}

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: _onScaleUpdate,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.5,

        child: Column (
          children: [
            Expanded(
              child: LineChartBody(calculateInterval: calculateInterval, data: data),
            ),
            LineChartXAxios(
              zoomLevel: _zoomLevel,
              calculateInterval: calculateInterval,
            )
          ],
        )
      ), 
    );
  }
}
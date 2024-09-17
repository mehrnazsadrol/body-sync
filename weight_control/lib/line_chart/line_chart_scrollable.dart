import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:weight_control/line_chart/calculate_interval.dart';
import 'package:weight_control/line_chart/line_chart_x_axios_scrollable.dart';
import 'dart:convert';
import 'line_chart_body_scrollable.dart';

class CustomLineChartScrollable extends StatefulWidget {
  @override
  _LineChartStateScrollable createState() => _LineChartStateScrollable();
}

class _LineChartStateScrollable extends State<CustomLineChartScrollable> with TickerProviderStateMixin {
  late CalculateInterval calculateInterval;
  double _zoomLevel = 1.0;
  List<MapEntry<DateTime, int>> data = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadJsonData().then((loadedData) {
      setState(() {
        data = loadedData;
        calculateInterval = CalculateInterval();
        isLoading = false;
      });
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _zoomLevel = details.scale;
      calculateInterval.setZoomLevel(_zoomLevel);
    });
  }


  Future<List<MapEntry<DateTime, int>>> loadJsonData() async {
    final String response = await rootBundle.loadString('assets/caloriesData.json');
    final data = await json.decode(response);
    List<MapEntry<DateTime, int>> parsedData = [];

    for (var entry in data['data']) {
      DateTime date = DateTime.parse(entry['date']);
      int calorie = entry['calories'];
      parsedData.add(MapEntry(date, calorie));
    }

    parsedData.sort((a, b) => a.key.compareTo(b.key));

    return parsedData;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onScaleUpdate: _onScaleUpdate,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.5,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: ClampingScrollPhysics(),
          child: Container(
            alignment: Alignment.bottomRight,
            child: Column (
              children: [
                Expanded(
                  child: LineChartBodyScrollable(calculateInterval: calculateInterval, data: data),
                ),
                LineChartXAxiosScrollable(calculateInterval: calculateInterval, data: data),
              ],
            )
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:weight_control/line_chart/calculate_interval.dart';
import 'package:weight_control/line_chart/line_chart_x_axios_scrollable.dart';
import 'line_chart_body_scrollable.dart';
import 'setup_fake_data.dart';
import '../common/data_handler.dart';

class CustomLineChartScrollable extends StatefulWidget {
  final String page;

  CustomLineChartScrollable({required this.page});

  @override
  _LineChartStateScrollable createState() => _LineChartStateScrollable();
}

class _LineChartStateScrollable extends State<CustomLineChartScrollable> with TickerProviderStateMixin {
  late CalculateInterval calculateInterval;
  late FakeData fakeData;
  double _zoomLevel = 1.0;
  List<MapEntry<DateTime, int>> data = [];
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    calculateInterval = CalculateInterval();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // fakeData = FakeData();
    // data = widget.page == 'calories' ? fakeData.getCalData() : fakeData.getWeightData();
    DataHandler dataHandler = DataHandler();
    List<MapEntry<DateTime, int>> fetchedData = [];

    if (widget.page == 'calories') {
      fetchedData = (await dataHandler.getSavedDataLineChart('calories'));
    } else if (widget.page == 'weight') {
      fetchedData = (await dataHandler.getSavedDataLineChart('weight'));
    }

    if (fetchedData.isNotEmpty) {
      fetchedData.sort((a, b) => a.key.compareTo(b.key));
    }

    setState(() {
      data = fetchedData;
      isLoading = false;
    });
  }



  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _zoomLevel = details.scale;
      calculateInterval.setZoomLevel(_zoomLevel);
    });
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


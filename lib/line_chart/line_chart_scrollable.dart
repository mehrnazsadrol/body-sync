import 'package:flutter/material.dart';
import 'package:body_sync/line_chart/calculate_interval.dart';
import 'package:body_sync/line_chart/line_chart_x_axis_scrollable.dart';
import 'line_chart_body_scrollable.dart';
import 'setup_fake_data.dart';

class CustomLineChartScrollable extends StatefulWidget {
  final String page;

  const CustomLineChartScrollable({super.key, required this.page});

  @override
  State<CustomLineChartScrollable> createState() =>
      _CustomLineChartScrollableState();
}

class _CustomLineChartScrollableState extends State<CustomLineChartScrollable> {
  final ScrollController _scrollController = ScrollController();
  final CalculateInterval _calculateInterval = CalculateInterval();
  final FakeData _fakeData = FakeData();
  double _zoomLevel = 1.0;
  List<MapEntry<DateTime, int>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _fakeData.loadJsonData();
    final fetchedData = widget.page == 'calories'
        ? _fakeData.getCalData()
        : _fakeData.getWeightData();
    setState(() {
      _data = fetchedData;
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _zoomLevel = details.scale;
      _calculateInterval.setZoomLevel(_zoomLevel);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onScaleUpdate: _onScaleUpdate,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.5,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              Expanded(
                child: LineChartBodyScrollable(
                  calculateInterval: _calculateInterval,
                  data: _data,
                  showDataPoints: widget.page != 'weight',
                ),
              ),
              LineChartXAxisScrollable(
                  calculateInterval: _calculateInterval, data: _data),
            ],
          ),
        ),
      ),
    );
  }
}

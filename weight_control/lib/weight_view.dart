import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'customized_linechart.dart';
import 'theme.dart';

class WeightView extends StatefulWidget {
  @override
  _WeightViewState createState() => _WeightViewState();
}

class _WeightViewState extends State<WeightView> {
  List<double> weights = [];
  List<DateTime> dates = [];
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  _saveWeight(double weight) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      weights.add(weight);
      dates.add(DateTime.now());
      _saveData();
    });
  }

  _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList('weights', weights.map((item) => item.toString()).toList());
    prefs.setStringList('dates', dates.map((item) => item.toIso8601String()).toList());
  }

  List<FlSpot> _generateSpots() {
    return List.generate(weights.length, (index) => FlSpot(index.toDouble(), weights[index]));
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: screenHeight * 0.6,
          child: LineChartWithCustomBackground(
            allSpots: _generateSpots(),
            startDate: dates.isNotEmpty ? dates.first : DateTime.now(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 50, bottom: 30),
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.darkGreen3.withOpacity(0.5),
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
                borderRadius: BorderRadius.all(Radius.circular(AppTheme.borderRadius)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(AppTheme.borderRadius),
                          bottomLeft: Radius.circular(AppTheme.borderRadius),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: 'Enter weight',
                          labelStyle: TextStyle(color: const Color.fromARGB(255, 65, 101, 101)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        style: TextStyle(color: AppTheme.darkGreen3),
                        keyboardType: TextInputType.number,
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8 / 3,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.darkGreen2,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(AppTheme.borderRadius),
                        bottomRight: Radius.circular(AppTheme.borderRadius),
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        double weight = double.tryParse(_controller.text) ?? 0;
                        if (weight > 0) {
                          _saveWeight(weight);
                          _controller.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                      ),
                      child: Icon(Icons.check, color: AppTheme.whiteColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

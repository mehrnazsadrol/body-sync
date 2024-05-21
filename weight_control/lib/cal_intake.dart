import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class CalIntakeView extends StatefulWidget {
  @override
  _CalIntakeViewState createState() => _CalIntakeViewState();
}

class _CalIntakeViewState extends State<CalIntakeView> {
  List<double> calories = [];
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCalories();
  }

  _loadCalories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      calories = (prefs.getStringList('calories') ?? []).map((item) => double.parse(item)).toList();
    });
  }

  _saveCalories(double calorie) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      calories.add(calorie);
      prefs.setStringList('calories', calories.map((item) => item.toString()).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: calories.isNotEmpty 
                      ? calories.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()
                      : [FlSpot(0, 0)], // Add a default point if the list is empty
                    isCurved: true,
                    colors: [AppTheme.darkGreen2],
                    barWidth: 4,
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
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
                      height: 50, // Adjust the height to match the design
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
                          labelText: 'Enter calories',
                          labelStyle: TextStyle(color: AppTheme.darkGreen3),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                        ),
                        style: TextStyle(color: AppTheme.whiteColor),
                        keyboardType: TextInputType.number,
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8 / 3, // Set the width of the button to 1/3 of the container's width
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
                        double calorie = double.tryParse(_controller.text) ?? 0;
                        if (calorie > 0) {
                          _saveCalories(calorie);
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

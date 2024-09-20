import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weight_control/calorie_intake_view/cal_intake_view.dart';
import 'package:weight_control/weight_view/weight_view.dart';
import 'package:weight_control/workout_view/workout_view.dart';
import 'package:weight_control/common/data_handler.dart';
import 'layout/theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<DataHandler>(create: (_) => DataHandler()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Custom Bottom Bar',
      theme: ThemeData(
        scaffoldBackgroundColor: AppTheme.backgroundColor,
        elevatedButtonTheme: ElevatedButtonThemeData(style: AppTheme.buttonStyle),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;


  static final List<Widget> _widgetOptions = <Widget>[
    WorkoutView(),
    CalIntakeView(),
    WeightView(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          bottom: 50,
        ),
        child: FractionallySizedBox(
          widthFactor: 0.8,
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.darkGreen1,
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
                _buildNavItem(0, 'Workout', true),
                _buildNavItem(1, 'Calorie Intake', false),
                _buildNavItem(2, 'Weight', false, true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, [bool isFirst = false, bool isLast = false]) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: Container(
          decoration: BoxDecoration(
            color: _selectedIndex == index ? AppTheme.darkGreen2 : Colors.transparent,
            borderRadius: _selectedIndex == index
                ? BorderRadius.horizontal(
                    left: isFirst ? Radius.circular(AppTheme.borderRadius) : Radius.zero,
                    right: isLast ? Radius.circular(AppTheme.borderRadius) : Radius.zero,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedIndex == index)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    width: 60,
                    height: 3,
                    color: AppTheme.whiteColor.withOpacity(0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

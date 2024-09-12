import 'package:flutter/material.dart';
import 'calendar_view.dart';

class WorkoutView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CalendarView(),
        ],
      ),
    );
  }
}

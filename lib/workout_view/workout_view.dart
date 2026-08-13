import 'package:flutter/material.dart';
import 'calendar/calendar_view.dart';

class WorkoutView extends StatelessWidget {
  const WorkoutView({super.key});

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

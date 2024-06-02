import 'package:flutter/material.dart';
import 'custom_background.dart'; // Adjust the path as needed

class WorkoutView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomGridBackground(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            colors: [Color(0xFF2AC4D2), Color(0xff4CE3CE), Color(0xffFCE9BA)]
          ),
          Center(
            child: Text(
              'Workout View',
              style: TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}

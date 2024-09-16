import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../common/input_bar.dart';
import '../line_chart/line_chart.dart';

class CalIntakeView extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    void onInputButtonPressed() {
      debugPrint('Button Pressed');
    }

    return Scaffold(
      body: Center(
        child: Container (
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomLineChart(),
              InputBar(
                onPressed: onInputButtonPressed,
                action: 'add'),
            ],
          ),
        )
      ),
    );
  }
}

// Stack(
//         children: [
//           CustomGridBackground(
//             width: MediaQuery.of(context).size.width,
//             height: MediaQuery.of(context).size.height,
//             colors: [Color(0xFF14293A), Color(0xff3B9C8D), Color(0xffD8B06E), Color(0xffF1A292)]
//           ),
//           Center(
//           ),
//         ],
// import '../custom_background.dart';
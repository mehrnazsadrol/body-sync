import 'package:flutter/material.dart';
import '../custom_background.dart';

class CalIntakeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomGridBackground(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            colors: [Color(0xFF14293A), Color(0xff3B9C8D), Color(0xffD8B06E), Color(0xffF1A292)]
          ),
          Center(
          ),
        ],
      ),
    );
  }
}
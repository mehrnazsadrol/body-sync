import 'package:flutter/material.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class CalendarTitle extends StatelessWidget {
  final DateTime currDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const CalendarTitle({
    required this.currDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  String get _month {
    return _months[currDate.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align children to the start (left)
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${currDate.year}',
              style: const TextStyle(
                fontSize: 18.0,
                color: Color(0xFFd5626a),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              Transform.rotate(
                angle: 3.14159, // 180 degrees in radians
                child: IconButton(
                icon: Icon(
                  Icons.play_arrow,
                  color: Color(0xFFd5626a),
                ),
                  onPressed: onPreviousMonth,
                ),
              ),
              Text(
                '${_month}',
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFd5626a),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.play_arrow,
                  color: Color(0xFFd5626a),
                ),
                onPressed: onNextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
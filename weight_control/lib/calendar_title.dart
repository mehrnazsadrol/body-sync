import 'package:flutter/material.dart';

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec',
];

class CalendarTitle extends StatelessWidget {
  final DateTime currDate;

  const CalendarTitle({required this.currDate});

  String get _month {
    return _months[currDate.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0, left: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            '${currDate.year}-${_month}',
            style: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w800,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
        ],
      ),
    );
  }
}
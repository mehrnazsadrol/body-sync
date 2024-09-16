import 'package:flutter/material.dart';

const List<String> _days = [
  'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
];

class CalendarHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _days.map((day) => Expanded(
          child: Container(
            alignment: Alignment.center,
            child: Text(
              day,
              style: TextStyle(
                fontSize: 16.0,
                color: Color(0xFFd5626a),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

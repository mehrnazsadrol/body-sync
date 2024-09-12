import 'package:flutter/material.dart';
import 'calendar_body.dart';
import 'calendar_title.dart';
import 'calendar_header_row.dart';

class CalendarView extends StatelessWidget {

  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Container(
          height: size.height * 0.5,
          width: size.width * 0.8,
          decoration: BoxDecoration(
            color: Color.fromRGBO(102, 102, 102, 0.89),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              CalendarTitle(currDate: _selectedDate),
              CalendarHeaderRow(),
              Expanded(child: CalendarBody(currDate: _selectedDate)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weight_control/common/data_handler.dart';
import 'calendar_body.dart';
import 'calendar_title.dart';
import 'calendar_header_row.dart';
import 'package:provider/provider.dart';

class CalendarView extends StatefulWidget {
  @override
  _CalendarViewState createState() => _CalendarViewState();
}


class _CalendarViewState extends State<CalendarView> {
  late DataHandler dataHandler;
  DateTime _selectedDate = DateTime.now();
  List<DateTime> _savedDates = [];

  @override
  void initState() {
    super.initState();
    dataHandler = Provider.of<DataHandler>(context, listen: false);
    _loadSavedDates();
  }

  Future<void> _loadSavedDates() async {
    dataHandler.getSavedDataCalendar().then((savedDates) {
      setState(() {
        _savedDates = savedDates;
      });
    });
  }

  void _onDateTapped(DateTime date) {
    setState(() {
      if (_savedDates.contains(date)) {
        dataHandler.saveWorkoutData(date, false);
        _savedDates.remove(date);
      } else {
        dataHandler.saveWorkoutData(date, true);
        _savedDates.add(date);
      }
    });
  }

  void _goToPreviousMonth() {
    setState(() {
      int year = _selectedDate.year;
      int month = _selectedDate.month - 1;
      if (month == 0) {
        month = 12;
        year -= 1;
      }
      _selectedDate = DateTime(year, month, 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      int year = _selectedDate.year;
      int month = _selectedDate.month + 1;
      if (month == 13) {
        month = 1;
        year += 1;
      }
      _selectedDate = DateTime(year, month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Container(
          height: size.height * 0.5,
          width: size.width * 0.8,
          decoration: BoxDecoration(
            color: Color(0xFFffe4e4),
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
              CalendarTitle(
                currDate: _selectedDate,
                onPreviousMonth: _goToPreviousMonth,
                onNextMonth: _goToNextMonth,
              ),
              CalendarHeaderRow(),
              Expanded(
                child: CalendarBody(
                  savedDates: _savedDates,
                  onDateTapped: _onDateTapped,
                  currDate: _selectedDate)
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class CalendarBody extends StatelessWidget {
  final DateTime currDate;

  const CalendarBody({required this.currDate});

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(currDate.year, currDate.month, 1);
    final lastDayOfMonth = DateTime(currDate.year, currDate.month + 1, 0);
    final numberOfDays = lastDayOfMonth.day;
    final startWeekday = (firstDayOfMonth.weekday % 7);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellHeight = constraints.maxHeight / 5;
        final cellWidth = constraints.maxWidth / 7;
        final totalCells = numberOfDays + startWeekday;

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: cellWidth / cellHeight,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < startWeekday) {
              return Container(
                alignment: Alignment.center,
                height: cellHeight,
                child: Text(''),
              );
            } else {
              return GestureDetector(
                onTap: () {
                  print('Tapped on ${index - startWeekday + 1}');
                },
                child: Container(
                  alignment: Alignment.center,
                  height: cellHeight,
                  child: Text(
                    '${index - startWeekday + 1}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
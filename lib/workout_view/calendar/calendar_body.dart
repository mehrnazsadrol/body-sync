import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';

class CalendarBody extends StatelessWidget {
  final List<DateTime> savedDates;
  final DateTime currDate;
  final void Function(DateTime) onDateTapped;

  const CalendarBody({
    required this.savedDates,
    required this.currDate,
    required this.onDateTapped,
  });

    bool _isToday(DateTime date) {
    final today = DateTime.now();
    return today.year == date.year && today.month == date.month && today.day == date.day;
  }

  bool _isSavedDate(DateTime date) {
    return savedDates.any((savedDate) =>
        savedDate.year == date.year &&
        savedDate.month == date.month &&
        savedDate.day == date.day);
  }

  Widget _buildDateCell(BuildContext context, DateTime date, double cellWidth, double cellHeight) {
    final isToday = _isToday(date);
    final isSavedDate = _isSavedDate(date);

    return GestureDetector(
      onTap: () => onDateTapped(date),
      child: Container(
        alignment: Alignment.center,
        height: cellHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSavedDate)
              Container(
                width: cellWidth * 0.7,
                height: cellHeight * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFFff878d),
                    width: 5,
                  ),
                ),
              ),
            if (isToday)
              DottedBorder(
                borderType: BorderType.Circle,
                color: Color(0xFFff878d),
                strokeWidth: 1,
                dashPattern: [5, 5],
                child: Container(
                  width: cellWidth * 0.75,
                  height: cellHeight * 0.75,
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(
                      color: Color(0xFF007688),
                    ),
                  ),
                ),
              ),
            if (!isToday)
              Text(
                '${date.day}',
                style: const TextStyle(
                  color:Color(0xFF007688),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
              final day = index - startWeekday + 1;
              final date = DateTime(currDate.year, currDate.month, day);
              return _buildDateCell(context, date, cellWidth, cellHeight);
            }
          },
        );
      },
    );
  }
}
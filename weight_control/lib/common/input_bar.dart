import 'package:flutter/material.dart';
import '../theme.dart';

class InputBar extends StatelessWidget {
  final VoidCallback onPressed;
  final String action;
  final String textPlaceholder;

  InputBar({
    required this.onPressed,
    required this.action,
  }) : textPlaceholder = 'Enter ' + (action == 'add' ? 'Calorie Intake' : 'Weight');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadius),
                bottomLeft: Radius.circular(AppTheme.borderRadius),
              ),
            ),
            alignment: Alignment.center,
            child: TextField(
              decoration: InputDecoration(
                labelText: textPlaceholder,
                labelStyle: TextStyle(color: const Color.fromARGB(255, 65, 101, 101)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
              style: TextStyle(color: AppTheme.darkGreen3),
              keyboardType: TextInputType.number,
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * 0.8 / 3,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.darkGreen2,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(AppTheme.borderRadius),
              bottomRight: Radius.circular(AppTheme.borderRadius),
            ),
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
            ),
            child: Icon(
              action == 'add' ? Icons.add : Icons.check,
              color: AppTheme.whiteColor,
            ),
          ),
        ),
      ],
    );
  }
}
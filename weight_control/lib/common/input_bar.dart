import 'package:flutter/material.dart';
import '../layout/theme.dart';
class InputBar extends StatefulWidget {
  final void Function(String) onPressed;
  final String action;
  final FocusNode focusNode;

  InputBar({
    required this.onPressed,
    required this.action,
    required this.focusNode,
  });

  @override
  _InputBarState createState() => _InputBarState();
}

class _InputBarState extends State<InputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late final String textPlaceholder;

  @override
  void initState() {
    super.initState();
    textPlaceholder = 'Enter ' + (widget.action == 'add' ? 'Calorie Intake' : 'Weight');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Row(
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
                controller: _controller,
                focusNode: widget.focusNode,
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
              onPressed: () {
                widget.onPressed(_controller.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
              child: Icon(
                widget.action == 'add' ? Icons.add : Icons.check,
                color: AppTheme.whiteColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
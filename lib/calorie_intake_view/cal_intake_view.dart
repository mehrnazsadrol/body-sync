import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/data_handler.dart';
import '../common/input_bar.dart';
import '../line_chart/line_chart_scrollable.dart';

class CalIntakeView extends StatefulWidget {
  const CalIntakeView({super.key});

  @override
  State<CalIntakeView> createState() => _CalIntakeViewState();
}

class _CalIntakeViewState extends State<CalIntakeView> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _unfocus() {
    _focusNode.unfocus();
  }

  void _onInputButtonPressed(String inputText) {
    final int? calories = int.tryParse(inputText);
    if (calories != null) {
      context.read<DataHandler>().addCalories(calories);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _unfocus,
      child: Scaffold(
        body: Center(
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFfff4ee))),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CustomLineChartScrollable(
                  page: 'calories',
                ),
                InputBar(
                  onPressed: _onInputButtonPressed,
                  action: 'add',
                  focusNode: _focusNode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

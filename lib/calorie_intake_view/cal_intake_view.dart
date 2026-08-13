import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/input_bar.dart';
import '../line_chart/line_chart_scrollable.dart';
import '../common/data_handler.dart';

class CalIntakeView extends StatefulWidget {
  @override
  _CalIntakeViewState createState() => _CalIntakeViewState();
}

class _CalIntakeViewState extends State<CalIntakeView> {
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final dataHandler = Provider.of<DataHandler>(context);

    void onInputButtonPressed(String inputText) {
      print('calintake on inputPreesed, inputText: $inputText');
      int? calories = int.tryParse(inputText);
      if (calories != null) {
        dataHandler.addCalories(calories);
        setState(() {});
      }
    }

    void _unfocus() {
      _focusNode.unfocus();
    }

    return GestureDetector(
      onTap: _unfocus,
      child: Scaffold(
        body: Center(
          child: Container (
            decoration: BoxDecoration(border: Border.all(color: Color(0xFFfff4ee))),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomLineChartScrollable(
                  page: 'calories',
                ),
                InputBar(
                  onPressed: onInputButtonPressed,
                  action: 'add',
                  focusNode: _focusNode),
              ],
            ),
          )
        ),
      ),
    );
  }
}
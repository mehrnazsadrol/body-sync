import 'package:flutter/material.dart';
import '../../common/input_bar.dart';
import '../../line_chart/line_chart_scrollable.dart';
import '../common/data_handler.dart';
import 'package:provider/provider.dart';

class WeightView extends StatelessWidget {
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final dataHandler = Provider.of<DataHandler>(context);

    void _unfocus() {
      _focusNode.unfocus();
    }

    void onInputButtonPressed(String inputText) {
      int? weight = int.tryParse(inputText);
      if (weight != null) {
        dataHandler.addCalories(weight);
      }
      _unfocus();
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
                  page: 'weight',
                ),
                InputBar(
                  onPressed: onInputButtonPressed,
                  action: 'check',
                  focusNode: _focusNode),
              ],
            ),
          )
        ),
      ),
    );
  }
}
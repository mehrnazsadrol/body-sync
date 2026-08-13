import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/data_handler.dart';
import '../common/input_bar.dart';
import '../line_chart/line_chart_scrollable.dart';

class WeightView extends StatefulWidget {
  const WeightView({super.key});

  @override
  State<WeightView> createState() => _WeightViewState();
}

class _WeightViewState extends State<WeightView> {
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
    final int? weight = int.tryParse(inputText);
    if (weight != null) {
      // BUG (left unchanged on purpose): this records the entered weight as
      // calories. The intended call is DataHandler.addWeight.
      context.read<DataHandler>().addCalories(weight);
    }
    _unfocus();
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
                  page: 'weight',
                ),
                InputBar(
                  onPressed: _onInputButtonPressed,
                  action: 'check',
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

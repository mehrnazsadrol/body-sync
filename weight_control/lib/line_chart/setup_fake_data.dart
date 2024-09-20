import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class FakeData{
  List<MapEntry<DateTime, int>> calData = [];
  List<MapEntry<DateTime, int>> weightData = [];


  Future<void> loadJsonData() async {
    final String responseCalData = await rootBundle.loadString('assets/caloriesData.json');
    final String responseWeightData = await rootBundle.loadString('assets/weightData.json');

    final calJsonData = await json.decode(responseCalData);
    final weightJsonData = await json.decode(responseWeightData);

    for (var entry in calJsonData['data']) {
      DateTime date = DateTime.parse(entry['date']);
      int calorie = (entry['calories'] as num).toInt();
      calData.add(MapEntry(date, calorie));
    }

    for (var entry in weightJsonData['data']) {
      DateTime date = DateTime.parse(entry['date']);
      int weight = (entry['weight'] as num).toInt();
      weightData.add(MapEntry(date, weight));
    }

    calData.sort((a, b) => a.key.compareTo(b.key));
    weightData.sort((a, b) => a.key.compareTo(b.key));

  }

  List<MapEntry<DateTime, int>> getCalData() {
    return calData;
  }

  List<MapEntry<DateTime, int>> getWeightData() {
    return weightData;
  }
}
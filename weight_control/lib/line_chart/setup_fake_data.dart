import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class FakeData{
  List<MapEntry<DateTime, int>> calData = [];
  List<MapEntry<DateTime, int>> weightData = [];

  FakeData() {
    loadJsonData();
  }


  Future<void> loadJsonData() async {
    final String responseCalData = await rootBundle.loadString('assets/caloriesData.json');
    final String responseWeightData = await rootBundle.loadString('assets/weightData.json');

    final calData = await json.decode(responseCalData);
    final wightData = await json.decode(responseWeightData);

    for (var entry in calData['data']) {
      DateTime date = DateTime.parse(entry['date']);
      int calorie = entry['calories'];
      calData.add(MapEntry(date, calorie));
    }

    for (var entry in wightData['data']) {
      DateTime date = DateTime.parse(entry['date']);
      int weight = entry['weight'];
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
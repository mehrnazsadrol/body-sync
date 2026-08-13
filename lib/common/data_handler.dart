import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DataHandler{
  bool? workout;
  int? calories;
  int? weight;


  void addCalories(int calories) async{
    await _loadDataForToday();
    this.calories = (this.calories ?? 0) + calories;
    _saveData();
  }

  void addWeight(int weight) async{
    await _loadDataForToday();
    this.weight = (this.weight ?? 0) + weight;
    _saveData();
  }

  Future<void> _loadDataForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final savedData = prefs.getString('savedData') ?? '{}';
    final Map<String, dynamic> jsonData = json.decode(savedData);
    print('inside _loadDataForToday, jsonData: $jsonData');

    if (jsonData.containsKey(today)) {
      final todayData = jsonData[today];
      workout = todayData['workout'] ?? workout;
      calories = todayData['calories'] ?? calories;
      weight = todayData['weight'] ?? weight;
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T').first;
    final Map<String, dynamic> data = {};

    data['workout'] = workout ?? false;
    if (calories != null) data['calories'] = calories;
    if (weight != null) data['weight'] = weight;

    final savedData = prefs.getString('savedData') ?? '{}';
    final Map<String, dynamic> jsonData = json.decode(savedData);
    jsonData[today] = data;
    print('inside _saveData, jsonData: $jsonData');
    await prefs.setString('savedData', json.encode(jsonData));
  }

  Future<void> saveWorkoutData (DateTime date, bool workout) async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('savedData') ?? '{}';
    final Map<String, dynamic> jsonData = json.decode(savedData);
    final dateKey = date.toIso8601String().split('T').first;

    if (jsonData.containsKey(dateKey)) {
      jsonData[dateKey]['workout'] = workout;
    } else {
      jsonData[dateKey] = {'workout': workout};
    }

    await prefs.setString('savedData', json.encode(jsonData));
  }

  /*
  * to clear the data from the shared preferences add the below lines
  * final prefs = await SharedPreferences.getInstance();
  * await prefs.remove('savedData');
  * List<MapEntry<DateTime, int>> data = []; 
  * 
  * to fake calories data add the below lines
  * if (dataType == 'calories') {
  *      return [
  *      MapEntry(DateTime(2024, 09,01), 1500),
  *      MapEntry(DateTime(2024, 09,04), 1800),
  *      MapEntry(DateTime(2024, 09,10), 1400),
  *      MapEntry(DateTime(2024, 09,17), 1550)
  *    ];
  *  }
  *
  * 
  */

  Future<List<MapEntry<DateTime, int>>> getSavedDataLineChart(String dataType) async {

    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('savedData') ?? '{}';
    final Map<String, dynamic> jsonData = json.decode(savedData);


    List<MapEntry<DateTime, int>> data = [];
    jsonData.forEach((key, value) {
      final date = DateTime.parse(key);
      switch (dataType) {
        case 'weight':
          if (value['weight'] != null) data.add(MapEntry(date, value['weight'] as int));
          break;
        case 'calories':
          if (value['calories'] != null) data.add(MapEntry(date, value['calories'] as int));
          break;
      }
    });

    print(data);

    return data;
  }

  DateTime getEarliestDate(List<MapEntry<DateTime, int>> data) {
    DateTime earliestDate;
    if (data.isEmpty || data.length < 30) {
      earliestDate = DateTime.now().subtract(const Duration(days: 30));
    } else {
      earliestDate = data[0].key;
    }
    return earliestDate;
  }

  Future<List<DateTime>> getSavedDataCalendar() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('savedData') ?? '{}';
    final Map<String, dynamic> jsonData = json.decode(savedData);

    List<DateTime> data = [];
    jsonData.forEach((key, value) {
      final date = DateTime.parse(key);
      if (value['workout'] as bool == true) data.add(date);
    });

    return data;
  }
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DataHandler {
  static const String _storageKey = 'savedData';

  bool? workout;
  int? calories;
  int? weight;

  Future<void> addCalories(int calories) async {
    await _loadDataForToday();
    this.calories = (this.calories ?? 0) + calories;
    await _saveData();
  }

  Future<void> addWeight(int weight) async {
    await _loadDataForToday();
    this.weight = (this.weight ?? 0) + weight;
    await _saveData();
  }

  Future<void> _loadDataForToday() async {
    final jsonData = await _readAll();
    final today = _dateKey(DateTime.now());

    if (jsonData.containsKey(today)) {
      final todayData = jsonData[today];
      workout = todayData['workout'] ?? workout;
      calories = todayData['calories'] ?? calories;
      weight = todayData['weight'] ?? weight;
    }
  }

  Future<void> _saveData() async {
    final jsonData = await _readAll();
    final today = _dateKey(DateTime.now());
    final Map<String, dynamic> data = {};

    data['workout'] = workout ?? false;
    if (calories != null) data['calories'] = calories;
    if (weight != null) data['weight'] = weight;

    jsonData[today] = data;
    await _writeAll(jsonData);
  }

  Future<void> saveWorkoutData(DateTime date, bool workout) async {
    final jsonData = await _readAll();
    final dateKey = _dateKey(date);

    if (jsonData.containsKey(dateKey)) {
      jsonData[dateKey]['workout'] = workout;
    } else {
      jsonData[dateKey] = {'workout': workout};
    }

    await _writeAll(jsonData);
  }

  Future<List<MapEntry<DateTime, int>>> getSavedDataLineChart(
      String dataType) async {
    final jsonData = await _readAll();

    final List<MapEntry<DateTime, int>> data = [];
    jsonData.forEach((key, value) {
      final date = DateTime.parse(key);
      switch (dataType) {
        case 'weight':
          if (value['weight'] != null) {
            data.add(MapEntry(date, value['weight'] as int));
          }
          break;
        case 'calories':
          if (value['calories'] != null) {
            data.add(MapEntry(date, value['calories'] as int));
          }
          break;
      }
    });

    return data;
  }

  DateTime getEarliestDate(List<MapEntry<DateTime, int>> data) {
    if (data.isEmpty || data.length < 30) {
      return DateTime.now().subtract(const Duration(days: 30));
    }
    return data[0].key;
  }

  Future<List<DateTime>> getSavedDataCalendar() async {
    final jsonData = await _readAll();

    final List<DateTime> data = [];
    jsonData.forEach((key, value) {
      final date = DateTime.parse(key);
      if (value['workout'] as bool == true) data.add(date);
    });

    return data;
  }

  String _dateKey(DateTime date) => date.toIso8601String().split('T').first;

  Future<Map<String, dynamic>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_storageKey) ?? '{}';
    return json.decode(savedData) as Map<String, dynamic>;
  }

  Future<void> _writeAll(Map<String, dynamic> jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(jsonData));
  }
}

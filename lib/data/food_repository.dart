import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'models.dart';

class FoodRepository {
  List<Food> _bundled = [];
  List<Food> customFoods = [];
  Map<String, FoodOverride> overrides = {};

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/foods.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _bundled = [
      for (final f in json['foods'] as List)
        Food.fromJson(f as Map<String, dynamic>)
    ];
    _loaded = true;
  }

  List<Food> get allFoods => [...customFoods, ..._bundled];

  Food? byId(String id) {
    for (final f in allFoods) {
      if (f.id == id) return f;
    }
    return null;
  }

  FoodPortion effective(Food food, FoodPortion portion) {
    final o = overrides['${food.id}|${portion.label}'];
    if (o == null) return portion;
    return portion.copyWith(kcal: o.kcal, p: o.p, c: o.c, f: o.f);
  }

  bool hasOverride(Food food, FoodPortion portion) =>
      overrides.containsKey('${food.id}|${portion.label}');

  FoodOverride? overrideFor(Food food, FoodPortion portion) =>
      overrides['${food.id}|${portion.label}'];

  List<({Food food, FoodPortion portion})> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final results = <({Food food, FoodPortion portion})>[];
    final scored = <(int, Food)>[];
    for (final f in allFoods) {
      final name = f.name.toLowerCase();
      if (name.startsWith(q)) {
        scored.add((0, f));
      } else if (name.split(RegExp(r'[\s,]+')).any((w) => w.startsWith(q))) {
        scored.add((1, f));
      } else if (name.contains(q)) {
        scored.add((2, f));
      }
    }
    scored.sort((a, b) => a.$1 != b.$1
        ? a.$1.compareTo(b.$1)
        : a.$2.name.length.compareTo(b.$2.name.length));
    for (final (_, f) in scored) {
      const sizes = {'Large', 'Medium', 'Small', 'Half', 'Whole'};
      final sizePortions =
          f.portions.where((p) => sizes.contains(p.label)).toList();
      if (sizePortions.length > 1) {
        for (final p in sizePortions) {
          results.add((food: f, portion: p));
        }
      } else {
        results.add((food: f, portion: f.portions.first));
      }
    }
    return results;
  }
}

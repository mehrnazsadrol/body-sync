import 'package:flutter/material.dart';
import '../widgets/bs_tab_bar.dart';
import 'body/body_screen.dart';
import 'food/food_screen.dart';
import 'today/today_screen.dart';
import 'workout/workout_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();

  static HomeShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<HomeShellState>();
}

class HomeShellState extends State<HomeShell> {
  String _active = 'today';

  void switchTab(String key) => setState(() => _active = key);

  @override
  Widget build(BuildContext context) {
    final index = bsNavTabs.indexWhere((t) => t.key == _active);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: index,
          children: const [
            TodayScreen(),
            FoodScreen(),
            BodyScreen(),
            WorkoutScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BSNavBar(active: _active, onTap: switchTab),
    );
  }
}

// screens/meal_history_screen.dart
//
// Full meal history screen showing all of today's logged entries.
// Supports pull-to-refresh and swipe-to-delete.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/meal_provider.dart';
import '../widgets/meal_tile.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealProvider>().loadTodayData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text("Today's Meals",
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Consumer<MealProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            );
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text(
                    provider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: provider.loadTodayData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.todayMeals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text(
                    'No meals logged today',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF4CAF50),
            onRefresh: provider.loadTodayData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Summary row ─────────────────────────────────────────
                if (provider.dailySummary != null) ...[
                  _SummaryBar(
                    totalCalories:
                        provider.dailySummary!.totalCalories,
                    goal: provider.dailySummary!.calorieGoal ?? 2000,
                    entryCount: provider.dailySummary!.entryCount,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Meal list ────────────────────────────────────────────
                ...provider.todayMeals.map(
                  (meal) => MealTile(
                    meal: meal,
                    onDelete: () => _confirmDelete(context, provider, meal.mealId),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, MealProvider provider, int mealId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete meal?'),
        content: const Text('This will remove the entry from your log.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await provider.deleteMeal(mealId);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ─── Summary bar ─────────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final double totalCalories;
  final int    goal;
  final int    entryCount;

  const _SummaryBar({
    required this.totalCalories,
    required this.goal,
    required this.entryCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total today',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '${totalCalories.toStringAsFixed(0)} / $goal kcal',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$entryCount ${entryCount == 1 ? 'entry' : 'entries'}',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

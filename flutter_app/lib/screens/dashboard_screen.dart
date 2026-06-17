// screens/dashboard_screen.dart
//
// Home screen showing:
//   • Today's date greeting
//   • Calorie progress bar
//   • 4 macro summary cards (calories, protein, carbs, fat)
//   • Today's meal list (last 5)
//   • FAB to go to UploadScreen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/meal_provider.dart';
import '../widgets/meal_tile.dart';
import '../widgets/nutrition_card.dart';
import 'upload_screen.dart';
import 'meal_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data after first frame so the provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MealProvider>().loadTodayData();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 🌤️';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Consumer<MealProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              color: const Color(0xFF4CAF50),
              onRefresh: () => provider.loadTodayData(),
              child: CustomScrollView(
                slivers: [
                  // ── Header ────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _todayLabel(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.history_rounded),
                            tooltip: 'Meal history',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MealHistoryScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Error banner ──────────────────────────────────────────
                  if (provider.hasError)
                    SliverToBoxAdapter(
                      child: _ErrorBanner(
                        message: provider.errorMessage!,
                        onDismiss: provider.clearError,
                      ),
                    ),

                  // ── Loading indicator ─────────────────────────────────────
                  if (provider.isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    )
                  else ...[
                    // ── Calorie progress card ─────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _CalorieCard(provider: provider),
                      ),
                    ),

                    // ── Macro row ─────────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                        child: provider.dailySummary != null
                            ? MacroRow(
                                calories: provider.dailySummary!.totalCalories,
                                protein:  provider.dailySummary!.totalProteinG,
                                carbs:    provider.dailySummary!.totalCarbsG,
                                fat:      provider.dailySummary!.totalFatG,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),

                    // ── Today's meals ─────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Today's meals",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (provider.todayMeals.length > 3)
                              TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const MealHistoryScreen(),
                                  ),
                                ),
                                child: const Text('See all'),
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (provider.todayMeals.isEmpty)
                      SliverToBoxAdapter(
                        child: _EmptyMeals(
                          onAdd: () => _goToUpload(context),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final meal = provider.todayMeals
                                .take(5)
                                .toList()[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: MealTile(
                                meal: meal,
                                onDelete: () =>
                                    _confirmDelete(context, provider, meal.mealId),
                              ),
                            );
                          },
                          childCount: provider.todayMeals.take(5).length,
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ],
              ),
            );
          },
        ),
      ),

      // ── FAB: go to camera/upload screen ──────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToUpload(context),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text(
          'Scan Food',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _goToUpload(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadScreen()),
    ).then((_) {
      // Refresh dashboard when returning from the upload flow
      if (mounted) context.read<MealProvider>().loadTodayData();
    });
  }

  Future<void> _confirmDelete(
      BuildContext context, MealProvider provider, int mealId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete meal?'),
        content: const Text('This will remove the meal from your log.'),
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
      await provider.deleteMeal(mealId);
    }
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _CalorieCard extends StatelessWidget {
  final MealProvider provider;
  const _CalorieCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final summary = provider.dailySummary;
    final progress = summary?.calorieProgress ?? 0.0;
    final consumed = summary?.totalCalories.toStringAsFixed(0) ?? '0';
    final goal     = summary?.calorieGoal?.toString() ?? '2000';
    final remaining = summary?.caloriesRemaining?.toStringAsFixed(0) ?? goal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Calories',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                consumed,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' / $goal kcal',
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$remaining kcal remaining',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyMeals extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyMeals({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.no_food_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            'No meals logged yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Scan your first meal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              side: const BorderSide(color: Color(0xFF4CAF50)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close_rounded,
                  color: Colors.redAccent, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

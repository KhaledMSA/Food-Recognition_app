// screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/meal_provider.dart';
import '../widgets/meal_tile.dart';
import 'upload_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    final userId = context.read<AuthProvider>().userId;
    if (userId > 0) context.read<MealProvider>().loadTodayData(userId);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
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
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Consumer<MealProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              color: const Color(0xFF4CAF50),
              onRefresh: () async => _reload(),
              child: CustomScrollView(
                slivers: [
                  // ── Header ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_greeting()}, ${user?.displayName ?? ''} 👋',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _todayLabel(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (user?.goal != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF43A047)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user!.goalLabel,
                                style: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Error banner ─────────────────────────────────────────
                  if (provider.hasError)
                    SliverToBoxAdapter(
                      child: _ErrorBanner(
                        message: provider.errorMessage!,
                        onDismiss: provider.clearError,
                      ),
                    ),

                  // ── Loading / Content ─────────────────────────────────────
                  if (provider.isLoading)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF4CAF50)),
                        ),
                      ),
                    )
                  else ...[
                    // ── Calorie card ─────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _CalorieCard(provider: provider),
                      ),
                    ),

                    // ── Macro row ─────────────────────────────────────────
                    if (provider.dailySummary != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          child: _MacroProgressRow(provider: provider),
                        ),
                      ),

                    // ── Quick actions ─────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.camera_alt_rounded,
                                label: 'Scan Food',
                                color: const Color(0xFF43A047),
                                onTap: () => _goToUpload(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickAction(
                                icon: Icons.edit_note_rounded,
                                label: 'Add Manually',
                                color: const Color(0xFF1565C0),
                                onTap: () {
                                  // Switch to Diary via BottomNav (index 2)
                                  // Signal main shell to go to tab 2
                                  DefaultTabController.of(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Today's meals header ──────────────────────────────
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
                                  fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${provider.todayMeals.length} items',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Meal list ─────────────────────────────────────────
                    if (provider.todayMeals.isEmpty)
                      SliverToBoxAdapter(
                        child: _EmptyMeals(
                            onScan: () => _goToUpload(context)),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final meal =
                                provider.todayMeals.take(5).toList()[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: MealTile(
                                meal: meal,
                                onDelete: () => _confirmDelete(
                                    context, provider, meal.mealId),
                              ),
                            );
                          },
                          childCount: provider.todayMeals.take(5).length,
                        ),
                      ),

                    const SliverToBoxAdapter(
                        child: SizedBox(height: 100)),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _goToUpload(BuildContext context) {
    final userId = context.read<AuthProvider>().userId;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UploadScreen(userId: userId)),
    ).then((_) {
      if (mounted) _reload();
    });
  }

  Future<void> _confirmDelete(
      BuildContext context, MealProvider provider, int mealId) async {
    final userId = context.read<AuthProvider>().userId;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete meal?'),
        content: const Text('This will remove the meal from your log.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await provider.deleteMeal(mealId, userId);
    }
  }
}

// ─── Calorie card ─────────────────────────────────────────────────────────────

class _CalorieCard extends StatelessWidget {
  final MealProvider provider;
  const _CalorieCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final s = provider.dailySummary;
    final progress = s?.calorieProgress ?? 0.0;
    final consumed = s?.totalCalories.toStringAsFixed(0) ?? '0';
    final goal = s?.calorieGoal?.toString() ?? '2000';
    final remaining = s?.caloriesRemaining?.toStringAsFixed(0) ?? goal;

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
            color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Calories',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(consumed,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800)),
              Text(' / $goal kcal',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('$remaining kcal remaining',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Macro row ────────────────────────────────────────────────────────────────

class _MacroProgressRow extends StatelessWidget {
  final MealProvider provider;
  const _MacroProgressRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    final s = provider.dailySummary!;
    return Row(
      children: [
        Expanded(
          child: _MacroCard(
            label: 'Protein',
            consumed: s.totalProteinG,
            goal: s.proteinGoal?.toDouble() ?? 50,
            progress: s.proteinProgress,
            color: const Color(0xFF1565C0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroCard(
            label: 'Carbs',
            consumed: s.totalCarbsG,
            goal: s.carbsGoal?.toDouble() ?? 250,
            progress: s.carbsProgress,
            color: const Color(0xFFE65100),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroCard(
            label: 'Fat',
            consumed: s.totalFatG,
            goal: s.fatGoal?.toDouble() ?? 65,
            progress: s.fatProgress,
            color: const Color(0xFF6A1B9A),
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double consumed;
  final double goal;
  final double progress;
  final Color color;

  const _MacroCard({
    required this.label,
    required this.consumed,
    required this.goal,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${consumed.toStringAsFixed(0)}g',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          Text('/ ${goal.toStringAsFixed(0)}g',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick action ─────────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyMeals extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyMeals({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.no_food_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No meals logged yet',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text('Scan your first meal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              side: const BorderSide(color: Color(0xFF4CAF50)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.redAccent, fontSize: 13)),
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

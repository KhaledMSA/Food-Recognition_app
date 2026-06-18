// models/daily_summary.dart
//
// Maps to DailySummaryResponse from GET /nutrition/daily-summary.

class DailySummary {
  final int userId;
  final String date;
  final double totalCalories;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;
  final int entryCount;
  final int? calorieGoal;
  final double? caloriesRemaining;
  final int? proteinGoal;
  final int? carbsGoal;
  final int? fatGoal;

  const DailySummary({
    required this.userId,
    required this.date,
    required this.totalCalories,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
    required this.entryCount,
    this.calorieGoal,
    this.caloriesRemaining,
    this.proteinGoal,
    this.carbsGoal,
    this.fatGoal,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      userId: json['user_id'] as int,
      date: json['date'] as String,
      totalCalories: (json['total_calories'] as num).toDouble(),
      totalProteinG: (json['total_protein_g'] as num).toDouble(),
      totalCarbsG: (json['total_carbs_g'] as num).toDouble(),
      totalFatG: (json['total_fat_g'] as num).toDouble(),
      entryCount: json['entry_count'] as int,
      calorieGoal: json['calorie_goal'] as int?,
      caloriesRemaining: json['calories_remaining'] != null
          ? (json['calories_remaining'] as num).toDouble()
          : null,
      proteinGoal: json['protein_goal'] as int?,
      carbsGoal: json['carbs_goal'] as int?,
      fatGoal: json['fat_goal'] as int?,
    );
  }

  /// Calorie progress as a fraction 0.0–1.0 (clamped).
  double get calorieProgress {
    if (calorieGoal == null || calorieGoal! <= 0) return 0.0;
    return (totalCalories / calorieGoal!).clamp(0.0, 1.0);
  }

  double get proteinProgress {
    if (proteinGoal == null || proteinGoal! <= 0) return 0.0;
    return (totalProteinG / proteinGoal!).clamp(0.0, 1.0);
  }

  double get carbsProgress {
    if (carbsGoal == null || carbsGoal! <= 0) return 0.0;
    return (totalCarbsG / carbsGoal!).clamp(0.0, 1.0);
  }

  double get fatProgress {
    if (fatGoal == null || fatGoal! <= 0) return 0.0;
    return (totalFatG / fatGoal!).clamp(0.0, 1.0);
  }

  /// Returns an empty summary for a given userId (used as initial state).
  factory DailySummary.empty(int userId) {
    return DailySummary(
      userId: userId,
      date: DateTime.now().toIso8601String().substring(0, 10),
      totalCalories: 0,
      totalProteinG: 0,
      totalCarbsG: 0,
      totalFatG: 0,
      entryCount: 0,
      calorieGoal: 2000,
      caloriesRemaining: 2000,
      proteinGoal: 50,
      carbsGoal: 250,
      fatGoal: 65,
    );
  }
}

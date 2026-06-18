// models/user_model.dart
//
// Maps to UserResponse from GET /users/me and PATCH /users/me.

class UserModel {
  final int id;
  final String email;
  final String? name;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final String? goal;
  final String? weeklyEffort;
  final int dailyCalorieGoal;
  final int dailyProteinGoal;
  final int dailyCarbsGoal;
  final int dailyFatGoal;
  final bool onboardingCompleted;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.goal,
    this.weeklyEffort,
    required this.dailyCalorieGoal,
    required this.dailyProteinGoal,
    required this.dailyCarbsGoal,
    required this.dailyFatGoal,
    required this.onboardingCompleted,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String?,
      gender: json['gender'] as String?,
      heightCm: json['height_cm'] != null
          ? (json['height_cm'] as num).toDouble()
          : null,
      weightKg: json['weight_kg'] != null
          ? (json['weight_kg'] as num).toDouble()
          : null,
      goal: json['goal'] as String?,
      weeklyEffort: json['weekly_effort'] as String?,
      dailyCalorieGoal: json['daily_calorie_goal'] as int? ?? 2000,
      dailyProteinGoal: json['daily_protein_goal'] as int? ?? 50,
      dailyCarbsGoal: json['daily_carbs_goal'] as int? ?? 250,
      dailyFatGoal: json['daily_fat_goal'] as int? ?? 65,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }

  /// Human-readable goal label
  String get goalLabel {
    switch (goal) {
      case 'lose_weight':
        return 'Lose Weight';
      case 'maintain_weight':
        return 'Maintain Weight';
      case 'gain_weight':
        return 'Gain Weight';
      case 'build_muscle':
        return 'Build Muscle';
      default:
        return goal ?? 'Not set';
    }
  }

  /// Human-readable effort label
  String get effortLabel {
    switch (weeklyEffort) {
      case 'low':
        return 'Low';
      case 'moderate':
        return 'Moderate';
      case 'high':
        return 'High';
      default:
        return weeklyEffort ?? 'Not set';
    }
  }

  /// Human-readable gender label
  String get genderLabel {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return gender ?? 'Not set';
    }
  }

  String get displayName => name ?? email.split('@').first;
}

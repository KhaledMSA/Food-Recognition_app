// models/meal.dart
//
// Maps to MealEntryResponse from:
//   POST /meals/from-analysis
//   GET  /meals
//   GET  /meals/today

class MealEntry {
  final int mealItemId;
  final int mealId;
  final int userId;
  final String foodName;
  final String predictedLabel;
  final double servingQuantity;
  final String servingUnit;
  final double servingG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? confidence;
  final String? imageUrl;
  final String mealType;
  final String mealDate;
  final String loggedAt;

  const MealEntry({
    required this.mealItemId,
    required this.mealId,
    required this.userId,
    required this.foodName,
    required this.predictedLabel,
    required this.servingQuantity,
    required this.servingUnit,
    required this.servingG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.confidence,
    this.imageUrl,
    required this.mealType,
    required this.mealDate,
    required this.loggedAt,
  });

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      mealItemId:      json['meal_item_id'] as int,
      mealId:          json['meal_id'] as int,
      userId:          json['user_id'] as int,
      foodName:        json['food_name'] as String,
      predictedLabel:  json['predicted_label'] as String,
      servingQuantity: (json['serving_quantity'] as num).toDouble(),
      servingUnit:     json['serving_unit'] as String,
      servingG:        (json['serving_g'] as num).toDouble(),
      calories:        (json['calories'] as num).toDouble(),
      proteinG:        (json['protein_g'] as num).toDouble(),
      carbsG:          (json['carbs_g'] as num).toDouble(),
      fatG:            (json['fat_g'] as num).toDouble(),
      confidence:      json['confidence'] != null
          ? (json['confidence'] as num).toDouble()
          : null,
      imageUrl:  json['image_url'] as String?,
      mealType:  json['meal_type'] as String,
      mealDate:  json['meal_date'] as String,
      loggedAt:  json['logged_at'] as String,
    );
  }

  /// Formatted time string for display, e.g. "10:32 AM"
  String get formattedTime {
    try {
      final dt = DateTime.parse(loggedAt);
      final hour   = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return loggedAt;
    }
  }

  /// Capitalised meal type, e.g. "Lunch"
  String get mealTypeLabel =>
      mealType[0].toUpperCase() + mealType.substring(1);
}

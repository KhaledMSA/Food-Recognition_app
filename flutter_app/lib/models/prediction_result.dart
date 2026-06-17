// models/prediction_result.dart
//
// Maps to the AnalysisPreview response from POST /analyze-image.

class PredictionItem {
  final String className;
  final double confidence;

  const PredictionItem({required this.className, required this.confidence});

  factory PredictionItem.fromJson(Map<String, dynamic> json) {
    return PredictionItem(
      className:  json['class_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class AnalysisPreview {
  final String imageUrl;
  final String predictedLabel;
  final double confidence;
  final bool lowConfidenceWarning;
  final List<PredictionItem> topPredictions;
  final double processingTimeMs;

  // Nutrition estimate
  final String foodName;
  final double servingQuantity;
  final String servingUnit;
  final double servingG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String nutritionSource;

  const AnalysisPreview({
    required this.imageUrl,
    required this.predictedLabel,
    required this.confidence,
    required this.lowConfidenceWarning,
    required this.topPredictions,
    required this.processingTimeMs,
    required this.foodName,
    required this.servingQuantity,
    required this.servingUnit,
    required this.servingG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.nutritionSource,
  });

  factory AnalysisPreview.fromJson(Map<String, dynamic> json) {
    return AnalysisPreview(
      imageUrl:             json['image_url'] as String,
      predictedLabel:       json['predicted_label'] as String,
      confidence:           (json['confidence'] as num).toDouble(),
      lowConfidenceWarning: json['low_confidence_warning'] as bool,
      topPredictions: (json['top_predictions'] as List)
          .map((e) => PredictionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      processingTimeMs: (json['processing_time_ms'] as num).toDouble(),
      foodName:        json['food_name'] as String,
      servingQuantity: (json['serving_quantity'] as num).toDouble(),
      servingUnit:     json['serving_unit'] as String,
      servingG:        (json['serving_g'] as num).toDouble(),
      calories:        (json['calories'] as num).toDouble(),
      proteinG:        (json['protein_g'] as num).toDouble(),
      carbsG:          (json['carbs_g'] as num).toDouble(),
      fatG:            (json['fat_g'] as num).toDouble(),
      nutritionSource: json['nutrition_source'] as String,
    );
  }
}

import 'package:flutter/foundation.dart';

class ApiConfig {
  // User used for local demo/testing
  static const int userId = 1;

  // Default serving values
  static const double defaultServingQty = 100;
  static const String defaultServingUnit = 'g';

  static const List<String> servingUnits = [
    'g',
    'kg',
    'piece',
    'slice',
    'cup',
    'tbsp',
    'tsp',
  ];

  // Base URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://192.168.1.164:8000';

      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return 'http://127.0.0.1:8000';

      default:
        return 'http://127.0.0.1:8000';
    }
  }

  // API routes
  static const String analyzeImage = '/analyze-image';

  static const String meals = '/meals';
  static const String mealsFromAnalysis = '/meals/from-analysis';
  static const String mealsToday = '/meals/today';

  static const String dailySummary = '/nutrition/daily-summary';

  static const String nutrition = '/nutrition';
}

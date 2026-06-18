// providers/meal_provider.dart
//
// Central state for meal data using Provider (ChangeNotifier).
// userId is passed in dynamically — no hardcoded user_id = 1.

import 'package:flutter/foundation.dart';

import '../models/daily_summary.dart';
import '../models/meal.dart';
import '../models/prediction_result.dart';
import '../services/api_service.dart';

class MealProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ── State ─────────────────────────────────────────────────────────────────

  List<MealEntry> _todayMeals = [];
  DailySummary? _dailySummary;
  bool _isLoading = false;
  String? _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<MealEntry> get todayMeals => _todayMeals;
  DailySummary? get dailySummary => _dailySummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // ── Private helpers ───────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  // ── Load today's data (meals + summary) ───────────────────────────────────

  Future<void> loadTodayData(int userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final results = await Future.wait([
        _api.getTodayMeals(userId),
        _api.getDailySummary(userId),
      ]);

      _todayMeals = results[0] as List<MealEntry>;
      _dailySummary = results[1] as DailySummary;
    } on ApiException catch (e) {
      _setError(e.message);
    } finally {
      _setLoading(false);
    }
  }

  // ── Save confirmed meal (called from PredictionResultScreen) ──────────────

  Future<MealEntry?> confirmAndSaveMeal({
    required int userId,
    required AnalysisPreview preview,
    required double servingQuantity,
    required String servingUnit,
    required String mealType,
    String? confirmedLabel,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final saved = await _api.saveMealFromAnalysis(
        userId: userId,
        predictedLabel: preview.predictedLabel,
        confirmedLabel: confirmedLabel,
        confidence: preview.confidence,
        servingQuantity: servingQuantity,
        servingUnit: servingUnit,
        mealType: mealType,
        imageUrl: preview.imageUrl,
      );

      _todayMeals = [saved, ..._todayMeals];
      await _refreshSummary(userId);

      return saved;
    } on ApiException catch (e) {
      _setError(e.message);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ── Save manual meal ──────────────────────────────────────────────────────

  Future<MealEntry?> saveManualMeal({
    required int userId,
    required String foodName,
    required double servingQuantity,
    required String servingUnit,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required String mealType,
    String? mealDate,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final saved = await _api.saveManualMeal(
        userId: userId,
        foodName: foodName,
        servingQuantity: servingQuantity,
        servingUnit: servingUnit,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        mealType: mealType,
        mealDate: mealDate,
      );

      // Only add to today's list if it's today's date
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (mealDate == null || mealDate == today) {
        _todayMeals = [saved, ..._todayMeals];
        await _refreshSummary(userId);
      }

      return saved;
    } on ApiException catch (e) {
      _setError(e.message);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ── Delete a meal ─────────────────────────────────────────────────────────

  Future<bool> deleteMeal(int mealId, int userId) async {
    _setError(null);

    try {
      await _api.deleteMeal(mealId);
      _todayMeals = _todayMeals.where((m) => m.mealId != mealId).toList();
      await _refreshSummary(userId);
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ── Refresh just the summary (after add/delete) ───────────────────────────

  Future<void> _refreshSummary(int userId) async {
    try {
      _dailySummary = await _api.getDailySummary(userId);
      notifyListeners();
    } catch (_) {
      // Best-effort
    }
  }

  // ── Clear error ───────────────────────────────────────────────────────────

  void clearError() => _setError(null);
}

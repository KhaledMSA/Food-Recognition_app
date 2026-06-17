// providers/meal_provider.dart
//
// Central state for the app using Provider (ChangeNotifier).
// Holds today's meals, the daily summary, loading/error state,
// and all actions that update them.

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/daily_summary.dart';
import '../models/meal.dart';
import '../models/prediction_result.dart';
import '../services/api_service.dart';

class MealProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  // ── State ─────────────────────────────────────────────────────────────────

  List<MealEntry> _todayMeals   = [];
  DailySummary?   _dailySummary;
  bool            _isLoading    = false;
  String?         _errorMessage;

  // ── Getters ───────────────────────────────────────────────────────────────

  List<MealEntry> get todayMeals   => _todayMeals;
  DailySummary?   get dailySummary => _dailySummary;
  bool            get isLoading    => _isLoading;
  String?         get errorMessage => _errorMessage;
  bool            get hasError     => _errorMessage != null;

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

  Future<void> loadTodayData() async {
    _setLoading(true);
    _setError(null);

    try {
      final results = await Future.wait([
        _api.getTodayMeals(ApiConfig.userId),
        _api.getDailySummary(ApiConfig.userId),
      ]);

      _todayMeals   = results[0] as List<MealEntry>;
      _dailySummary = results[1] as DailySummary;
    } on ApiException catch (e) {
      _setError(e.message);
    } finally {
      _setLoading(false);
    }
  }

  // ── Save confirmed meal (called from PredictionResultScreen) ──────────────

  Future<MealEntry?> confirmAndSaveMeal({
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
        userId:          ApiConfig.userId,
        predictedLabel:  preview.predictedLabel,
        confirmedLabel:  confirmedLabel,
        confidence:      preview.confidence,
        servingQuantity: servingQuantity,
        servingUnit:     servingUnit,
        mealType:        mealType,
        imageUrl:        preview.imageUrl,
      );

      // Optimistically add to today's list and refresh summary
      _todayMeals = [saved, ..._todayMeals];
      await _refreshSummary();

      return saved;
    } on ApiException catch (e) {
      _setError(e.message);
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ── Delete a meal ─────────────────────────────────────────────────────────

  Future<bool> deleteMeal(int mealId) async {
    _setError(null);

    try {
      await _api.deleteMeal(mealId);
      _todayMeals = _todayMeals.where((m) => m.mealId != mealId).toList();
      await _refreshSummary();
      return true;
    } on ApiException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ── Refresh just the summary (after add/delete) ───────────────────────────

  Future<void> _refreshSummary() async {
    try {
      _dailySummary = await _api.getDailySummary(ApiConfig.userId);
      notifyListeners();
    } catch (_) {
      // Best-effort — don't show error if summary refresh fails
    }
  }

  // ── Clear error ───────────────────────────────────────────────────────────

  void clearError() => _setError(null);
}

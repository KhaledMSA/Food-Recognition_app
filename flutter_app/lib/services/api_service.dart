// services/api_service.dart
//
// Single class that handles all HTTP calls to the FastAPI backend.
// All methods throw an ApiException on failure so the UI can show
// a clean error message.

import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/daily_summary.dart';
import '../models/meal.dart';
import '../models/prediction_result.dart';

// ─── Custom exception ────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}



MediaType getImageMediaType(String path) {
  final lowerPath = path.toLowerCase();

  if (lowerPath.endsWith('.jpg') || lowerPath.endsWith('.jpeg')) {
    return MediaType('image', 'jpeg');
  }

  if (lowerPath.endsWith('.png')) {
    return MediaType('image', 'png');
  }

  if (lowerPath.endsWith('.webp')) {
    return MediaType('image', 'webp');
  }

  if (lowerPath.endsWith('.bmp')) {
    return MediaType('image', 'bmp');
  }

  if (lowerPath.endsWith('.gif')) {
    return MediaType('image', 'gif');
  }

  return MediaType('image', 'jpeg');
}


// ─── Service ─────────────────────────────────────────────────────────────────

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Shared HTTP client — reused for connection keep-alive
  final http.Client _client = http.Client();

  static const Duration _timeout = Duration(seconds: 30);

  // ── Helper: parse error detail from FastAPI response ──────────────────────

  String _parseError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['detail']?.toString() ??
          'Server returned ${response.statusCode}';
    } catch (_) {
      return 'Server returned ${response.statusCode}';
    }
  }

  // ── POST /analyze-image ───────────────────────────────────────────────────
  //
  // Sends the image as multipart/form-data.
  // Returns an AnalysisPreview — no meal is saved yet.

  Future<AnalysisPreview> analyzeImage({
  required File imageFile,
  required int userId,
  double servingQuantity = ApiConfig.defaultServingQty,
  String servingUnit = ApiConfig.defaultServingUnit,
}) async {
  final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.analyzeImage}');

  final request = http.MultipartRequest('POST', uri)
    ..fields['user_id'] = userId.toString()
    ..fields['serving_quantity'] = servingQuantity.toString()
    ..fields['serving_unit'] = servingUnit
    ..files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: getImageMediaType(imageFile.path),
      ),
    );

  try {
    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalysisPreview.fromJson(json);
    }

    throw ApiException(_parseError(response), statusCode: response.statusCode);
  } on ApiException {
    rethrow;
  } on SocketException {
    throw const ApiException(
      'Cannot reach the server. Check your network connection and API URL.',
    );
  } on Exception catch (e) {
    throw ApiException('analyzeImage failed: $e');
  }
}

  // ── POST /meals/from-analysis ─────────────────────────────────────────────
  //
  // Confirms the analysis preview and saves the meal to the database.

  Future<MealEntry> saveMealFromAnalysis({
    required int userId,
    required String predictedLabel,
    String? confirmedLabel,
    double? confidence,
    required double servingQuantity,
    required String servingUnit,
    String mealType    = 'meal',
    String? imageUrl,
  }) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.mealsFromAnalysis}');

    final body = <String, dynamic>{
      'user_id':          userId,
      'predicted_label':  predictedLabel,
      'serving_quantity': servingQuantity,
      'serving_unit':     servingUnit,
      'meal_type':        mealType,
      if (confirmedLabel != null) 'confirmed_label': confirmedLabel,
      if (confidence     != null) 'confidence':      confidence,
      if (imageUrl       != null) 'image_url':        imageUrl,
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return MealEntry.fromJson(json);
      }

      throw ApiException(_parseError(response), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Cannot reach the server. Check your network.');
    } on Exception catch (e) {
      throw ApiException('saveMeal failed: $e');
    }
  }

  // ── GET /meals/today ──────────────────────────────────────────────────────

  Future<List<MealEntry>> getTodayMeals(int userId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.mealsToday}?user_id=$userId',
    );

    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw ApiException(_parseError(response), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Cannot reach the server. Check your network.');
    } on Exception catch (e) {
      throw ApiException('getTodayMeals failed: $e');
    }
  }

  // ── GET /meals ────────────────────────────────────────────────────────────

  Future<List<MealEntry>> getAllMeals(int userId,
      {int limit = 50, int offset = 0}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.meals}'
      '?user_id=$userId&limit=$limit&offset=$offset',
    );

    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list
            .map((e) => MealEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      throw ApiException(_parseError(response), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Cannot reach the server. Check your network.');
    } on Exception catch (e) {
      throw ApiException('getAllMeals failed: $e');
    }
  }

  // ── GET /nutrition/daily-summary ──────────────────────────────────────────

  Future<DailySummary> getDailySummary(int userId, {String? date}) async {
    final params = 'user_id=$userId${date != null ? '&date=$date' : ''}';
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.dailySummary}?$params',
    );

    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return DailySummary.fromJson(json);
      }

      // 404 → user not in DB yet → return empty summary
      if (response.statusCode == 404) {
        return DailySummary.empty(userId);
      }

      throw ApiException(_parseError(response), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Cannot reach the server. Check your network.');
    } on Exception catch (e) {
      throw ApiException('getDailySummary failed: $e');
    }
  }

  // ── DELETE /meals/{meal_id} ───────────────────────────────────────────────

  Future<void> deleteMeal(int mealId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.meals}/$mealId');

    try {
      final response = await _client.delete(uri).timeout(_timeout);

      // 204 No Content = success
      if (response.statusCode == 204) return;

      throw ApiException(_parseError(response), statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Cannot reach the server. Check your network.');
    } on Exception catch (e) {
      throw ApiException('deleteMeal failed: $e');
    }
  }
}

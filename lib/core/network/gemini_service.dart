import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../data/models/inference_result.dart';
import '../utils/logger.dart';

final _log = AppLogger('GeminiService');

/// Service for communicating with the Google Gemini Vision API.
///
/// Implements the inference pipeline from the project specification
/// (Section 3) — sends food images to the Gemini multimodal model
/// and forces a strict JSON schema response containing nutritional data.
class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  static const String _model = 'gemini-2.0-flash';

  final Dio _dio;

  GeminiService({Dio? dio}) : _dio = dio ?? Dio();

  /// API key loaded from environment.
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// The structured prompt that forces the LLM to emit a strict JSON schema
  /// with zero conversational text (spec Section 3 guardrail).
  static const String _systemPrompt = '''
You are a food nutrition analysis engine. You receive a photo of a food item.
You MUST respond with ONLY a valid JSON object — no markdown, no explanation,
no conversation, no code fences.

The JSON MUST match this exact schema:
{
  "food_item_identified": "<string: name of the food>",
  "confidence_score": <float: 0.0 to 1.0>,
  "calories_kcal": <integer: estimated calories>,
  "proteins_grams": <float: estimated protein in grams>,
  "carbohydrates_grams": <float: estimated carbohydrates in grams>,
  "fats_grams": <float: estimated fats in grams>,
  "serving_size_estimate": "<string: estimated serving size>"
}

Rules:
- All numeric values MUST be non-negative.
- confidence_score MUST be between 0.0 and 1.0.
- Do NOT wrap the JSON in markdown code fences.
- Do NOT include any text outside the JSON object.
''';

  /// Analyze a food image and return structured nutritional data.
  ///
  /// Sends [imageBytes] to Gemini Vision with a JSON schema constraint.
  /// Returns an [InferenceResult] if the response is valid, or throws
  /// an exception if the guardrail validation fails.
  ///
  /// The [mimeType] should match the image format (default: `image/jpeg`).
  Future<InferenceResult> analyzeFood(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    _log.info('Sending food image (${imageBytes.length} bytes) to Gemini');

    final base64Image = base64Encode(imageBytes);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': _systemPrompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
        'topP': 0.8,
        'maxOutputTokens': 512,
        'responseMimeType': 'application/json',
      },
    };

    try {
      final response = await _dio.post(
        '$_baseUrl/models/$_model:generateContent',
        queryParameters: {'key': _apiKey},
        data: requestBody,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final result = _parseResponse(response.data);

      // ── Guardrail Validation (Spec Section 3) ─────────────────────────
      if (!result.isValid) {
        _log.error('Inference result failed guardrail validation: $result');
        throw InferenceGuardrailException(
          'Inference response contains invalid values: $result',
        );
      }

      _log.info('Inference success: ${result.foodItemIdentified} '
          '(${result.confidenceScore} confidence)');
      return result;
    } on DioException catch (e) {
      _log.error('Gemini API request failed', e, e.stackTrace);
      throw InferenceNetworkException(
        'Failed to reach Gemini API: ${e.message}',
      );
    }
  }

  /// Parse the Gemini API response and extract the [InferenceResult].
  InferenceResult _parseResponse(dynamic responseData) {
    try {
      final candidates = responseData['candidates'] as List<dynamic>;
      if (candidates.isEmpty) {
        throw InferenceParseException('No candidates in Gemini response');
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List<dynamic>;
      if (parts.isEmpty) {
        throw InferenceParseException('No parts in Gemini response');
      }

      final rawText = parts[0]['text'] as String;
      _log.debug('Raw Gemini response text: $rawText');

      // Parse JSON — handle potential markdown fences despite prompt
      final cleanedJson = _stripMarkdownFences(rawText.trim());
      final jsonMap = jsonDecode(cleanedJson) as Map<String, dynamic>;

      return InferenceResult.fromJson(jsonMap);
    } catch (e) {
      if (e is InferenceException) rethrow;
      _log.error('Failed to parse Gemini response', e);
      throw InferenceParseException('Could not parse Gemini response: $e');
    }
  }

  /// Strip markdown code fences if the model wraps JSON despite instructions.
  String _stripMarkdownFences(String text) {
    if (text.startsWith('```')) {
      final lines = text.split('\n');
      // Remove first line (```json) and last line (```)
      final filtered =
          lines.where((line) => !line.trim().startsWith('```')).toList();
      return filtered.join('\n').trim();
    }
    return text;
  }
}

// ── Inference Exceptions ──────────────────────────────────────────────────────

/// Base class for inference pipeline exceptions.
sealed class InferenceException implements Exception {
  final String message;
  const InferenceException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the Gemini API response fails guardrail validation.
class InferenceGuardrailException extends InferenceException {
  const InferenceGuardrailException(super.message);
}

/// Thrown when the Gemini API response cannot be parsed.
class InferenceParseException extends InferenceException {
  const InferenceParseException(super.message);
}

/// Thrown when the network request to Gemini API fails.
class InferenceNetworkException extends InferenceException {
  const InferenceNetworkException(super.message);
}

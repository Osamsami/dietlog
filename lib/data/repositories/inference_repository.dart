import 'dart:io';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../core/network/gemini_service.dart';
import '../../core/utils/logger.dart';
import '../models/inference_result.dart';
import '../models/nutrition_log.dart';
import 'nutrition_log_repository.dart';

final _log = AppLogger('InferenceRepository');

/// Repository bridging the Gemini Vision inference pipeline
/// to the nutrition log persistence layer.
///
/// Orchestrates the full flow:
/// 1. Accept raw image data
/// 2. Send to Gemini for food identification
/// 3. Convert inference result to a NutritionLog
/// 4. Persist via NutritionLogRepository
class InferenceRepository {
  final GeminiService _geminiService;
  final NutritionLogRepository _nutritionLogRepository;
  final Uuid _uuid;

  InferenceRepository({
    required GeminiService geminiService,
    required NutritionLogRepository nutritionLogRepository,
    Uuid? uuid,
  }) : _geminiService = geminiService,
       _nutritionLogRepository = nutritionLogRepository,
       _uuid = uuid ?? const Uuid();

  /// Analyze a food image file and persist the results.
  ///
  /// Returns the created [NutritionLog] entry on success.
  /// Throws [InferenceException] subclasses on failure.
  Future<NutritionLog> analyzeAndLog({
    required File imageFile,
    required String userId,
  }) async {
    _log.info('Starting inference pipeline for user: $userId');

    // ── 1. Read image bytes ─────────────────────────────────────────────
    final Uint8List imageBytes = await imageFile.readAsBytes();
    final mimeType = _inferMimeType(imageFile.path);
    _log.debug('Image loaded: ${imageBytes.length} bytes, type: $mimeType');

    // ── 2. Run inference ────────────────────────────────────────────────
    final InferenceResult result = await _geminiService.analyzeFood(
      imageBytes,
      mimeType: mimeType,
    );
    _log.info('Inference complete: ${result.foodItemIdentified}');

    // ── 3. Convert to NutritionLog ──────────────────────────────────────
    final log = _resultToLog(result, userId);

    // ── 4. Persist ──────────────────────────────────────────────────────
    final saved = await _nutritionLogRepository.addLog(log);
    _log.info('Log persisted: ${saved.logId}');

    return saved;
  }

  /// Run inference only without persisting — returns the raw result.
  ///
  /// Useful for previewing inference before the user confirms logging.
  Future<InferenceResult> analyzeOnly(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    _log.info('Running inference preview (no persist)');
    return _geminiService.analyzeFood(imageBytes, mimeType: mimeType);
  }

  /// Convert an [InferenceResult] to a [NutritionLog] model.
  NutritionLog _resultToLog(InferenceResult result, String userId) {
    return NutritionLog(
      logId: _uuid.v4(),
      userId: userId,
      foodName: result.foodItemIdentified,
      calories: result.caloriesKcal,
      proteinG: result.proteinsGrams,
      carbsG: result.carbohydratesGrams,
      fatsG: result.fatsGrams,
      confidenceScore: result.confidenceScore,
      servingSizeEstimate: result.servingSizeEstimate,
      loggedAt: DateTime.now(),
    );
  }

  /// Infer MIME type from file extension.
  String _inferMimeType(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
      case 'heif':
        return 'image/heic';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}

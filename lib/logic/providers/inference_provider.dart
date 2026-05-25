import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/gemini_service.dart';
import '../../data/models/nutrition_log.dart';
import '../../data/repositories/inference_repository.dart';
import '../../data/repositories/nutrition_log_repository.dart';

/// Provides the [GeminiService] singleton instance.
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Provides the [InferenceRepository] with its dependencies.
final inferenceRepositoryProvider = Provider<InferenceRepository>((ref) {
  return InferenceRepository(
    geminiService: ref.watch(geminiServiceProvider),
    nutritionLogRepository: ref.watch(_nutritionLogRepoProvider),
  );
});

/// Internal provider — avoids circular dependency with nutrition_log_provider.
final _nutritionLogRepoProvider = Provider<NutritionLogRepository>((ref) {
  return NutritionLogRepository();
});

/// Manages the state of an active inference operation.
///
/// Tracks loading, success, and error states for the food image
/// analysis pipeline. The UI layer will consume this to show
/// loading indicators and result previews.
class InferenceNotifier extends StateNotifier<InferenceState> {
  final InferenceRepository _repository;

  InferenceNotifier(this._repository) : super(const InferenceState.idle());

  /// Analyze a food image and persist the result.
  ///
  /// Updates state through: idle → loading → success/error.
  Future<void> analyzeAndLog({
    required File imageFile,
    required String userId,
  }) async {
    state = const InferenceState.loading();

    try {
      final log = await _repository.analyzeAndLog(
        imageFile: imageFile,
        userId: userId,
      );

      state = InferenceState.success(log: log);
    } on InferenceException catch (e) {
      state = InferenceState.error(message: e.message);
    } catch (e) {
      state = InferenceState.error(message: 'Unexpected error: $e');
    }
  }

  /// Reset state back to idle (e.g., after navigating away from results).
  void reset() {
    state = const InferenceState.idle();
  }
}

/// StateNotifierProvider for the inference pipeline.
final inferenceNotifierProvider =
    StateNotifierProvider<InferenceNotifier, InferenceState>((ref) {
  final repo = ref.watch(inferenceRepositoryProvider);
  return InferenceNotifier(repo);
});

/// Sealed state class for the inference pipeline.
///
/// Uses a discriminated union pattern to model the four possible states.
sealed class InferenceState {
  const InferenceState();

  const factory InferenceState.idle() = InferenceIdle;
  const factory InferenceState.loading() = InferenceLoading;
  const factory InferenceState.success({required NutritionLog log}) =
      InferenceSuccess;
  const factory InferenceState.error({required String message}) =
      InferenceError;
}

/// No inference operation in progress.
class InferenceIdle extends InferenceState {
  const InferenceIdle();
}

/// Inference is in progress (image being analyzed).
class InferenceLoading extends InferenceState {
  const InferenceLoading();
}

/// Inference completed successfully — contains the persisted log.
class InferenceSuccess extends InferenceState {
  final NutritionLog log;
  const InferenceSuccess({required this.log});
}

/// Inference failed — contains the error message.
class InferenceError extends InferenceState {
  final String message;
  const InferenceError({required this.message});
}

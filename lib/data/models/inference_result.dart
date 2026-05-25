import 'package:json_annotation/json_annotation.dart';

part 'inference_result.g.dart';

/// Represents the structured JSON response from the Gemini Vision
/// inference pipeline.
///
/// This model maps directly to the ML inference JSON schema defined
/// in the project specification (Section 3). It is NOT persisted in
/// Hive — it is a transient object used to bridge the inference
/// response to a [NutritionLog] entry.
///
/// Schema enforced on the LLM:
/// ```json
/// {
///   "food_item_identified": "String",
///   "confidence_score": "Float",
///   "calories_kcal": "Integer",
///   "proteins_grams": "Float",
///   "carbohydrates_grams": "Float",
///   "fats_grams": "Float",
///   "serving_size_estimate": "String"
/// }
/// ```
@JsonSerializable()
class InferenceResult {
  /// The food item name identified by the vision model.
  @JsonKey(name: 'food_item_identified')
  final String foodItemIdentified;

  /// Model confidence score (0.0–1.0).
  @JsonKey(name: 'confidence_score')
  final double confidenceScore;

  /// Estimated calorie count in kcal.
  @JsonKey(name: 'calories_kcal')
  final int caloriesKcal;

  /// Estimated protein content in grams.
  @JsonKey(name: 'proteins_grams')
  final double proteinsGrams;

  /// Estimated carbohydrate content in grams.
  @JsonKey(name: 'carbohydrates_grams')
  final double carbohydratesGrams;

  /// Estimated fat content in grams.
  @JsonKey(name: 'fats_grams')
  final double fatsGrams;

  /// Estimated serving size description.
  @JsonKey(name: 'serving_size_estimate')
  final String servingSizeEstimate;

  const InferenceResult({
    required this.foodItemIdentified,
    required this.confidenceScore,
    required this.caloriesKcal,
    required this.proteinsGrams,
    required this.carbohydratesGrams,
    required this.fatsGrams,
    required this.servingSizeEstimate,
  });

  /// Create an [InferenceResult] from the LLM JSON response.
  factory InferenceResult.fromJson(Map<String, dynamic> json) =>
      _$InferenceResultFromJson(json);

  /// Serialize to JSON (used for debugging/logging).
  Map<String, dynamic> toJson() => _$InferenceResultToJson(this);

  /// Validates that all numeric fields meet the guardrail constraints
  /// defined in the project specification (Section 3):
  /// - All nutrition values must be non-negative
  /// - Confidence score must be between 0.0 and 1.0
  ///
  /// Returns `true` if the result passes all guardrails.
  bool get isValid =>
      caloriesKcal >= 0 &&
      proteinsGrams >= 0 &&
      carbohydratesGrams >= 0 &&
      fatsGrams >= 0 &&
      confidenceScore >= 0.0 &&
      confidenceScore <= 1.0 &&
      foodItemIdentified.isNotEmpty;

  @override
  String toString() =>
      'InferenceResult(food: $foodItemIdentified, conf: $confidenceScore, '
      'cal: $caloriesKcal, P: ${proteinsGrams}g, C: ${carbohydratesGrams}g, '
      'F: ${fatsGrams}g, serving: $servingSizeEstimate)';
}

import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

import '../local/hive_boxes.dart';

part 'nutrition_log.g.dart';

/// Represents a single nutrition log entry in DietLog.
///
/// Maps to the `public.nutrition_logs` table in Supabase.
/// Annotated for both JSON serialization (Supabase REST API)
/// and Hive local caching (offline-first support).
@JsonSerializable()
@HiveType(typeId: HiveTypeIds.nutritionLog)
class NutritionLog extends HiveObject {
  /// Unique log entry identifier.
  @HiveField(0)
  @JsonKey(name: 'log_id')
  final String logId;

  /// ID of the user who created this log.
  @HiveField(1)
  @JsonKey(name: 'user_id')
  final String userId;

  /// Name of the food item identified by the ML inference pipeline.
  @HiveField(2)
  @JsonKey(name: 'food_name')
  final String foodName;

  /// Total calories in kcal (must be >= 0).
  @HiveField(3)
  @JsonKey(name: 'calories')
  final int calories;

  /// Protein content in grams (must be >= 0).
  @HiveField(4)
  @JsonKey(name: 'protein_g')
  final double proteinG;

  /// Carbohydrate content in grams (must be >= 0).
  @HiveField(5)
  @JsonKey(name: 'carbs_g')
  final double carbsG;

  /// Fat content in grams (must be >= 0).
  @HiveField(6)
  @JsonKey(name: 'fats_g')
  final double fatsG;

  /// ML model confidence score (0.0–1.0), nullable for manual entries.
  @HiveField(7)
  @JsonKey(name: 'confidence_score')
  final double? confidenceScore;

  /// Estimated serving size description from inference.
  @HiveField(8)
  @JsonKey(name: 'serving_size_estimate')
  final String? servingSizeEstimate;

  /// URL to the uploaded food image in Supabase Storage (nullable).
  @HiveField(9)
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  /// Timestamp when the log was recorded.
  @HiveField(10)
  @JsonKey(name: 'logged_at')
  final DateTime loggedAt;

  NutritionLog({
    required this.logId,
    required this.userId,
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatsG,
    this.confidenceScore,
    this.servingSizeEstimate,
    this.imageUrl,
    required this.loggedAt,
  });

  /// Create a [NutritionLog] from a Supabase JSON response.
  factory NutritionLog.fromJson(Map<String, dynamic> json) =>
      _$NutritionLogFromJson(json);

  /// Serialize this log entry to JSON for Supabase insert operations.
  Map<String, dynamic> toJson() => _$NutritionLogToJson(this);

  /// Total macronutrient grams (protein + carbs + fats).
  double get totalMacrosG => proteinG + carbsG + fatsG;

  /// Create a copy with selective field overrides.
  NutritionLog copyWith({
    String? logId,
    String? userId,
    String? foodName,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatsG,
    double? confidenceScore,
    String? servingSizeEstimate,
    String? imageUrl,
    DateTime? loggedAt,
  }) {
    return NutritionLog(
      logId: logId ?? this.logId,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatsG: fatsG ?? this.fatsG,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      servingSizeEstimate: servingSizeEstimate ?? this.servingSizeEstimate,
      imageUrl: imageUrl ?? this.imageUrl,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  String toString() =>
      'NutritionLog(logId: $logId, food: $foodName, cal: $calories, '
      'P: ${proteinG}g, C: ${carbsG}g, F: ${fatsG}g)';
}

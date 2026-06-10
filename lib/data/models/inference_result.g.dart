// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inference_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InferenceResult _$InferenceResultFromJson(Map<String, dynamic> json) =>
    InferenceResult(
      foodItemIdentified: json['food_item_identified'] as String,
      confidenceScore: _safeDouble(json['confidence_score']),
      caloriesKcal: _safeInt(json['calories_kcal']),
      proteinsGrams: _safeDouble(json['proteins_grams']),
      carbohydratesGrams: _safeDouble(json['carbohydrates_grams']),
      fatsGrams: _safeDouble(json['fats_grams']),
      servingSizeEstimate: json['serving_size_estimate'] as String,
    );

Map<String, dynamic> _$InferenceResultToJson(InferenceResult instance) =>
    <String, dynamic>{
      'food_item_identified': instance.foodItemIdentified,
      'confidence_score': instance.confidenceScore,
      'calories_kcal': instance.caloriesKcal,
      'proteins_grams': instance.proteinsGrams,
      'carbohydrates_grams': instance.carbohydratesGrams,
      'fats_grams': instance.fatsGrams,
      'serving_size_estimate': instance.servingSizeEstimate,
    };

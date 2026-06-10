import 'package:flutter_test/flutter_test.dart';
import 'package:diet_log/data/models/inference_result.dart';

void main() {
  group('InferenceResult Serialization & Deserialization Tests', () {
    test('Successful parsing of completely valid JSON data', () {
      final json = {
        'food_item_identified': 'Apple',
        'confidence_score': 0.95,
        'calories_kcal': 95,
        'proteins_grams': 0.5,
        'carbohydrates_grams': 25.0,
        'fats_grams': 0.3,
        'serving_size_estimate': '1 medium',
      };

      final result = InferenceResult.fromJson(json);

      expect(result.foodItemIdentified, 'Apple');
      expect(result.confidenceScore, 0.95);
      expect(result.caloriesKcal, 95);
      expect(result.proteinsGrams, 0.5);
      expect(result.carbohydratesGrams, 25.0);
      expect(result.fatsGrams, 0.3);
      expect(result.servingSizeEstimate, '1 medium');
      expect(result.isValid, true);
    });

    test(
      'Resilient recovery from dynamic runtime type-casting errors (Strings instead of Int/Double)',
      () {
        final json = {
          'food_item_identified': 'Banana',
          'confidence_score': '0.88',
          'calories_kcal': '105',
          'proteins_grams': '1.3',
          'carbohydrates_grams': '27',
          'fats_grams': '0.4',
          'serving_size_estimate': '1 large',
        };

        final result = InferenceResult.fromJson(json);

        expect(result.foodItemIdentified, 'Banana');
        expect(result.confidenceScore, 0.88);
        expect(result.caloriesKcal, 105);
        expect(result.proteinsGrams, 1.3);
        expect(result.carbohydratesGrams, 27.0);
        expect(result.fatsGrams, 0.4);
        expect(result.servingSizeEstimate, '1 large');
        expect(result.isValid, true);
      },
    );

    test(
      'Graceful fallback handling when expected fields are null or corrupted',
      () {
        final json = {
          'food_item_identified': 'Unknown Food',
          'confidence_score': null,
          'calories_kcal': 'invalid_number',
          'proteins_grams': null,
          'carbohydrates_grams': 'not_a_double',
          'fats_grams': null,
          'serving_size_estimate': 'N/A',
        };

        final result = InferenceResult.fromJson(json);

        expect(result.foodItemIdentified, 'Unknown Food');
        expect(result.confidenceScore, 0.0);
        expect(result.caloriesKcal, 0);
        expect(result.proteinsGrams, 0.0);
        expect(result.carbohydratesGrams, 0.0);
        expect(result.fatsGrams, 0.0);
        expect(result.servingSizeEstimate, 'N/A');
      },
    );
  });
}

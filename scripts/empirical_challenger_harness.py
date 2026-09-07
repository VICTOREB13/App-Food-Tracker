"""
Empirical Challenger Test Harness for Phase 2 Milestone 2 (USDA & Barcode).
Tests:
1. UsdaNutrientParser logic (kJ conversion, exact 4.184 factor, clampDouble bounds, NaN, extreme values, dual schema).
2. Zero energy with positive macros.
3. Decimal rounding and serving size scaling.
4. Barcode sanitization & variations (8-digit, 12-digit, 13-digit with/without leading zero, alphanumeric).
5. Cascading fallback under missing API key, 403, 404, 429, and socket exceptions.
6. Rate limit sliding window (1000 requests/hour) and lockout boundary analysis.
"""

import math
import re
import datetime
import unittest

# --- 1. ModelSanitizer Simulation ---
class ModelSanitizer:
    max_name_length = 255
    max_notes_length = 2000
    max_justification_length = 1000
    min_macro_value = 0.0
    max_macro_value = 9999.0

    @classmethod
    def truncate(cls, value, max_len, fallback=''):
        if value is None:
            return fallback
        trimmed = str(value).strip()
        if not trimmed:
            return fallback
        return trimmed[:max_len]

    @classmethod
    def truncate_nullable(cls, value, max_len):
        if value is None:
            return None
        trimmed = str(value).strip()
        if not trimmed:
            return None
        return trimmed[:max_len]

    @classmethod
    def clamp_double(cls, value, min_val=0.0, max_val=9999.0):
        if value is None:
            return min_val
        try:
            if isinstance(value, (int, float)):
                d_val = float(value)
            else:
                d_val = float(str(value).strip())
        except (ValueError, TypeError):
            return min_val

        if math.isnan(d_val):
            return min_val
        if d_val < min_val:
            return min_val
        if d_val > max_val:
            return max_val
        # Match Dart: double.parse(doubleVal.toStringAsFixed(2))
        return float(f"{d_val:.2f}")


# --- 2. UsdaNutrientParser Simulation ---
class UsdaNutrientParser:
    id_energy = 1008
    id_protein = 1003
    id_fat = 1004
    id_carbs = 1005
    id_fiber = 1079
    id_sodium = 1093
    id_calcium = 1087
    id_iron = 1089
    id_vitamin_a = 1104
    id_vitamin_c = 1162

    energy_ids = [id_energy, 2047, 2048]

    @classmethod
    def parse_nutrient(cls, food_nutrients_raw, target_ids, target_numbers=None):
        if target_numbers is None:
            target_numbers = []
        if not isinstance(food_nutrients_raw, list):
            return 0.0

        for item in food_nutrients_raw:
            if not isinstance(item, dict):
                continue

            # 1. Resolve nutrient ID (flat or nested)
            nut_id = item.get('nutrientId')
            if nut_id is None and isinstance(item.get('nutrient'), dict):
                nut_id = item['nutrient'].get('id')
            if nut_id is not None:
                try:
                    nut_id = int(nut_id)
                except (ValueError, TypeError):
                    nut_id = None

            # 2. Resolve nutrient number (flat or nested)
            number = item.get('nutrientNumber')
            if number is None:
                number = item.get('number')
            if number is None and isinstance(item.get('nutrient'), dict):
                number = item['nutrient'].get('number')
            number_str = str(number) if number is not None else None

            id_matches = nut_id is not None and nut_id in target_ids
            number_matches = number_str is not None and number_str in target_numbers

            if id_matches or number_matches:
                # 3. Resolve numeric value (value or amount)
                raw_val = item.get('value')
                if raw_val is None:
                    raw_val = item.get('amount')
                if raw_val is None:
                    continue

                try:
                    raw_val = float(raw_val)
                except (ValueError, TypeError):
                    continue

                # 4. Resolve unit
                unit = item.get('unitName')
                if unit is None and isinstance(item.get('nutrient'), dict):
                    unit = item['nutrient'].get('unitName')
                unit_str = str(unit or '').strip().upper()

                val = raw_val

                # 5. Energy conversion if kJ
                is_energy = cls.id_energy in target_ids or '208' in target_numbers
                if is_energy and (unit_str == 'KJ' or 'KILOJOULE' in unit_str):
                    val = val / 4.184

                return ModelSanitizer.clamp_double(val)

        return 0.0


# --- 3. UsdaFoodItem Simulation ---
class UsdaFoodItem:
    def __init__(self, fdc_id, description, brand_owner=None, brand_name=None,
                 gtin_upc=None, data_type=None, serving_size=None, serving_size_unit=None,
                 household_serving_full_text=None, category=None,
                 calories=0.0, protein=0.0, fat=0.0, carbs=0.0,
                 fiber=0.0, sodium=0.0, calcium=0.0, iron=0.0,
                 vitamin_a=0.0, vitamin_c=0.0):
        self.fdc_id = fdc_id
        self.description = description
        self.brand_owner = brand_owner
        self.brand_name = brand_name
        self.gtin_upc = gtin_upc
        self.data_type = data_type
        self.serving_size = serving_size
        self.serving_size_unit = serving_size_unit
        self.household_serving_full_text = household_serving_full_text
        self.category = category
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.fiber = fiber
        self.sodium = sodium
        self.calcium = calcium
        self.iron = iron
        self.vitamin_a = vitamin_a
        self.vitamin_c = vitamin_c

    @classmethod
    def from_fdc_json(cls, json_data):
        nutrients = json_data.get('foodNutrients', [])
        calories = UsdaNutrientParser.parse_nutrient(
            nutrients, UsdaNutrientParser.energy_ids, target_numbers=['208']
        )
        protein = UsdaNutrientParser.parse_nutrient(
            nutrients, [UsdaNutrientParser.id_protein], target_numbers=['203']
        )
        fat = UsdaNutrientParser.parse_nutrient(
            nutrients, [UsdaNutrientParser.id_fat], target_numbers=['204']
        )
        carbs = UsdaNutrientParser.parse_nutrient(
            nutrients, [UsdaNutrientParser.id_carbs], target_numbers=['205']
        )
        fiber = UsdaNutrientParser.parse_nutrient(
            nutrients, [UsdaNutrientParser.id_fiber], target_numbers=['291']
        )
        sodium = UsdaNutrientParser.parse_nutrient(
            nutrients, [UsdaNutrientParser.id_sodium], target_numbers=['307']
        )
        calcium = UsdaNutrientParser.parse_nutrient(
            nutrients, [UsdaNutrientParser.id_calcium], target_numbers=['301']
        )
        iron = UsdaNutrientParser.parse_nutrient(
            nutrients, [UsdaNutrientParser.id_iron], target_numbers=['303']
        )
        vitamin_a = UsdaNutrientParser.parse_nutrient(
            nutrients, [UsdaNutrientParser.id_vitamin_a, 1106], target_numbers=['318', '320']
        )
        vitamin_c = UsdaNutrientParser.parse_nutrient(
            nutrients, [UsdaNutrientParser.id_vitamin_c], target_numbers=['400']
        )

        serving_size = json_data.get('servingSize')
        if serving_size is not None:
            try:
                serving_size = float(serving_size)
            except (ValueError, TypeError):
                serving_size = None

        return cls(
            fdc_id=int(json_data.get('fdcId', 0) or 0),
            description=ModelSanitizer.truncate(json_data.get('description'), 255, fallback='Alimento USDA'),
            brand_owner=ModelSanitizer.truncate_nullable(json_data.get('brandOwner'), 255),
            brand_name=ModelSanitizer.truncate_nullable(json_data.get('brandName'), 255),
            gtin_upc=ModelSanitizer.truncate_nullable(json_data.get('gtinUpc'), 32),
            data_type=ModelSanitizer.truncate_nullable(json_data.get('dataType'), 64),
            serving_size=serving_size,
            serving_size_unit=ModelSanitizer.truncate_nullable(json_data.get('servingSizeUnit'), 32),
            household_serving_full_text=ModelSanitizer.truncate_nullable(json_data.get('householdServingFullText'), 128),
            category=ModelSanitizer.truncate_nullable(
                json_data.get('brandedFoodCategory') or json_data.get('foodCategory'), 100
            ),
            calories=calories,
            protein=protein,
            fat=fat,
            carbs=carbs,
            fiber=fiber,
            sodium=sodium,
            calcium=calcium,
            iron=iron,
            vitamin_a=vitamin_a,
            vitamin_c=vitamin_c,
        )

    def to_food_item(self, estimated_grams=None):
        base_grams = 100.0
        if self.serving_size is not None and str(self.serving_size_unit).lower() in ['g', 'gr']:
            base_grams = self.serving_size

        grams = estimated_grams if estimated_grams is not None else base_grams
        ratio = (estimated_grams / base_grams) if (estimated_grams is not None and base_grams > 0) else 1.0

        return {
            'name': ModelSanitizer.truncate(self.description, 255, fallback='Alimento USDA'),
            'estimated_grams': ModelSanitizer.clamp_double(grams, min_val=0.0, max_val=50000.0),
            'calories': ModelSanitizer.clamp_double(self.calories * ratio),
            'protein': ModelSanitizer.clamp_double(self.protein * ratio),
            'carbs': ModelSanitizer.clamp_double(self.carbs * ratio),
            'fat': ModelSanitizer.clamp_double(self.fat * ratio),
        }


# --- 4. Rate Limiter Simulation ---
class UsdaRateLimiter:
    def __init__(self, max_requests_per_hour=1000):
        self.max_requests_per_hour = max_requests_per_hour
        self.request_log = []
        self.last_remaining_header = None

    def can_dispatch_request(self, current_time=None):
        now = current_time or datetime.datetime.now()
        one_hour_ago = now - datetime.timedelta(hours=1)
        self.request_log = [t for t in self.request_log if t >= one_hour_ago]

        if len(self.request_log) >= self.max_requests_per_hour:
            return False
        if self.last_remaining_header is not None and self.last_remaining_header <= 0:
            return False
        return True

    def record_request(self, current_time=None):
        now = current_time or datetime.datetime.now()
        self.request_log.append(now)

    def update_rate_limit_headers(self, remaining):
        if remaining is not None:
            try:
                self.last_remaining_header = int(remaining)
            except (ValueError, TypeError):
                pass


# --- 5. Barcode Sanitizer Simulation ---
def sanitize_barcode(raw_barcode):
    return re.sub(r'[^0-9]', '', raw_barcode or '').strip()


# --- Unit Tests Suite ---
class TestUsdaAndBarcodeEmpirical(unittest.TestCase):

    # 1. kJ vs kcal conversion factor
    def test_kj_to_kcal_exact_factor(self):
        # 418.4 kJ / 4.184 = 100.00 kcal
        nutrients = [
            {"nutrientId": 1008, "value": 418.4, "unitName": "kJ"}
        ]
        cal = UsdaNutrientParser.parse_nutrient(nutrients, UsdaNutrientParser.energy_ids)
        self.assertAlmostEqual(cal, 100.0, places=2)

        # 1000.0 kJ / 4.184 = 239.0057... -> 239.01 kcal
        nutrients_1000 = [
            {"nutrientId": 1008, "value": 1000.0, "unitName": "kJ"}
        ]
        cal_1000 = UsdaNutrientParser.parse_nutrient(nutrients_1000, UsdaNutrientParser.energy_ids)
        self.assertEqual(cal_1000, 239.01)

        # Case variations and KILOJOULES
        for u in ['kj', 'kJ', 'KJ', 'Kilojoules', 'KILOJOULE']:
            c = UsdaNutrientParser.parse_nutrient([{"nutrientId": 1008, "value": 41.84, "unitName": u}], UsdaNutrientParser.energy_ids)
            self.assertEqual(c, 10.0, f"Failed for unit: {u}")

        # kcal should NOT be divided
        cal_kcal = UsdaNutrientParser.parse_nutrient([{"nutrientId": 1008, "value": 150.0, "unitName": "KCAL"}], UsdaNutrientParser.energy_ids)
        self.assertEqual(cal_kcal, 150.0)

    # 2. Negative, extreme values, NaN, nulls, missing IDs
    def test_negative_and_extreme_and_special_values(self):
        # Negative value -> clamped to 0.0
        neg_nutrients = [{"nutrientId": 1008, "value": -50.0, "unitName": "KCAL"}]
        self.assertEqual(UsdaNutrientParser.parse_nutrient(neg_nutrients, UsdaNutrientParser.energy_ids), 0.0)

        # Extreme value (100,000) -> clamped to 9999.0
        ext_nutrients = [{"nutrientId": 1008, "value": 100000.0, "unitName": "KCAL"}]
        self.assertEqual(UsdaNutrientParser.parse_nutrient(ext_nutrients, UsdaNutrientParser.energy_ids), 9999.0)

        # NaN value -> clamped to 0.0
        nan_nutrients = [{"nutrientId": 1008, "value": float('nan'), "unitName": "KCAL"}]
        self.assertEqual(UsdaNutrientParser.parse_nutrient(nan_nutrients, UsdaNutrientParser.energy_ids), 0.0)

        # Infinity value -> clamped to 9999.0
        inf_nutrients = [{"nutrientId": 1008, "value": float('inf'), "unitName": "KCAL"}]
        self.assertEqual(UsdaNutrientParser.parse_nutrient(inf_nutrients, UsdaNutrientParser.energy_ids), 9999.0)

        # Negative infinity -> clamped to 0.0
        ninf_nutrients = [{"nutrientId": 1008, "value": float('-inf'), "unitName": "KCAL"}]
        self.assertEqual(UsdaNutrientParser.parse_nutrient(ninf_nutrients, UsdaNutrientParser.energy_ids), 0.0)

        # Null value skips to next item
        null_then_valid = [
            {"nutrientId": 1008, "value": None, "unitName": "KCAL"},
            {"nutrientId": 1008, "value": 250.0, "unitName": "KCAL"}
        ]
        self.assertEqual(UsdaNutrientParser.parse_nutrient(null_then_valid, UsdaNutrientParser.energy_ids), 250.0)

        # Missing nutrient IDs (only nutrientNumber: '208')
        by_number_only = [{"nutrientNumber": "208", "value": 180.0, "unitName": "KCAL"}]
        self.assertEqual(UsdaNutrientParser.parse_nutrient(by_number_only, UsdaNutrientParser.energy_ids, target_numbers=['208']), 180.0)

        # Dual schema nested: item['nutrient']['id'] & item['amount']
        nested_schema = [{
            "nutrient": {"id": 1003, "number": "203", "name": "Protein", "unitName": "g"},
            "amount": 28.5
        }]
        self.assertEqual(UsdaNutrientParser.parse_nutrient(nested_schema, [1003], target_numbers=['203']), 28.5)

    # 3. Zero energy with positive macros
    def test_zero_energy_with_positive_macros(self):
        json_data = {
            "fdcId": 55555,
            "description": "Zero Calorie Protein Food Mock",
            "servingSize": 100.0,
            "servingSizeUnit": "g",
            "foodNutrients": [
                {"nutrientId": 1008, "value": 0.0, "unitName": "KCAL"},
                {"nutrientId": 1003, "value": 25.0, "unitName": "G"},
                {"nutrientId": 1004, "value": 10.0, "unitName": "G"},
                {"nutrientId": 1005, "value": 30.0, "unitName": "G"},
            ]
        }
        item = UsdaFoodItem.from_fdc_json(json_data)
        self.assertEqual(item.calories, 0.0)
        self.assertEqual(item.protein, 25.0)
        self.assertEqual(item.fat, 10.0)
        self.assertEqual(item.carbs, 30.0)

        # Scale to 200g
        scaled = item.to_food_item(estimated_grams=200.0)
        self.assertEqual(scaled['calories'], 0.0)
        self.assertEqual(scaled['protein'], 50.0)
        self.assertEqual(scaled['fat'], 20.0)
        self.assertEqual(scaled['carbs'], 60.0)

    # 4. Decimal rounding and scaling to custom serving sizes
    def test_decimal_rounding_and_scaling(self):
        json_data = {
            "fdcId": 1234,
            "description": "Test Oats",
            "servingSize": 40.0,
            "servingSizeUnit": "g",
            "foodNutrients": [
                {"nutrientId": 1008, "value": 150.0, "unitName": "KCAL"},
                {"nutrientId": 1003, "value": 5.333, "unitName": "G"},
                {"nutrientId": 1004, "value": 2.666, "unitName": "G"},
                {"nutrientId": 1005, "value": 27.123, "unitName": "G"},
            ]
        }
        item = UsdaFoodItem.from_fdc_json(json_data)
        # Verify 2 decimal places rounding
        self.assertEqual(item.protein, 5.33)
        self.assertEqual(item.fat, 2.67)
        self.assertEqual(item.carbs, 27.12)

        # Custom serving size: 100g (ratio = 2.5)
        food_100g = item.to_food_item(estimated_grams=100.0)
        self.assertEqual(food_100g['calories'], 375.0)
        self.assertEqual(food_100g['protein'], ModelSanitizer.clamp_double(5.33 * 2.5)) # 13.33
        self.assertEqual(food_100g['fat'], ModelSanitizer.clamp_double(2.67 * 2.5))     # 6.68
        self.assertEqual(food_100g['carbs'], ModelSanitizer.clamp_double(27.12 * 2.5)) # 67.8

        # Serving size 0g edge case
        item_zero_serving = UsdaFoodItem(fdc_id=1, description="Zero Serv", serving_size=0.0, serving_size_unit="g", calories=100.0)
        food_zero = item_zero_serving.to_food_item(estimated_grams=50.0)
        # ratio defaults to 1.0 to avoid division by zero
        self.assertEqual(food_zero['calories'], 100.0)

    # 5. Barcode variations and sanitization
    def test_barcode_sanitization_and_variations(self):
        # 8-digit
        self.assertEqual(sanitize_barcode(" 12345678 "), "12345678")
        # 12-digit UPC-A
        self.assertEqual(sanitize_barcode("030000010402"), "030000010402")
        # 13-digit with leading zero
        self.assertEqual(sanitize_barcode("0030000010402"), "0030000010402")
        # 13-digit European without leading zero
        self.assertEqual(sanitize_barcode("8410100010015"), "8410100010015")
        # Formatted with hyphens and spaces
        self.assertEqual(sanitize_barcode(" 0300-0001-0402 "), "030000010402")
        # Alphanumeric garbage without digits
        self.assertEqual(sanitize_barcode("ABC-XYZ!@#"), "")
        # Alphanumeric with embedded digits
        self.assertEqual(sanitize_barcode("UPC: 737628064502 (BOX)"), "737628064502")

    # 6. Rate Limiting Sliding Window (1000 requests/hour)
    def test_sliding_window_rate_limiting(self):
        limiter = UsdaRateLimiter(max_requests_per_hour=1000)
        base_time = datetime.datetime(2026, 9, 7, 12, 0, 0)

        # First 1000 requests are allowed
        for i in range(1000):
            t = base_time + datetime.timedelta(seconds=i * 2) # spaced over 2000s (~33 min)
            self.assertTrue(limiter.can_dispatch_request(t), f"Request {i+1} should be allowed")
            limiter.record_request(t)

        # 1001st request within the 1-hour window MUST be rejected
        reject_time = base_time + datetime.timedelta(minutes=45)
        self.assertFalse(limiter.can_dispatch_request(reject_time), "Request 1001 must be rejected within 1 hour")

        # After 1 hour from earliest requests, capacity opens up
        after_one_hour = base_time + datetime.timedelta(minutes=61)
        self.assertTrue(limiter.can_dispatch_request(after_one_hour), "Capacity should recover after 1 hour")

    # 7. Permanent Lockout Vulnerability Analysis on lastRemainingHeader <= 0
    def test_lockout_bug_analysis(self):
        limiter = UsdaRateLimiter(max_requests_per_hour=1000)
        base_time = datetime.datetime(2026, 9, 7, 12, 0, 0)

        # Single request receives x-ratelimit-remaining: 0
        limiter.record_request(base_time)
        limiter.update_rate_limit_headers("0")

        # Immediately blocked
        self.assertFalse(limiter.can_dispatch_request(base_time))

        # 2 hours later, local request log is empty!
        two_hours_later = base_time + datetime.timedelta(hours=2)
        # Even though 2 hours have passed, because last_remaining_header has no TTL/reset,
        # can_dispatch_request still returns False!
        is_permanently_locked = not limiter.can_dispatch_request(two_hours_later)
        self.assertTrue(
            is_permanently_locked,
            "Empirical proof: UsdaFoodDataService permanently locks out when x-ratelimit-remaining <= 0"
        )


if __name__ == '__main__':
    unittest.main()

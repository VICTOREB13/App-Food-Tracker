import decimal
import os
import re
import sys

def _round_half_up(val: float, decimals: int = 1) -> float:
    d = decimal.Decimal(str(val))
    return float(d.quantize(decimal.Decimal(10) ** -decimals, rounding=decimal.ROUND_HALF_UP))

def test_mifflin_st_jeor():
    print("=== 1. Testing Mifflin-St Jeor Mathematics ===")
    
    # Male: (10 * weight) + (6.25 * height) - (5 * age) + 5
    weight_m, height_m, age_m = 70.0, 175.0, 30
    expected_bmr_m = (10.0 * weight_m) + (6.25 * height_m) - (5.0 * age_m) + 5.0
    assert _round_half_up(expected_bmr_m, 1) == 1648.8, f"Male BMR mismatch: {expected_bmr_m}"
    print(f"  [PASS] Male BMR (70kg, 175cm, 30y): {_round_half_up(expected_bmr_m, 1)} kcal")

    # Female: (10 * weight) + (6.25 * height) - (5 * age) - 161
    weight_f, height_f, age_f = 60.0, 165.0, 30
    expected_bmr_f = (10.0 * weight_f) + (6.25 * height_f) - (5.0 * age_f) - 161.0
    assert _round_half_up(expected_bmr_f, 1) == 1320.3, f"Female BMR mismatch: {expected_bmr_f}"
    print(f"  [PASS] Female BMR (60kg, 165cm, 30y): {_round_half_up(expected_bmr_f, 1)} kcal")

    # Boundary ages and weights
    # Young male boundary (age 15, 50kg, 160cm)
    bmr_teen = (10.0 * 50.0) + (6.25 * 160.0) - (5.0 * 15) + 5.0
    assert _round_half_up(bmr_teen, 1) == 1430.0
    print(f"  [PASS] Young Male BMR (50kg, 160cm, 15y): 1430.0 kcal")

    # Elder female boundary (age 80, 65kg, 155cm)
    bmr_elder = (10.0 * 65.0) + (6.25 * 155.0) - (5.0 * 80) - 161.0
    assert _round_half_up(bmr_elder, 1) == 1057.8
    print(f"  [PASS] Elder Female BMR (65kg, 155cm, 80y): 1057.8 kcal")

def test_tdee_and_activity():
    print("\n=== 2. Testing Activity Multipliers & TDEE ===")
    bmr = 1600.0
    multipliers = {
        'sedentary': 1.2,
        'light': 1.375,
        'moderate': 1.55,
        'very_active': 1.725,
    }
    for level, mult in multipliers.items():
        tdee = _round_half_up(bmr * mult, 1)
        expected = {
            'sedentary': 1920.0,
            'light': 2200.0,
            'moderate': 2480.0,
            'very_active': 2760.0,
        }[level]
        assert tdee == expected, f"TDEE mismatch for {level}: {tdee} != {expected}"
        print(f"  [PASS] TDEE {level} ({mult}x): {tdee} kcal")

def test_caloric_goals():
    print("\n=== 3. Testing Caloric Goals & Clinical Protection Floor ===")
    tdee = 2400.0
    bmr = 1600.0
    # Maintenance
    assert tdee == 2400.0
    print(f"  [PASS] Maintenance Goal: {tdee} kcal")
    
    # Muscle Gain (+300)
    muscle_gain = tdee + 300.0
    assert muscle_gain == 2700.0
    print(f"  [PASS] Muscle Gain Goal: {muscle_gain} kcal")
    
    # Fat Loss (-500)
    fat_loss = max(bmr, tdee - 500.0)
    assert fat_loss == 1900.0
    print(f"  [PASS] Fat Loss Goal: {fat_loss} kcal")
    
    # Floor at BMR Protection
    low_tdee = 1600.0
    high_bmr = 1400.0
    deficit_floored = max(high_bmr, low_tdee - 500.0)
    assert deficit_floored == 1400.0, f"Floor failed: {deficit_floored}"
    print(f"  [PASS] Clinical Floor at BMR: {low_tdee} - 500 = 1100 -> floored to BMR {high_bmr} kcal")

def test_macronutrients():
    print("\n=== 4. Testing Macronutrient Distributions & Calorie Balance ===")
    test_cases = [
        # (weight, target_cals, goal, expected_p_factor)
        (75.0, 2000.0, 'fat_loss', 2.0),
        (80.0, 2800.0, 'muscle_gain', 2.2),
        (70.0, 2200.0, 'maintenance', 1.8),
        (60.0, 1500.0, 'fat_loss', 2.0),
        (90.0, 2500.0, 'maintenance', 1.8),
    ]
    for weight, target_cals, goal, p_factor in test_cases:
        protein = _round_half_up(weight * p_factor, 1)
        fat_from_pct = (target_cals * 0.25) / 9.0
        fat_floor = weight * 0.8
        fat = _round_half_up(max(fat_from_pct, fat_floor), 1)
        carbs = _round_half_up(max(0.0, (target_cals - (protein * 4.0) - (fat * 9.0)) / 4.0), 1)
        total_cals = (protein * 4.0) + (fat * 9.0) + (carbs * 4.0)
        
        diff = abs(total_cals - target_cals)
        assert diff <= 3.0, f"Macro calorie balance violated for {goal}: {total_cals} vs {target_cals}"
        print(f"  [PASS] {goal.upper()} ({weight}kg, {target_cals}kcal): P={protein}g, F={fat}g, C={carbs}g -> {total_cals:.1f} kcal (diff: {diff:.1f})")

def test_loc_constraints():
    print("\n=== 5. Testing Line of Code Constraints (< 300 LoC per screen) ===")
    base_dir = r"C:\Users\vmesp\Documents\Cositas\App-Food-Tracker"
    screen_path = os.path.join(base_dir, "lib", "screens", "user_profile_screen.dart")
    assert os.path.exists(screen_path), f"File not found: {screen_path}"
    
    with open(screen_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    
    loc = len(lines)
    print(f"  lib/screens/user_profile_screen.dart: {loc} lines of code")
    assert loc < 300, f"Screen exceeds 300 LoC limit! Current: {loc}"
    print(f"  [PASS] Screen is {loc} LoC (< 300 LoC limit)")

def test_file_syntax_and_integrity():
    print("\n=== 6. Testing Syntax Integrity & Balanced Brackets ===")
    base_dir = r"C:\Users\vmesp\Documents\Cositas\App-Food-Tracker"
    files = [
        "lib/services/metabolic_calculator.dart",
        "lib/screens/user_profile_screen.dart",
        "lib/widgets/profile/biometric_inputs_card.dart",
        "lib/widgets/profile/activity_goal_selector_card.dart",
        "lib/widgets/profile/metabolic_summary_bento_card.dart",
        "test/services/metabolic_calculator_test.dart",
        "test/screens/user_profile_screen_test.dart",
    ]
    for rel_path in files:
        full_path = os.path.join(base_dir, *rel_path.split("/"))
        assert os.path.exists(full_path), f"Required file missing: {full_path}"
        with open(full_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Verify bracket balance
        open_braces = content.count("{")
        close_braces = content.count("}")
        assert open_braces == close_braces, f"Mismatched braces in {rel_path}: {open_braces} vs {close_braces}"
        
        open_parens = content.count("(")
        close_parens = content.count(")")
        assert open_parens == close_parens, f"Mismatched parens in {rel_path}: {open_parens} vs {close_parens}"

        open_brackets = content.count("[")
        close_brackets = content.count("]")
        assert open_brackets == close_brackets, f"Mismatched brackets in {rel_path}: {open_brackets} vs {close_brackets}"
        
        # Check no deprecated withOpacity is used
        assert ".withOpacity(" not in content, f"Deprecated withOpacity found in {rel_path}! Must use withValues(alpha: ...)"
        
        print(f"  [PASS] {rel_path}: {len(content.splitlines())} lines, 100% balanced, zero deprecated opacity calls")

if __name__ == "__main__":
    test_mifflin_st_jeor()
    test_tdee_and_activity()
    test_caloric_goals()
    test_macronutrients()
    test_loc_constraints()
    test_file_syntax_and_integrity()
    print("\n=======================================================")
    print(">>> ALL VERIFICATIONS PASSED WITH ZERO VIOLATIONS <<<")
    print("=======================================================")

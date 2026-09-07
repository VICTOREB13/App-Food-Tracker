import decimal
import math
import re
import sys

def round_half_up(val: float, decimals: int = 1) -> float:
    d = decimal.Decimal(str(val))
    return float(d.quantize(decimal.Decimal(10) ** -decimals, rounding=decimal.ROUND_HALF_UP))

def mifflin_bmr(gender: str, weight: float, height: float, age: int) -> float:
    is_female = gender.lower() in [female, femenino, mujer, f]
    offset = -161.0 if is_female else 5.0
    bmr = (10.0 * weight) + (6.25 * height) - (5.0 * age) + offset
    return round_half_up(bmr, 1)

def tdee(bmr: float, activity: str) -> float:
    act = activity.lower()
    if very in act or muy in act or intenso in act:
        m = 1.725
    elif moderat in act or moderado in act:
        m = 1.55
    elif light in act or ligero in act:
        m = 1.375
    else:
        m = 1.2
    return round_half_up(bmr * m, 1)

def caloric_goal(tdee_val: float, bmr_val: float, goal: str) -> float:
    g = goal.lower()
    if any(k in g for k in [fat, perdid, deficit, déficit, grasa]):
        raw = tdee_val - 500.0
        target = max(bmr_val, raw)
    elif any(k in g for k in [gain, gananc, superavit, superávit, musculo, músculo]):
        target = tdee_val + 300.0
    else:
        target = tdee_val
    return round_half_up(target, 1)

def macros(target_cals: float, weight: float, goal: str):
    g = goal.lower()
    if any(k in g for k in [fat, perdid, deficit, déficit, grasa]):
        p_factor = 2.0
    elif any(k in g for k in [gain, gananc, superavit, superávit, musculo, músculo]):
        p_factor = 2.2
    else:
        p_factor = 1.8
    protein = round_half_up(weight * p_factor, 1)
    fat_pct = (target_cals * 0.25) / 9.0
    fat_floor = weight * 0.8
    fat = round_half_up(max(fat_pct, fat_floor), 1)
    rem_cals = target_cals - (protein * 4.0) - (fat * 9.0)
    carbs = round_half_up(max(0.0, rem_cals / 4.0), 1)
    return protein, carbs, fat

def run_adversarial_suite():
    print(=== ADVERSARIAL STRESS SUITE: METABOLIC ENGINE ===)

    # Test 1: Biological Sex Gender Delta Invariant
    # For identical biometrics, Male BMR - Female BMR MUST BE EXACTLY 166.0 kcal (5 - (-161) = 166)
    for w in [50.0, 70.0, 95.5, 120.0]:
        for h in [150.0, 175.0, 190.0]:
            for a in [20, 35, 60, 80]:
                bmr_m = mifflin_bmr(male, w, h, a)
                bmr_f = mifflin_bmr(female, w, h, a)
                delta = round(bmr_m - bmr_f, 1)
                assert delta == 166.0, fGender delta violated for ({w}kg, {h}cm, {a}y): {bmr_m} - {bmr_f} = {delta}
    print( [PASS] Gender Invariant Delta (Male BMR - Female BMR == 166.0 kcal) holds across all parameter sweeps.)

    # Test 2: Starvation Floor Defense
    # Test cases where TDEE - 500 would drop below BMR
    small_cases = [
        # (weight, height, age, gender, activity)
        (45.0, 150.0, 45, female, sedentary),
        (50.0, 155.0, 60, female, sedentary),
        (55.0, 160.0, 70, male, sedentary),
    ]
    for w, h, a, g, act in small_cases:
        b = mifflin_bmr(g, w, h, a)
        t = tdee(b, act)
        goal_cals = caloric_goal(t, b, fat_loss)
        assert goal_cals >= b, fStarvation floor breached! Goal {goal_cals} < BMR {b}
        print(f [PASS] Starvation Defense: {g} {w}kg {act} -> BMR={b}, TDEE={t}, FatLossTarget={goal_cals} (>= BMR))

    # Test 3: Macro Negative Carbohydrate Impossibility Defense
    # In extreme deficits or super heavy individuals, rem_cals could be negative.
    # Verify carbs is strictly clamped to >= 0.0
    extreme_cases = [
        (130.0, 1200.0, fat_loss),
        (150.0, 1400.0, fat_loss),
        (200.0, 1600.0, fat_loss),
    ]
    for w, cals, g in extreme_cases:
        p, c, f = macros(cals, w, g)
        assert c >= 0.0, fNegative carbs produced! Carbs = {c}
        assert p > 0.0 and f > 0.0
        print(f [PASS] Non-Negative Macro Defense: {w}kg at {cals}kcal -> P={p}g, F={f}g, C={c}g (C >= 0))

    # Test 4: Macro Percentage Caloric Consistency
    normal_sweeps = [
        (65.0, 1900.0, fat_loss),
        (70.0, 2100.0, maintenance),
        (75.0, 2500.0, muscle_gain),
        (82.0, 2300.0, fat_loss),
        (88.0, 3000.0, muscle_gain),
        (95.0, 2600.0, maintenance),
    ]
    for w, cals, g in normal_sweeps:
        p, c, f = macros(cals, w, g)
        total_macro_cals = (p * 4.0) + (f * 9.0) + (c * 4.0)
        diff = abs(total_macro_cals - cals)
        assert diff <= 3.0, fCaloric balance gap too high: {diff} kcal for {w}kg, {cals}kcal
        print(f [PASS] Caloric Reconciliation: {w}kg {g} ({cals}kcal) -> Macro sum = {total_macro_cals:.1f}kcal (diff: {diff:.1f}kcal))

    print(\n>>> ALL ADVERSARIAL STRESS TESTS COMPLETED SUCCESSFULLY <<<)

if __name__ == __main__:
    run_adversarial_suite()

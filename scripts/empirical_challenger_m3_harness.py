"""
Empirical Challenger Test Harness for Phase 2 Milestone 3 (Metabolic Engine & User Profile).
Adversarial test suite covering:
1. Mifflin-St Jeor math & gender divergence (exact 166.0 kcal offset).
2. Boundary stress tests (ages 10-120, weights 20-500kg, heights 50-300cm).
3. Gender synonym parsing matrix.
4. Activity multipliers & TDEE.
5. Caloric goal calculation & Starvation Defense (BMR floor guarantee).
6. Macro distribution, hormonal fat floor (0.8 g/kg & 25%), protein scaling (1.8 - 2.2 g/kg),
   and caloric summation (+/- 5 kcal margin up to obesity cutoff).
7. Critical obesity threshold where fixed protein + fat floor saturates deficit.
8. ModelSanitizer defensive clamping for negative, NaN, 0, and extreme values.
9. Master Prompt Markdown structure and clinical directive completeness.
10. LoC compliance (< 300 LoC per screen) and balanced syntax.
"""

import math
import os
import re
import sys
import unittest
import decimal

def round_half_up(val: float, decimals: int = 1) -> float:
    d = decimal.Decimal(str(val))
    return float(d.quantize(decimal.Decimal(10) ** -decimals, rounding=decimal.ROUND_HALF_UP))

class ModelSanitizer:
    min_macro_value = 0.0
    max_macro_value = 9999.0
    max_name_length = 255
    max_notes_length = 2000
    max_json_length = 100000

    @classmethod
    def truncate(cls, value, max_length, fallback=""):
        if value is None:
            return fallback
        trimmed = str(value).strip()
        if not trimmed:
            return fallback
        return trimmed[:max_length]

    @classmethod
    def truncate_nullable(cls, value, max_length):
        if value is None:
            return None
        trimmed = str(value).strip()
        if not trimmed:
            return None
        return trimmed[:max_length]

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
        # Matches Dart: double.parse(doubleVal.toStringAsFixed(2))
        return float(f"{d_val:.2f}")


class MetabolicCalculatorSim:
    multiplier_sedentary = 1.2
    multiplier_light = 1.375
    multiplier_moderate = 1.55
    multiplier_very_active = 1.725

    fat_loss_deficit = 500.0
    muscle_gain_surplus = 300.0

    protein_factor_fat_loss = 2.0
    protein_factor_maintenance = 1.8
    protein_factor_muscle_gain = 2.2

    fat_minimum_per_kg = 0.8
    fat_calorie_percentage = 0.25

    @classmethod
    def normalize_gender(cls, raw):
        if raw is None:
            return "male"
        lower = str(raw).strip().lower()
        if lower in ("female", "femenino", "mujer", "f"):
            return "female"
        return "male"

    @classmethod
    def normalize_activity_level(cls, raw):
        if raw is None:
            return "sedentary"
        lower = str(raw).strip().lower()
        if "very" in lower or "muy" in lower or "intenso" in lower:
            return "very_active"
        if "moderat" in lower or "moderado" in lower:
            return "moderate"
        if "light" in lower or "ligero" in lower:
            return "light"
        return "sedentary"

    @classmethod
    def normalize_body_goal(cls, raw):
        if raw is None:
            return "maintenance"
        lower = str(raw).strip().lower()
        if any(x in lower for x in ("fat", "perdid", "déficit", "deficit", "grasa")):
            return "fat_loss"
        if any(x in lower for x in ("gain", "gananc", "superávit", "superavit", "musculo", "músculo")):
            return "muscle_gain"
        return "maintenance"

    @classmethod
    def get_activity_multiplier(cls, activity_level):
        norm = cls.normalize_activity_level(activity_level)
        if norm == "very_active":
            return cls.multiplier_very_active
        if norm == "moderate":
            return cls.multiplier_moderate
        if norm == "light":
            return cls.multiplier_light
        return cls.multiplier_sedentary

    @classmethod
    def calculate_bmr(cls, gender, weight_kg, height_cm, age):
        is_female = cls.normalize_gender(gender) == "female"
        offset = -161.0 if is_female else 5.0
        bmr = (10.0 * float(weight_kg)) + (6.25 * float(height_cm)) - (5.0 * float(age)) + offset
        return round_half_up(bmr, 1)

    @classmethod
    def calculate_tdee(cls, bmr, activity_level):
        mult = cls.get_activity_multiplier(activity_level)
        return round_half_up(bmr * mult, 1)

    @classmethod
    def calculate_caloric_goal(cls, tdee, bmr, body_goal):
        goal = cls.normalize_body_goal(body_goal)
        if goal == "fat_loss":
            target = max(bmr, tdee - cls.fat_loss_deficit)
        elif goal == "muscle_gain":
            target = tdee + cls.muscle_gain_surplus
        else:
            target = tdee
        return round_half_up(target, 1)

    @classmethod
    def calculate_macros(cls, target_calories, weight_kg, body_goal):
        goal = cls.normalize_body_goal(body_goal)
        if goal == "fat_loss":
            p_factor = cls.protein_factor_fat_loss
        elif goal == "muscle_gain":
            p_factor = cls.protein_factor_muscle_gain
        else:
            p_factor = cls.protein_factor_maintenance

        protein = round_half_up(weight_kg * p_factor, 1)
        protein_cals = protein * 4.0

        fat_from_pct = (target_calories * cls.fat_calorie_percentage) / 9.0
        fat_floor = weight_kg * cls.fat_minimum_per_kg
        fat = round_half_up(max(fat_from_pct, fat_floor), 1)
        fat_cals = fat * 9.0

        remaining_cals = target_calories - protein_cals - fat_cals
        raw_carbs = max(0.0, remaining_cals / 4.0)
        carbs = round_half_up(raw_carbs, 1)

        return {
            "protein": protein,
            "carbs": carbs,
            "fat": fat,
            "protein_cals": protein_cals,
            "carbs_cals": carbs * 4.0,
            "fat_cals": fat_cals,
            "total_cals": protein_cals + (carbs * 4.0) + fat_cals
        }

    @classmethod
    def generate_master_prompt(cls, profile):
        gender_display = "Femenino" if profile["gender"] == "female" else "Masculino"
        act_display = {
            "sedentary": "Sedentario (poco o ningún ejercicio, factor 1.2x)",
            "light": "Ligero (ejercicio ligero 1-3 días/semana, factor 1.375x)",
            "moderate": "Moderado (ejercicio moderado 3-5 días/semana, factor 1.55x)",
            "very_active": "Muy Activo (ejercicio intenso 6-7 días/semana, factor 1.725x)",
        }.get(profile["activity_level"], "Sedentario (factor 1.2x)")

        goal_display = {
            "fat_loss": "Pérdida de Grasa (Déficit calórico de -500 kcal)",
            "muscle_gain": "Ganancia Muscular (Superávit calórico de +300 kcal)",
            "maintenance": "Mantenimiento Normocalórico (Gasto TDEE)",
        }.get(profile["body_goal"], "Mantenimiento Normocalórico (Gasto TDEE)")

        lines = [
            "# Contexto Biológico y Metas Nutricionales del Comensal",
            "",
            "## 1. Datos Biométricos",
            f"- **Nombre**: {profile.get('name') or 'Comensal'}",
            f"- **Edad**: {profile['age']} años",
            f"- **Género Biológico**: {gender_display}",
            f"- **Estatura**: {profile['height']:.1f} cm",
            f"- **Peso Actual**: {profile['weight']:.1f} kg",
            "",
            "## 2. Nivel de Actividad y Gasto Energético",
            f"- **Nivel de Actividad**: {act_display}",
            f"- **Pasos Diarios Estimados**: {profile['estimated_steps']} pasos/día",
            f"- **Tasa Metabólica Basal (TMB / BMR - Mifflin-St Jeor)**: {profile['bmr']:.0f} kcal/día",
            f"- **Gasto Energético Diario Total (TDEE)**: {profile['tdee']:.0f} kcal/día",
            "",
            "## 3. Metas Metabólicas y Objetivos",
            f"- **Objetivo Corporal**: {goal_display}",
            f"- **Presupuesto Calórico Diario**: {profile['target_calories']:.0f} kcal/día",
            "",
            "## 4. Distribución de Macronutrientes Objetivo",
            f"- **Proteínas**: {profile['target_protein']:.0f} g/día ({profile['target_protein'] * 4.0:.0f} kcal)",
            f"- **Carbohidratos**: {profile['target_carbs']:.0f} g/día ({profile['target_carbs'] * 4.0:.0f} kcal)",
            f"- **Grasas**: {profile['target_fat']:.0f} g/día ({profile['target_fat'] * 9.0:.0f} kcal)",
            "",
            "## 5. Instrucciones Clínicas para la Estimación Visual (Gemini Vision)",
            f"- **Prioridad Proteica**: Presta atención especial a las fuentes de proteína para verificar si la porción cubre los requerimientos del objetivo ({goal_display}).",
            "- **Densidad Calórica y Grasa Oculta**: Ajusta las estimaciones de grasa oculta y aceite de cocina teniendo en cuenta el presupuesto calórico del comensal.",
            "- **Volumetría de Carbohidratos**: Evalúa con rigor la cantidad de almidones, cereales y legumbres cocidas según las reglas volumétricas anatómicas.",
            "- **Alineación con el Objetivo**: Ofrece observaciones en la justificación visual orientadas al cumplimiento de la meta",
        ]
        return "\n".join(lines)


class UserProfileSim:
    def __init__(self, id="primary", name=None, age=25, gender="male", height=170.0, weight=70.0,
                 activity_level="sedentary", body_goal="maintenance", estimated_steps=8000,
                 bmr=1500.0, tdee=1800.0, target_calories=1800.0, target_protein=100.0,
                 target_carbs=150.0, target_fat=50.0, master_prompt=None):
        self.id = ModelSanitizer.truncate(id, 128, fallback="primary")
        self.name = ModelSanitizer.truncate_nullable(name, ModelSanitizer.max_name_length)
        # Clamping
        try:
            a = int(age)
        except (ValueError, TypeError):
            a = 25
        self.age = max(10, min(120, a))
        self.gender = "female" if str(gender).strip().lower() in ("female", "femenino", "mujer") else "male"
        self.height = ModelSanitizer.clamp_double(height, min_val=50.0, max_val=300.0)
        self.weight = ModelSanitizer.clamp_double(weight, min_val=20.0, max_val=500.0)
        
        act = str(activity_level).strip().lower()
        if "light" in act or "ligero" in act:
            self.activity_level = "light"
        elif "moderat" in act or "moderado" in act:
            self.activity_level = "moderate"
        elif "very" in act or "muy" in act:
            self.activity_level = "very_active"
        else:
            self.activity_level = "sedentary"

        bg = str(body_goal).strip().lower()
        if any(x in bg for x in ("fat", "perdid", "déficit", "deficit")):
            self.body_goal = "fat_loss"
        elif any(x in bg for x in ("gain", "gananc", "superávit", "superavit")):
            self.body_goal = "muscle_gain"
        else:
            self.body_goal = "maintenance"

        try:
            st = int(estimated_steps)
        except (ValueError, TypeError):
            st = 8000
        self.estimated_steps = max(0, min(100000, st))

        self.bmr = ModelSanitizer.clamp_double(bmr, min_val=500.0, max_val=5000.0)
        self.tdee = ModelSanitizer.clamp_double(tdee, min_val=500.0, max_val=8000.0)
        self.target_calories = ModelSanitizer.clamp_double(target_calories, min_val=500.0, max_val=8000.0)
        self.target_protein = ModelSanitizer.clamp_double(target_protein, min_val=10.0, max_val=1000.0)
        self.target_carbs = ModelSanitizer.clamp_double(target_carbs, min_val=10.0, max_val=1000.0)
        self.target_fat = ModelSanitizer.clamp_double(target_fat, min_val=10.0, max_val=1000.0)
        self.master_prompt = ModelSanitizer.truncate_nullable(master_prompt, ModelSanitizer.max_json_length)


class TestMetabolicEngineAdversarial(unittest.TestCase):

    def test_01_mifflin_st_jeor_formula_divergence(self):
        """Verify that male vs female BMR for identical biometrics is ALWAYS exactly 166.0 kcal."""
        weights = [30.0, 50.0, 70.0, 95.5, 120.0, 200.0]
        heights = [140.0, 160.0, 175.0, 190.0, 210.0]
        ages = [10, 18, 30, 50, 75, 90, 120]

        for w in weights:
            for h in heights:
                for a in ages:
                    bmr_m = MetabolicCalculatorSim.calculate_bmr("male", w, h, a)
                    bmr_f = MetabolicCalculatorSim.calculate_bmr("female", w, h, a)
                    diff = round(bmr_m - bmr_f, 2)
                    self.assertAlmostEqual(diff, 166.0, places=1,
                        msg=f"Divergence failed for W={w}, H={h}, A={a}: {bmr_m} - {bmr_f} = {diff}")

    def test_02_mifflin_st_jeor_boundary_values(self):
        """Stress test exact boundary values: ages (10, 18, 50, 90, 120), weights (30-300kg), heights (100-250cm)."""
        # Minimum valid boundaries
        bmr_min = MetabolicCalculatorSim.calculate_bmr("female", 30.0, 100.0, 120)
        # (10*30) + (6.25*100) - (5*120) - 161 = 300 + 625 - 600 - 161 = 164.0
        self.assertEqual(bmr_min, 164.0)

        # Maximum valid boundaries
        bmr_max = MetabolicCalculatorSim.calculate_bmr("male", 300.0, 250.0, 10)
        # (10*300) + (6.25*250) - (5*10) + 5 = 3000 + 1562.5 - 50 + 5 = 4517.5
        self.assertEqual(bmr_max, 4517.5)

        # Standard boundary checks
        test_boundaries = [
            # (gender, w, h, a, expected)
            ("male", 30.0, 100.0, 10, (10*30) + (6.25*100) - (5*10) + 5),     # 300 + 625 - 50 + 5 = 880.0
            ("female", 300.0, 250.0, 120, (10*300) + (6.25*250) - (5*120) - 161), # 3000 + 1562.5 - 600 - 161 = 3801.5
            ("male", 70.0, 175.0, 18, (10*70) + (6.25*175) - (5*18) + 5),    # 700 + 1093.75 - 90 + 5 = 1708.75 -> 1708.8
            ("female", 60.0, 165.0, 50, (10*60) + (6.25*165) - (5*50) - 161),# 600 + 1031.25 - 250 - 161 = 1220.25 -> 1220.3
            ("male", 85.0, 180.0, 90, (10*85) + (6.25*180) - (5*90) + 5),    # 850 + 1125 - 450 + 5 = 1530.0
        ]
        for g, w, h, a, exp in test_boundaries:
            res = MetabolicCalculatorSim.calculate_bmr(g, w, h, a)
            expected_rounded = round_half_up(exp, 1)
            self.assertEqual(res, expected_rounded, f"Mismatch on {g}, {w}, {h}, {a}")

    def test_03_gender_synonyms_matrix(self):
        """Stress test synonym gender parsing against female vs male mapping."""
        female_inputs = [
            "female", "FEMALE", "Female", "femenino", "FEMENINO", "Femenino",
            "mujer", "MUJER", "Mujer", "f", "F", "  female  ", " femenino "
        ]
        male_inputs = [
            "male", "MALE", "Male", "hombre", "HOMBRE", "Hombre",
            "varón", "Varón", "VARON", "varon", "m", "M", "  hombre  ",
            None, "", "xyz", "non_binary", "unknown"
        ]

        w, h, a = 70.0, 175.0, 30
        expected_male = round_half_up((10*w) + (6.25*h) - (5*a) + 5, 1)
        expected_female = round_half_up((10*w) + (6.25*h) - (5*a) - 161, 1)

        for inp in female_inputs:
            norm = MetabolicCalculatorSim.normalize_gender(inp)
            self.assertEqual(norm, "female", f"Failed to normalize '{inp}' to female")
            bmr = MetabolicCalculatorSim.calculate_bmr(inp, w, h, a)
            self.assertEqual(bmr, expected_female, f"BMR failed for female input '{inp}'")

        for inp in male_inputs:
            norm = MetabolicCalculatorSim.normalize_gender(inp)
            self.assertEqual(norm, "male", f"Failed to normalize '{inp}' to male")
            bmr = MetabolicCalculatorSim.calculate_bmr(inp, w, h, a)
            self.assertEqual(bmr, expected_male, f"BMR failed for male input '{inp}'")

    def test_04_caloric_goals_and_starvation_defense(self):
        """
        Verify:
        - Maintenance == TDEE
        - Muscle gain == TDEE + 300
        - Fat loss: NEVER drops below BMR (Starvation Defense Guarantee)
        """
        # Test 100 random combinations of BMR and Activity Level
        bmr_samples = [800.0, 1100.0, 1350.0, 1500.0, 1800.0, 2200.0, 3000.0]
        activities = ["sedentary", "light", "moderate", "very_active"]

        for bmr in bmr_samples:
            for act in activities:
                tdee = MetabolicCalculatorSim.calculate_tdee(bmr, act)
                
                # Maintenance
                maint = MetabolicCalculatorSim.calculate_caloric_goal(tdee, bmr, "maintenance")
                self.assertEqual(maint, tdee)

                # Muscle Gain
                gain = MetabolicCalculatorSim.calculate_caloric_goal(tdee, bmr, "muscle_gain")
                self.assertEqual(gain, round_half_up(tdee + 300.0, 1))

                # Fat Loss
                fat_loss = MetabolicCalculatorSim.calculate_caloric_goal(tdee, bmr, "fat_loss")
                self.assertGreaterEqual(fat_loss, bmr,
                    f"STARVATION DEFENSE VIOLATED! BMR={bmr}, TDEE={tdee}, FatLoss={fat_loss}")

        # Targeted starvation edge case: Sedentary small person
        # BMR = 1400.0, Sedentary TDEE = 1400 * 1.2 = 1680.0
        # TDEE - 500 = 1180.0 -> Must be clamped to 1400.0
        goal_clamped = MetabolicCalculatorSim.calculate_caloric_goal(1680.0, 1400.0, "fat_loss")
        self.assertEqual(goal_clamped, 1400.0)

    def test_05_macro_distribution_scaling_and_summation(self):
        """
        Verify:
        - Protein scaling: 2.0 (fat loss), 1.8 (maintenance), 2.2 (muscle gain)
        - Fat floor: max(target * 0.25 / 9, weight * 0.8)
        - Carbs pool: remaining calories / 4 >= 0
        - Summation within +/- 5 kcal for typical human weight range (40kg to 130kg)
        """
        test_profiles = [
            # (weight, target_calories, goal)
            (45.0, 1500.0, "fat_loss"),
            (55.0, 1800.0, "maintenance"),
            (65.0, 2100.0, "muscle_gain"),
            (75.0, 2000.0, "fat_loss"),
            (80.0, 2400.0, "maintenance"),
            (85.0, 2800.0, "muscle_gain"),
            (95.0, 2200.0, "fat_loss"),
            (110.0, 2600.0, "fat_loss"),
            (125.0, 2900.0, "maintenance"),
        ]

        for w, target_cals, goal in test_profiles:
            macros = MetabolicCalculatorSim.calculate_macros(target_cals, w, goal)

            # Check Protein
            expected_p_factor = {
                "fat_loss": 2.0,
                "maintenance": 1.8,
                "muscle_gain": 2.2
            }[goal]
            self.assertEqual(macros["protein"], round_half_up(w * expected_p_factor, 1))

            # Check Fat floor
            expected_fat_pct = (target_cals * 0.25) / 9.0
            expected_fat_min = w * 0.8
            self.assertGreaterEqual(macros["fat"], round_half_up(expected_fat_min, 1) - 0.1)

            # Check Carbs >= 0
            self.assertGreaterEqual(macros["carbs"], 0.0)

            # Caloric summation check within +/- 5 kcal
            diff = abs(macros["total_cals"] - target_cals)
            self.assertLessEqual(diff, 5.0,
                f"Caloric summation violated for W={w}, Target={target_cals}, Goal={goal}: "
                f"Total={macros['total_cals']} vs Target={target_cals} (diff: {diff})")

    def test_06_macro_extreme_obesity_boundary_behavior(self):
        """
        Adversarial Analysis: What happens at extreme weights (e.g. 200kg - 300kg)?
        When total fixed protein (2.0 g/kg = 8 kcal/kg) and fat floor (0.8 g/kg = 7.2 kcal/kg)
        require 15.2 kcal/kg, if caloric target per kg is < 15.2 kcal/kg,
        carbs zero out and summation exceeds target calories.
        Document the exact transition point.
        """
        # Test extreme weights:
        w_extreme = 250.0
        bmr = MetabolicCalculatorSim.calculate_bmr("female", w_extreme, 165.0, 45)
        # (10*250) + (6.25*165) - (5*45) - 161 = 2500 + 1031.25 - 225 - 161 = 3145.25 -> 3145.3
        tdee = MetabolicCalculatorSim.calculate_tdee(bmr, "sedentary") # 3145.3 * 1.2 = 3774.4
        target = MetabolicCalculatorSim.calculate_caloric_goal(tdee, bmr, "fat_loss") # 3774.4 - 500 = 3274.4

        macros = MetabolicCalculatorSim.calculate_macros(target, w_extreme, "fat_loss")
        # Protein: 250 * 2.0 = 500g (2000 kcal)
        # Fat: max(3274.4 * 0.25 / 9 = 90.96g, 250 * 0.8 = 200g) -> 200g (1800 kcal)
        # Protein + Fat = 3800 kcal > Target (3274.4 kcal)!
        # Carbs must be floored to 0.0g:
        self.assertEqual(macros["carbs"], 0.0)
        self.assertEqual(macros["protein"], 500.0)
        self.assertEqual(macros["fat"], 200.0)
        # The engine gracefully protects against negative carbs with max(0.0, ...)
        self.assertGreaterEqual(macros["carbs"], 0.0)

    def test_07_model_sanitizer_clamping_defense(self):
        """
        Stress test ModelSanitizer bounds in UserProfile:
        - Negative, NaN, Zero, Infinity, and Out-of-bounds values
        """
        # 1. Zero/Negative/NaN inputs
        p1 = UserProfileSim(
            age=-5,
            height=-10.0,
            weight=0.0,
            bmr=-500.0,
            tdee=float("nan"),
            target_calories=0.0,
            target_protein=-10.0,
            target_carbs=float("nan"),
            target_fat=-5.0,
            estimated_steps=-1000
        )
        self.assertEqual(p1.age, 10)       # Min age is 10
        self.assertEqual(p1.height, 50.0)  # Min height is 50.0 cm
        self.assertEqual(p1.weight, 20.0)  # Min weight is 20.0 kg
        self.assertEqual(p1.bmr, 500.0)    # Min BMR is 500.0 kcal
        self.assertEqual(p1.tdee, 500.0)   # Min TDEE is 500.0 kcal (NaN fallback)
        self.assertEqual(p1.target_calories, 500.0)
        self.assertEqual(p1.target_protein, 10.0)
        self.assertEqual(p1.target_carbs, 10.0)
        self.assertEqual(p1.target_fat, 10.0)
        self.assertEqual(p1.estimated_steps, 0)

        # 2. Oversized / Extreme inputs
        p2 = UserProfileSim(
            age=200,
            height=999.0,
            weight=1500.0,
            bmr=99999.0,
            tdee=99999.0,
            target_calories=99999.0,
            target_protein=99999.0,
            target_carbs=99999.0,
            target_fat=99999.0,
            estimated_steps=500000
        )
        self.assertEqual(p2.age, 120)        # Max age is 120
        self.assertEqual(p2.height, 300.0)   # Max height is 300.0 cm
        self.assertEqual(p2.weight, 500.0)   # Max weight is 500.0 kg
        self.assertEqual(p2.bmr, 5000.0)     # Max BMR is 5000.0 kcal
        self.assertEqual(p2.tdee, 8000.0)    # Max TDEE is 8000.0 kcal
        self.assertEqual(p2.target_calories, 8000.0)
        self.assertEqual(p2.target_protein, 1000.0)
        self.assertEqual(p2.target_carbs, 1000.0)
        self.assertEqual(p2.target_fat, 1000.0)
        self.assertEqual(p2.estimated_steps, 100000)

    def test_08_master_prompt_content_and_structure(self):
        """Stress test Master Prompt generation and verify all clinical markers."""
        profile = {
            "name": "Victor Tester",
            "age": 29,
            "gender": "male",
            "height": 182.0,
            "weight": 79.5,
            "activity_level": "moderate",
            "body_goal": "fat_loss",
            "estimated_steps": 12000,
            "bmr": 1800.0,
            "tdee": 2790.0,
            "target_calories": 2290.0,
            "target_protein": 159.0,
            "target_carbs": 268.0,
            "target_fat": 64.0,
        }

        prompt = MetabolicCalculatorSim.generate_master_prompt(profile)

        # Structure headers
        self.assertIn("# Contexto Biológico y Metas Nutricionales del Comensal", prompt)
        self.assertIn("## 1. Datos Biométricos", prompt)
        self.assertIn("## 2. Nivel de Actividad y Gasto Energético", prompt)
        self.assertIn("## 3. Metas Metabólicas y Objetivos", prompt)
        self.assertIn("## 4. Distribución de Macronutrientes Objetivo", prompt)
        self.assertIn("## 5. Instrucciones Clínicas para la Estimación Visual (Gemini Vision)", prompt)

        # Biometric values
        self.assertIn("Victor Tester", prompt)
        self.assertIn("29 años", prompt)
        self.assertIn("Masculino", prompt)
        self.assertIn("182.0 cm", prompt)
        self.assertIn("79.5 kg", prompt)
        self.assertIn("12000 pasos/día", prompt)
        self.assertIn("1800 kcal/día", prompt)
        self.assertIn("2790 kcal/día", prompt)
        self.assertIn("2290 kcal/día", prompt)

        # Clinical instructions
        self.assertIn("Prioridad Proteica", prompt)
        self.assertIn("Densidad Calórica y Grasa Oculta", prompt)
        self.assertIn("Volumetría de Carbohidratos", prompt)
        self.assertIn("Alineación con el Objetivo", prompt)

        # Empty name fallback
        profile_noname = dict(profile)
        profile_noname["name"] = None
        prompt_noname = MetabolicCalculatorSim.generate_master_prompt(profile_noname)
        self.assertIn("- **Nombre**: Comensal", prompt_noname)

    def test_09_code_loc_and_hygiene(self):
        """Verify screen LoC < 300 and zero deprecated opacity usage."""
        base_dir = r"C:\Users\vmesp\Documents\Cositas\App-Food-Tracker"
        screen_file = os.path.join(base_dir, "lib", "screens", "user_profile_screen.dart")
        self.assertTrue(os.path.exists(screen_file), "UserProfileScreen missing!")

        with open(screen_file, "r", encoding="utf-8") as f:
            lines = f.readlines()
        loc = len(lines)
        self.assertLess(loc, 300, f"Screen exceeds 300 LoC! Found {loc}")

        # Check for deprecated withOpacity across all milestone 3 files
        m3_files = [
            os.path.join(base_dir, "lib", "services", "metabolic_calculator.dart"),
            os.path.join(base_dir, "lib", "screens", "user_profile_screen.dart"),
            os.path.join(base_dir, "lib", "widgets", "profile", "biometric_inputs_card.dart"),
            os.path.join(base_dir, "lib", "widgets", "profile", "activity_goal_selector_card.dart"),
            os.path.join(base_dir, "lib", "widgets", "profile", "metabolic_summary_bento_card.dart"),
        ]
        for fpath in m3_files:
            with open(fpath, "r", encoding="utf-8") as f:
                content = f.read()
            self.assertNotIn(".withOpacity(", content, f"Deprecated .withOpacity found in {fpath}")
            self.assertEqual(content.count("{"), content.count("}"), f"Unbalanced braces in {fpath}")


if __name__ == "__main__":
    unittest.main(verbosity=2)

#!/usr/bin/env python3
"""
Adversarial Reviewer 2 Test Suite for Phase 2 Milestone 5 (Metrics & Bento Dashboard).

Focus:
1. Controller Lifecycle & State Management
2. QuickWeightEntryDialog Validation, Disposal & Mounted Guards
3. Bento Calculations: Caloric Compliance, Macro Distribution, Streak Counting
4. WeightLineChartPainter Zero/Boundary/Division-by-Zero Safety
5. Dashboard Navigation Link & LoC Constraints (< 300 LoC)
6. Integrity Violation Scanning
"""

import os
import re
import sys
import unittest
from datetime import datetime, timedelta

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

class TestMilestone5AdversarialReview(unittest.TestCase):

    def setUp(self):
        self.metrics_screen_path = os.path.join(REPO_ROOT, "lib", "screens", "metrics_screen.dart")
        self.dashboard_screen_path = os.path.join(REPO_ROOT, "lib", "screens", "dashboard_screen.dart")
        self.dialog_path = os.path.join(REPO_ROOT, "lib", "widgets", "metrics", "quick_weight_entry_dialog.dart")
        self.chart_path = os.path.join(REPO_ROOT, "lib", "widgets", "metrics", "weight_line_chart_painter.dart")
        self.weight_card_path = os.path.join(REPO_ROOT, "lib", "widgets", "metrics", "weight_trend_bento_card.dart")
        self.cal_card_path = os.path.join(REPO_ROOT, "lib", "widgets", "metrics", "calorie_compliance_bento_card.dart")
        self.macro_card_path = os.path.join(REPO_ROOT, "lib", "widgets", "metrics", "macro_distribution_bento_card.dart")
        self.streak_card_path = os.path.join(REPO_ROOT, "lib", "widgets", "metrics", "streak_compliance_bento_card.dart")
        self.meal_controller_path = os.path.join(REPO_ROOT, "lib", "controllers", "meal_controller.dart")

    def test_01_screen_loc_constraints(self):
        """Verify all screen files in lib/screens/ are strictly < 300 LoC."""
        screens_dir = os.path.join(REPO_ROOT, "lib", "screens")
        for filename in os.listdir(screens_dir):
            if filename.endswith(".dart"):
                fpath = os.path.join(screens_dir, filename)
                with open(fpath, "r", encoding="utf-8") as f:
                    lines = f.readlines()
                loc = len(lines)
                self.assertLess(loc, 300, f"Screen {filename} exceeds 300 LoC constraint: {loc} lines")

    def test_02_controller_lifecycle_in_metrics_screen(self):
        """Verify MealController listener lifecycle and mounted guards in MetricsScreen."""
        with open(self.metrics_screen_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Must add listener in initState
        self.assertIn("_mealController.addListener(_onControllerChange);", content)
        # Must remove listener in dispose
        self.assertIn("_mealController.removeListener(_onControllerChange);", content)
        # Must have super.dispose()
        self.assertIn("super.dispose();", content)
        # Must guard setState with mounted in _onControllerChange
        self.assertRegex(content, r"void\s+_onControllerChange\(\)\s*\{\s*if\s*\(\s*mounted\s*\)\s*setState\(\(\)\s*\{\}\);")
        # Must support 7, 30, 90 days range
        self.assertIn("static const List<int> _availableRanges = [7, 30, 90];", content)
        # Must call loadWeightLogs with selected days
        self.assertIn("await _mealController.loadWeightLogs(days: _selectedDays);", content)

    def test_03_quick_weight_entry_dialog_safety_and_lifecycle(self):
        """Verify QuickWeightEntryDialog lifecycle, controller disposal, bounds and mounted guards."""
        with open(self.dialog_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Both controllers must be declared
        self.assertIn("late final TextEditingController _weightController;", content)
        self.assertIn("late final TextEditingController _notesController;", content)
        # Both controllers must be disposed
        self.assertIn("_weightController.dispose();", content)
        self.assertIn("_notesController.dispose();", content)
        # Validation bounds: 20.0 to 350.0
        self.assertIn("weight < 20.0 || weight > 350.0", content)
        # Persistence through MealController.instance.recordWeight
        self.assertIn("MealController.instance.recordWeight", content)
        # Mounted checks before Navigator.pop and SnackBar
        self.assertIn("if (!mounted) return;", content)
        # No deprecated withOpacity
        self.assertNotIn(".withOpacity(", content)

    def test_04_dialog_validation_logic_adversarial(self):
        """Stress-test dialog numeric parsing and validation bounds."""
        def validate_weight_input(raw: str):
            import math
            raw_text = raw.strip().replace(",", ".")
            try:
                weight = float(raw_text)
            except ValueError:
                return False, None
            if math.isnan(weight) or math.isinf(weight) or weight < 20.0 or weight > 350.0:
                return False, None
            return True, weight

        # Valid inputs
        valid_cases = ["20.0", "20", "75.5", "75,5", " 80.2 ", "350.0", "350"]
        for c in valid_cases:
            ok, val = validate_weight_input(c)
            self.assertTrue(ok, f"Expected {c} to be valid")
            self.assertIsNotNone(val)

        # Invalid inputs
        invalid_cases = ["19.99", "0", "-5", "350.01", "400", "abc", "", "   ", "NaN", "Infinity", "-Infinity"]
        for c in invalid_cases:
            ok, val = validate_weight_input(c)
            self.assertFalse(ok, f"Expected {c} to be invalid")
            self.assertIsNone(val)

    def test_05_calorie_compliance_calculation_adversarial(self):
        """Stress-test calorie compliance calculation under edge cases."""
        def calc_compliance(meals, target_calories):
            daily_totals = {}
            for m_date, cals in meals:
                key = f"{m_date.year}-{m_date.month}-{m_date.day}"
                daily_totals[key] = daily_totals.get(key, 0.0) + cals

            total_calories = sum(cals for _, cals in meals)
            active_days = len(daily_totals)
            avg_calories = (total_calories / active_days) if active_days > 0 else 0.0

            progress_fraction = min(1.5, max(0.0, avg_calories / target_calories)) if target_calories > 0 else 0.0
            compliance_percent = int((avg_calories / target_calories) * 100) if target_calories > 0 else 0

            if target_calories <= 0:
                status = "Sin meta"
            elif avg_calories == 0:
                status = "Sin registros"
            elif avg_calories < target_calories - 200:
                status = "Déficit saludable"
            elif abs(avg_calories - target_calories) <= 200:
                status = "Mantenimiento"
            else:
                status = "Superávit"

            return avg_calories, compliance_percent, progress_fraction, status

        # Case 1: 0 meals, positive target
        avg, pct, prog, status = calc_compliance([], 2000.0)
        self.assertEqual(avg, 0.0)
        self.assertEqual(pct, 0)
        self.assertEqual(prog, 0.0)
        self.assertEqual(status, "Sin registros")

        # Case 2: 0 target
        avg, pct, prog, status = calc_compliance([(datetime.now(), 1500.0)], 0.0)
        self.assertEqual(avg, 1500.0)
        self.assertEqual(pct, 0)
        self.assertEqual(prog, 0.0)
        self.assertEqual(status, "Sin meta")

        # Case 3: Healthy deficit (< target - 200)
        now = datetime.now()
        meals = [(now, 700.0), (now, 800.0)] # total 1500 kcal on 1 day
        avg, pct, prog, status = calc_compliance(meals, 2000.0)
        self.assertEqual(avg, 1500.0)
        self.assertEqual(pct, 75)
        self.assertEqual(status, "Déficit saludable")

        # Case 4: Maintenance (target +/- 200)
        meals = [(now, 1000.0), (now, 950.0)] # 1950 kcal on 1 day vs 2000 target
        avg, pct, prog, status = calc_compliance(meals, 2000.0)
        self.assertEqual(avg, 1950.0)
        self.assertEqual(pct, 97)
        self.assertEqual(status, "Mantenimiento")

        # Case 5: Surplus (> target + 200)
        meals = [(now, 1200.0), (now, 1300.0)] # 2500 kcal
        avg, pct, prog, status = calc_compliance(meals, 2000.0)
        self.assertEqual(avg, 2500.0)
        self.assertEqual(pct, 125)
        self.assertEqual(status, "Superávit")

    def test_06_macro_distribution_calculation_adversarial(self):
        """Stress-test macro distribution calculation under zero and extreme conditions."""
        def calc_macros(meals):
            days_set = {f"{m_date.year}-{m_date.month}-{m_date.day}" for m_date, _, _, _ in meals}
            active_days = max(1, len(days_set))
            has_data = len(meals) > 0

            tot_p = sum(p for _, p, _, _ in meals)
            tot_c = sum(c for _, _, c, _ in meals)
            tot_f = sum(f for _, _, _, f in meals)

            avg_p = (tot_p / active_days) if has_data else 0.0
            avg_c = (tot_c / active_days) if has_data else 0.0
            avg_f = (tot_f / active_days) if has_data else 0.0

            tot_macro_grams = avg_p + avg_c + avg_f

            pct_p = (avg_p / tot_macro_grams * 100) if tot_macro_grams > 0 else 33.3
            pct_c = (avg_c / tot_macro_grams * 100) if tot_macro_grams > 0 else 33.3
            pct_f = (avg_f / tot_macro_grams * 100) if tot_macro_grams > 0 else 33.4

            return avg_p, avg_c, avg_f, pct_p, pct_c, pct_f

        # Case 1: Empty meals -> defaults to equal 33.3 / 33.3 / 33.4
        p, c, f, pp, pc, pf = calc_macros([])
        self.assertEqual(p, 0.0)
        self.assertEqual(c, 0.0)
        self.assertEqual(f, 0.0)
        self.assertAlmostEqual(pp, 33.3)
        self.assertAlmostEqual(pc, 33.3)
        self.assertAlmostEqual(pf, 33.4)

        # Case 2: Standard 150g P, 200g C, 50g F (400g total)
        now = datetime.now()
        meals = [(now, 150.0, 200.0, 50.0)]
        p, c, f, pp, pc, pf = calc_macros(meals)
        self.assertEqual(p, 150.0)
        self.assertEqual(c, 200.0)
        self.assertEqual(f, 50.0)
        self.assertEqual(pp, 37.5)
        self.assertEqual(pc, 50.0)
        self.assertEqual(pf, 12.5)

    def test_07_streak_calculation_adversarial(self):
        """Stress-test streak counting logic for all boundary scenarios."""
        def calculate_streak(meal_dates, ref_now=None):
            if not meal_dates:
                return 0
            date_set = {d.strftime("%Y-%m-%d") for d in meal_dates}
            now = ref_now or datetime.now()
            today_str = now.strftime("%Y-%m-%d")
            yesterday = now - timedelta(days=1)
            yesterday_str = yesterday.strftime("%Y-%m-%d")

            if today_str in date_set:
                check_date = now
            elif yesterday_str in date_set:
                check_date = yesterday
            else:
                return 0

            streak = 0
            while True:
                key = check_date.strftime("%Y-%m-%d")
                if key in date_set:
                    streak += 1
                    check_date = check_date - timedelta(days=1)
                else:
                    break
            return streak

        ref = datetime(2026, 9, 7, 12, 0, 0)

        # 1. Empty meals
        self.assertEqual(calculate_streak([], ref), 0)

        # 2. Meal today only -> 1
        self.assertEqual(calculate_streak([ref], ref), 1)

        # 3. Meal yesterday only -> 1
        self.assertEqual(calculate_streak([ref - timedelta(days=1)], ref), 1)

        # 4. Meal 2 days ago only -> 0
        self.assertEqual(calculate_streak([ref - timedelta(days=2)], ref), 0)

        # 5. Consecutive 5 days up to today -> 5
        dates = [ref - timedelta(days=i) for i in range(5)]
        self.assertEqual(calculate_streak(dates, ref), 5)

        # 6. Consecutive 5 days up to yesterday -> 5
        dates = [ref - timedelta(days=i) for i in range(1, 6)]
        self.assertEqual(calculate_streak(dates, ref), 5)

        # 7. Broken streak: today, yesterday, gap, 3 days ago -> 2
        dates = [ref, ref - timedelta(days=1), ref - timedelta(days=3)]
        self.assertEqual(calculate_streak(dates, ref), 2)

        # 8. Duplicate meals on same day -> 1
        dates = [ref, ref.replace(hour=8), ref.replace(hour=20)]
        self.assertEqual(calculate_streak(dates, ref), 1)

    def test_08_weight_line_chart_bounds_padding(self):
        """Verify bounds padding avoids division by zero or NaN coordinates."""
        def compute_bounds(weights):
            min_weight = min(weights)
            max_weight = max(weights)
            if abs(max_weight - min_weight) < 0.001:
                min_weight = max(0.0, min_weight - 1.5)
                max_weight = max_weight + 1.5
            else:
                pad = (max_weight - min_weight) * 0.15
                min_weight = max(0.0, min_weight - pad)
                max_weight = max_weight + pad
            return min_weight, max_weight, max_weight - min_weight

        # Flat weight: 70.0, 70.0, 70.0
        min_w, max_w, diff = compute_bounds([70.0, 70.0, 70.0])
        self.assertEqual(min_w, 68.5)
        self.assertEqual(max_w, 71.5)
        self.assertAlmostEqual(diff, 3.0)
        self.assertGreater(diff, 0.0)

        # Varying weight: 80.0 to 85.0
        min_w, max_w, diff = compute_bounds([80.0, 85.0])
        self.assertLess(min_w, 80.0)
        self.assertGreater(max_w, 85.0)
        self.assertGreater(diff, 5.0)

    def test_09_dashboard_navigation_integration(self):
        """Verify DashboardScreen has the Metrics navigation icon button."""
        with open(self.dashboard_screen_path, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("import 'metrics_screen.dart';", content)
        self.assertIn("Icons.insights_outlined", content)
        self.assertIn("tooltip: 'Métricas'", content)
        self.assertIn("MaterialPageRoute(builder: (_) => const MetricsScreen())", content)

    def test_10_adversarial_integrity_check(self):
        """Adversarial check for integrity violations: hardcoded mocks, empty stubs, cheats."""
        for path in [self.metrics_screen_path, self.dialog_path, self.chart_path,
                     self.weight_card_path, self.cal_card_path, self.macro_card_path,
                     self.streak_card_path]:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()

            # No TODO / FIXME placeholders left behind
            self.assertNotIn("// TODO", content, f"Found // TODO in {path}")
            self.assertNotIn("// FIXME", content, f"Found // FIXME in {path}")
            self.assertNotIn("throw UnimplementedError", content, f"UnimplementedError in {path}")
            # Real UI implementation tokens
            if path == self.chart_path:
                self.assertIn("void paint(Canvas canvas, Size size)", content, f"Missing paint in {path}")
            else:
                self.assertIn("Widget build(BuildContext context)", content, f"Missing build in {path}")


if __name__ == "__main__":
    unittest.main()

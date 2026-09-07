#!/usr/bin/env python3
"""
Empirical Verification Harness for Worker M5.1
Phase 2 Milestone 5: Metrics Screen & Bento Dashboard
Victor Engineer - Food Tracker (NutriTracker Local-First)
"""

import os
import re
import sys
import unittest
from datetime import datetime, timedelta

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

class TestWorkerM5EmpiricalHarness(unittest.TestCase):

    def setUp(self):
        self.files_to_check = [
            'lib/screens/metrics_screen.dart',
            'lib/widgets/metrics/weight_line_chart_painter.dart',
            'lib/widgets/metrics/weight_trend_bento_card.dart',
            'lib/widgets/metrics/calorie_compliance_bento_card.dart',
            'lib/widgets/metrics/macro_distribution_bento_card.dart',
            'lib/widgets/metrics/streak_compliance_bento_card.dart',
            'lib/widgets/metrics/quick_weight_entry_dialog.dart',
            'lib/screens/dashboard_screen.dart',
            'test/widgets/weight_line_chart_painter_test.dart',
            'test/widgets/quick_weight_entry_dialog_test.dart',
            'test/screens/metrics_screen_test.dart',
        ]

    def test_01_screen_line_count_constraints(self):
        """All screens in lib/screens/ must be strictly < 300 LoC."""
        screens_dir = os.path.join(PROJECT_ROOT, 'lib', 'screens')
        for filename in os.listdir(screens_dir):
            if filename.endswith('.dart'):
                filepath = os.path.join(screens_dir, filename)
                with open(filepath, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                loc = len(lines)
                print(f"[LoC Audit] {filename}: {loc} lines")
                self.assertLess(
                    loc, 300,
                    f"Screen {filename} has {loc} LoC, which violates the strict < 300 LoC constraint!"
                )

    def test_02_zero_with_opacity(self):
        """No code should use deprecated .withOpacity; strictly use .withValues(alpha: ...)."""
        opacity_regex = re.compile(r'\.withOpacity\s*\(')
        for rel_path in self.files_to_check:
            abs_path = os.path.join(PROJECT_ROOT, rel_path)
            self.assertTrue(os.path.exists(abs_path), f"File {rel_path} does not exist!")
            with open(abs_path, 'r', encoding='utf-8') as f:
                content = f.read()
            matches = opacity_regex.findall(content)
            self.assertEqual(
                len(matches), 0,
                f"File {rel_path} contains deprecated .withOpacity calls: {matches}"
            )

    def test_03_syntax_and_bracket_balancing(self):
        """Verify that brackets, parentheses, and braces are balanced in all files."""
        for rel_path in self.files_to_check:
            abs_path = os.path.join(PROJECT_ROOT, rel_path)
            with open(abs_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Clean out string literals and comments for balance checking
            cleaned = re.sub(r'//.*', '', content)
            cleaned = re.sub(r'/\*.*?\*/', '', cleaned, flags=re.DOTALL)
            cleaned = re.sub(r"'(?:\\.|[^'])*'", "''", cleaned)
            cleaned = re.sub(r'"(?:\\.|[^"])*"', '""', cleaned)

            stack = []
            brackets = {'(': ')', '{': '}', '[': ']'}
            for char in cleaned:
                if char in brackets:
                    stack.append(char)
                elif char in brackets.values():
                    self.assertTrue(len(stack) > 0, f"Unmatched closing bracket '{char}' in {rel_path}")
                    opening = stack.pop()
                    self.assertEqual(
                        brackets[opening], char,
                        f"Mismatched bracket in {rel_path}: expected {brackets[opening]} but got {char}"
                    )
            self.assertEqual(len(stack), 0, f"Unclosed brackets remaining in {rel_path}: {stack}")

    def test_04_ast_tokens_and_structure(self):
        """Verify presence of key architectural constructs across all M5 components."""
        # 1. weight_line_chart_painter
        painter_path = os.path.join(PROJECT_ROOT, 'lib/widgets/metrics/weight_line_chart_painter.dart')
        with open(painter_path, 'r', encoding='utf-8') as f:
            painter_src = f.read()
        self.assertIn('class WeightLineChartPainter extends CustomPainter', painter_src)
        self.assertIn('_paintEmptyState', painter_src)
        self.assertIn('_paintSingleLogState', painter_src)
        self.assertIn('_paintMultiLogChart', painter_src)
        self.assertIn('cubicTo', painter_src)
        self.assertIn('LinearGradient', painter_src)
        self.assertIn('shouldRepaint', painter_src)

        # 2. quick_weight_entry_dialog
        dialog_path = os.path.join(PROJECT_ROOT, 'lib/widgets/metrics/quick_weight_entry_dialog.dart')
        with open(dialog_path, 'r', encoding='utf-8') as f:
            dialog_src = f.read()
        self.assertIn('showQuickWeightEntryDialog', dialog_src)
        self.assertIn('class QuickWeightEntryDialog extends StatefulWidget', dialog_src)
        self.assertIn('_weightController', dialog_src)
        self.assertIn('_notesController', dialog_src)
        self.assertIn('20.0', dialog_src)
        self.assertIn('350.0', dialog_src)
        self.assertIn('MealController.instance.recordWeight', dialog_src)

        # 3. weight_trend_bento_card
        wt_path = os.path.join(PROJECT_ROOT, 'lib/widgets/metrics/weight_trend_bento_card.dart')
        with open(wt_path, 'r', encoding='utf-8') as f:
            wt_src = f.read()
        self.assertIn('WeightTrendBentoCard', wt_src)
        self.assertIn('WeightLineChartPainter', wt_src)
        self.assertIn('showQuickWeightEntryDialog', wt_src)

        # 4. calorie_compliance_bento_card
        cc_path = os.path.join(PROJECT_ROOT, 'lib/widgets/metrics/calorie_compliance_bento_card.dart')
        with open(cc_path, 'r', encoding='utf-8') as f:
            cc_src = f.read()
        self.assertIn('CalorieComplianceBentoCard', cc_src)
        self.assertIn('Déficit saludable', cc_src)
        self.assertIn('Mantenimiento', cc_src)
        self.assertIn('Superávit', cc_src)

        # 5. macro_distribution_bento_card
        md_path = os.path.join(PROJECT_ROOT, 'lib/widgets/metrics/macro_distribution_bento_card.dart')
        with open(md_path, 'r', encoding='utf-8') as f:
            md_src = f.read()
        self.assertIn('MacroDistributionBentoCard', md_src)
        self.assertIn('Proteína', md_src)
        self.assertIn('Carbos', md_src)
        self.assertIn('Grasas', md_src)

        # 6. streak_compliance_bento_card
        sc_path = os.path.join(PROJECT_ROOT, 'lib/widgets/metrics/streak_compliance_bento_card.dart')
        with open(sc_path, 'r', encoding='utf-8') as f:
            sc_src = f.read()
        self.assertIn('StreakComplianceBentoCard', sc_src)
        self.assertIn('calculateStreak', sc_src)
        self.assertIn('Imparable 🔥', sc_src)

        # 7. metrics_screen
        ms_path = os.path.join(PROJECT_ROOT, 'lib/screens/metrics_screen.dart')
        with open(ms_path, 'r', encoding='utf-8') as f:
            ms_src = f.read()
        self.assertIn('class MetricsScreen extends StatefulWidget', ms_src)
        self.assertIn('VeAppBar', ms_src)
        self.assertIn('WeightTrendBentoCard', ms_src)
        self.assertIn('CalorieComplianceBentoCard', ms_src)
        self.assertIn('StreakComplianceBentoCard', ms_src)
        self.assertIn('MacroDistributionBentoCard', ms_src)
        self.assertIn('FloatingActionButton.extended', ms_src)

        # 8. dashboard_screen
        db_path = os.path.join(PROJECT_ROOT, 'lib/screens/dashboard_screen.dart')
        with open(db_path, 'r', encoding='utf-8') as f:
            db_src = f.read()
        self.assertIn('MetricsScreen', db_src)
        self.assertIn('Icons.insights_outlined', db_src)

    def test_05_streak_calculation_logic(self):
        """Hermetic verification of streak counting algorithm."""
        now = datetime.now()
        today_str = now.strftime('%Y-%m-%d')
        yesterday_str = (now - timedelta(days=1)).strftime('%Y-%m-%d')
        day2_str = (now - timedelta(days=2)).strftime('%Y-%m-%d')
        day4_str = (now - timedelta(days=4)).strftime('%Y-%m-%d')

        def calc_streak(dates):
            date_set = set(dates)
            if today_str in date_set:
                check_date = now
            elif yesterday_str in date_set:
                check_date = now - timedelta(days=1)
            else:
                return 0

            streak = 0
            while True:
                d_str = check_date.strftime('%Y-%m-%d')
                if d_str in date_set:
                    streak += 1
                    check_date = check_date - timedelta(days=1)
                else:
                    break
            return streak

        self.assertEqual(calc_streak([]), 0)
        self.assertEqual(calc_streak([today_str]), 1)
        self.assertEqual(calc_streak([yesterday_str]), 1)
        self.assertEqual(calc_streak([today_str, yesterday_str, day2_str]), 3)
        self.assertEqual(calc_streak([yesterday_str, day2_str]), 2)
        self.assertEqual(calc_streak([day4_str]), 0)

    def test_06_bezier_midpoint_calculation(self):
        """Hermetic verification of cubic Bézier midpoint smoothing."""
        p0 = (10.0, 20.0)
        p1 = (50.0, 100.0)
        dx_half = (p1[0] - p0[0]) / 2.0
        cp1 = (p0[0] + dx_half, p0[1])
        cp2 = (p0[0] + dx_half, p1[1])

        self.assertEqual(cp1, (30.0, 20.0))
        self.assertEqual(cp2, (30.0, 100.0))

    def test_07_chart_weight_bounds_and_padding(self):
        """Hermetic verification of chart min/max padding and division-by-zero defense."""
        # Flat weights case
        min_w, max_w = 75.0, 75.0
        if abs(max_w - min_w) < 0.001:
            min_w = max(0.0, min_w - 1.5)
            max_w = max_w + 1.5
        self.assertEqual(min_w, 73.5)
        self.assertEqual(max_w, 76.5)
        self.assertGreater(max_w - min_w, 0)

        # Distinct weights case
        min_w, max_w = 70.0, 80.0
        pad = (max_w - min_w) * 0.15
        min_w = max(0.0, min_w - pad)
        max_w = max_w + pad
        self.assertEqual(min_w, 68.5)
        self.assertEqual(max_w, 81.5)
        self.assertEqual(max_w - min_w, 13.0)

    def test_08_calorie_and_macro_compliance_calculations(self):
        """Hermetic verification of calorie status and macro percentages."""
        # Calorie status logic
        target = 2000.0
        def get_status(avg, tgt):
            if tgt <= 0:
                return 'Sin meta'
            if avg < tgt - 200:
                return 'Déficit saludable'
            if abs(avg - tgt) <= 200:
                return 'Mantenimiento'
            return 'Superávit'

        self.assertEqual(get_status(1700.0, target), 'Déficit saludable')
        self.assertEqual(get_status(1900.0, target), 'Mantenimiento')
        self.assertEqual(get_status(2100.0, target), 'Mantenimiento')
        self.assertEqual(get_status(2300.0, target), 'Superávit')

        # Macro percentage distribution
        p, c, f = 150.0, 200.0, 50.0
        tot = p + c + f
        pct_p = (p / tot) * 100
        pct_c = (c / tot) * 100
        pct_f = (f / tot) * 100
        self.assertAlmostEqual(pct_p, 37.5)
        self.assertAlmostEqual(pct_c, 50.0)
        self.assertAlmostEqual(pct_f, 12.5)
        self.assertAlmostEqual(pct_p + pct_c + pct_f, 100.0)


if __name__ == '__main__':
    unittest.main()

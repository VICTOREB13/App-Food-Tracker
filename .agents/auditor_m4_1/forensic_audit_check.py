"""
Independent Forensic Integrity Audit Script for Milestone 4
Phase 2: Settings Screen Cards & Dynamic Model Selector UI
"""

import os
import re
import sys
import unittest

PROJECT_ROOT = r"C:\Users\vmesp\Documents\Cositas\App-Food-Tracker"

class ForensicAuditM4(unittest.TestCase):

    def test_01_all_screens_loc_budget(self):
        """Verify that every screen in lib/screens/ is strictly < 300 LoC."""
        screens_dir = os.path.join(PROJECT_ROOT, "lib", "screens")
        self.assertTrue(os.path.isdir(screens_dir), "lib/screens/ directory not found")

        screens = [f for f in os.listdir(screens_dir) if f.endswith(".dart")]
        self.assertGreaterEqual(len(screens), 4, f"Expected at least 4 screens, found {len(screens)}")

        print(f"\n[FORENSIC] Auditing {len(screens)} screens in lib/screens/:")
        for screen in screens:
            path = os.path.join(screens_dir, screen)
            with open(path, "r", encoding="utf-8") as f:
                lines = f.readlines()
            count = len(lines)
            print(f"  -> {screen}: {count} lines")
            self.assertLess(count, 300, f"INTEGRITY VIOLATION: {screen} has {count} lines (>= 300 LoC limit)")

    def test_02_zero_deprecated_with_opacity(self):
        """Verify zero occurrences of deprecated .withOpacity in lib/ and test/."""
        targets = [os.path.join(PROJECT_ROOT, "lib"), os.path.join(PROJECT_ROOT, "test")]
        violations = []

        for target in targets:
            for root, _, files in os.walk(target):
                for file in files:
                    if file.endswith(".dart"):
                        fpath = os.path.join(root, file)
                        with open(fpath, "r", encoding="utf-8") as f:
                            content = f.read()
                        if ".withOpacity(" in content:
                            violations.append(fpath)

        self.assertEqual(violations, [], f"INTEGRITY VIOLATION: Deprecated .withOpacity found in: {violations}")

    def test_03_facade_and_stub_detection(self):
        """Verify no UnimplementedError or dummy stubs in M4 deliverables."""
        m4_files = [
            os.path.join(PROJECT_ROOT, "lib", "widgets", "settings", "gemini_model_selector_card.dart"),
            os.path.join(PROJECT_ROOT, "lib", "widgets", "settings", "usda_api_key_card.dart"),
            os.path.join(PROJECT_ROOT, "lib", "screens", "settings_screen.dart"),
            os.path.join(PROJECT_ROOT, "lib", "screens", "dashboard_screen.dart"),
            os.path.join(PROJECT_ROOT, "lib", "screens", "meal_detail_screen.dart"),
            os.path.join(PROJECT_ROOT, "lib", "controllers", "settings_controller.dart"),
        ]

        for fpath in m4_files:
            self.assertTrue(os.path.exists(fpath), f"File missing: {fpath}")
            with open(fpath, "r", encoding="utf-8") as f:
                content = f.read()

            self.assertNotIn("UnimplementedError", content,
                f"INTEGRITY VIOLATION: UnimplementedError found in {fpath}")
            self.assertNotIn("throw UnsupportedError", content,
                f"INTEGRITY VIOLATION: UnsupportedError stub found in {fpath}")

    def test_04_dynamic_gemini_models_zero_hardcoding(self):
        """Verify dynamic model loading, no hardcoded models list in UI, and dynamic injection in Dashboard."""
        # 1. Check GeminiModelSelectorCard uses models parameter and fallback
        card_path = os.path.join(PROJECT_ROOT, "lib", "widgets", "settings", "gemini_model_selector_card.dart")
        with open(card_path, "r", encoding="utf-8") as f:
            card_code = f.read()

        self.assertIn("models", card_code)
        self.assertIn("GeminiModelService.fallbackModels", card_code)
        self.assertIn("onSelectModel", card_code)
        self.assertIn("onRefresh", card_code)

        # 2. Check SettingsController queries GeminiModelService
        ctrl_path = os.path.join(PROJECT_ROOT, "lib", "controllers", "settings_controller.dart")
        with open(ctrl_path, "r", encoding="utf-8") as f:
            ctrl_code = f.read()

        self.assertIn("_geminiModelService.fetchAvailableModels", ctrl_code)
        self.assertIn("SecureStorageService.instance.setSelectedGeminiModel", ctrl_code)
        self.assertIn("SecureStorageService.instance.getSelectedGeminiModel", ctrl_code)

        # 3. Check DashboardScreen dynamically retrieves selected model and master prompt
        dash_path = os.path.join(PROJECT_ROOT, "lib", "screens", "dashboard_screen.dart")
        with open(dash_path, "r", encoding="utf-8") as f:
            dash_code = f.read()

        self.assertIn("SecureStorageService.instance.getSelectedGeminiModel()", dash_code)
        self.assertIn("SecureStorageService.instance.getMasterPrompt()", dash_code)
        self.assertIn("GeminiVisionService(", dash_code)
        self.assertIn("modelName: effectiveModel", dash_code)
        self.assertIn("masterPrompt: masterPrompt", dash_code)

        # Ensure NO hardcoded 'gemini-2.5-flash' passed directly to GeminiVisionService in DashboardScreen
        self.assertNotIn("modelName: 'gemini-2.5-flash'", dash_code,
            "INTEGRITY VIOLATION: DashboardScreen has hardcoded modelName in GeminiVisionService instantiation")

    def test_05_usda_api_key_persistence_and_fallback(self):
        """Verify UsdaApiKeyCard persists to SecureStorageService and includes fallback notice."""
        card_path = os.path.join(PROJECT_ROOT, "lib", "widgets", "settings", "usda_api_key_card.dart")
        with open(card_path, "r", encoding="utf-8") as f:
            card_code = f.read()

        self.assertIn("currentApiKey", card_code)
        self.assertIn("onSaveApiKey", card_code)
        self.assertIn("Open Food Facts", card_code)
        self.assertIn("1,000 req/hr", card_code)

        # Verify SettingsScreen ties UsdaApiKeyCard to SettingsController.saveUsdaApiKey
        settings_path = os.path.join(PROJECT_ROOT, "lib", "screens", "settings_screen.dart")
        with open(settings_path, "r", encoding="utf-8") as f:
            settings_code = f.read()

        self.assertIn("UsdaApiKeyCard(", settings_code)
        self.assertIn("_controller.saveUsdaApiKey(key)", settings_code)

        # Verify SettingsController writes to SecureStorageService
        ctrl_path = os.path.join(PROJECT_ROOT, "lib", "controllers", "settings_controller.dart")
        with open(ctrl_path, "r", encoding="utf-8") as f:
            ctrl_code = f.read()

        self.assertIn("SecureStorageService.instance.setUsdaApiKey(trimmed)", ctrl_code)
        self.assertIn("SecureStorageService.instance.deleteUsdaApiKey()", ctrl_code)
        self.assertIn("SecureStorageService.instance.getUsdaApiKey()", ctrl_code)

    def test_06_clean_lifecycle_and_controller_disposal(self):
        """Verify all TextControllers and listeners in M4 stateful classes are properly disposed."""
        # Check UsdaApiKeyCard
        card_path = os.path.join(PROJECT_ROOT, "lib", "widgets", "settings", "usda_api_key_card.dart")
        with open(card_path, "r", encoding="utf-8") as f:
            code = f.read()
        self.assertIn("_controller.dispose()", code)
        self.assertIn("super.dispose()", code)

        # Check SettingsScreen
        settings_path = os.path.join(PROJECT_ROOT, "lib", "screens", "settings_screen.dart")
        with open(settings_path, "r", encoding="utf-8") as f:
            code = f.read()
        self.assertIn("_controller.removeListener", code)

        # Check DashboardScreen
        dash_path = os.path.join(PROJECT_ROOT, "lib", "screens", "dashboard_screen.dart")
        with open(dash_path, "r", encoding="utf-8") as f:
            code = f.read()
        self.assertIn("_mealController.removeListener", code)

        # Check MealDetailScreen
        meal_path = os.path.join(PROJECT_ROOT, "lib", "screens", "meal_detail_screen.dart")
        with open(meal_path, "r", encoding="utf-8") as f:
            code = f.read()
        self.assertIn("_nameController.dispose()", code)
        self.assertIn("_notesController.dispose()", code)

    def test_07_test_suites_authenticity(self):
        """Verify tests are genuine, non-tautological, and cover M4 specifications."""
        ctrl_test = os.path.join(PROJECT_ROOT, "test", "controllers", "settings_controller_test.dart")
        with open(ctrl_test, "r", encoding="utf-8") as f:
            code = f.read()
        # Verify it has real tests and assertions
        self.assertGreater(code.count("test("), 5)
        self.assertGreater(code.count("expect("), 15)
        self.assertIn("FakeFlutterSecureStorage", code)
        self.assertIn("MockClient", code)

        model_test = os.path.join(PROJECT_ROOT, "test", "widgets", "gemini_model_selector_card_test.dart")
        with open(model_test, "r", encoding="utf-8") as f:
            code = f.read()
        self.assertGreater(code.count("testWidgets("), 4)
        self.assertGreater(code.count("expect("), 10)
        self.assertIn("find.text('Ingresa tu Gemini API Key", code)
        self.assertIn("find.byType(DropdownButtonFormField", code)

        usda_test = os.path.join(PROJECT_ROOT, "test", "widgets", "usda_api_key_card_test.dart")
        with open(usda_test, "r", encoding="utf-8") as f:
            code = f.read()
        self.assertGreater(code.count("testWidgets("), 3)
        self.assertGreater(code.count("expect("), 10)
        self.assertIn("find.text('CONFIGURADA')", code)
        self.assertIn("find.text('OPCIONAL')", code)

    def test_08_prepopulated_artifacts_detection(self):
        """Verify no pre-populated fake test results, attestations, or fake log files in the repo."""
        suspicious = []
        for root, dirs, files in os.walk(PROJECT_ROOT):
            # Skip .git, .agents, .dart_tool, build
            if any(p in root for p in [".git", ".dart_tool", "build", ".gradle"]):
                continue
            for file in files:
                if file.endswith(".log") or (file.startswith("test_result") and not file.endswith(".dart")):
                    suspicious.append(os.path.join(root, file))

        self.assertEqual(suspicious, [], f"INTEGRITY VIOLATION: Pre-populated result artifacts found: {suspicious}")


if __name__ == "__main__":
    unittest.main(verbosity=2)

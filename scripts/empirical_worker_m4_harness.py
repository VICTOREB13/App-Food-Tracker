"""
Empirical Verification Harness for Phase 2 Milestone 4:
Settings Screen Cards & Dynamic Model Selector UI for Victor Engineer - Food Tracker.
"""

import os
import re
import unittest

BASE_DIR = r"C:\Users\vmesp\Documents\Cositas\App-Food-Tracker"

class TestMilestone4EmpiricalHarness(unittest.TestCase):

    def test_01_screens_loc_strict_compliance(self):
        """Verify that ALL screens in lib/screens/ are strictly < 300 LoC."""
        screens_dir = os.path.join(BASE_DIR, "lib", "screens")
        screen_files = [
            "settings_screen.dart",
            "dashboard_screen.dart",
            "meal_detail_screen.dart",
            "user_profile_screen.dart",
        ]

        print("\n--- Screen LoC Audit ---")
        for sfile in screen_files:
            fpath = os.path.join(screens_dir, sfile)
            self.assertTrue(os.path.exists(fpath), f"Screen file missing: {sfile}")
            with open(fpath, "r", encoding="utf-8") as f:
                lines = f.readlines()
            loc = len(lines)
            print(f"  {sfile}: {loc} lines (< 300 LoC: {'PASS' if loc < 300 else 'FAIL'})")
            self.assertLess(loc, 300, f"{sfile} exceeds 300 LoC! Found {loc} lines.")

    def test_02_syntax_balance_and_zero_deprecated_opacity(self):
        """Verify balanced braces and zero deprecated .withOpacity usage across all M4 files."""
        m4_files = [
            os.path.join(BASE_DIR, "lib", "controllers", "settings_controller.dart"),
            os.path.join(BASE_DIR, "lib", "widgets", "settings", "gemini_model_selector_card.dart"),
            os.path.join(BASE_DIR, "lib", "widgets", "settings", "usda_api_key_card.dart"),
            os.path.join(BASE_DIR, "lib", "screens", "settings_screen.dart"),
            os.path.join(BASE_DIR, "lib", "screens", "dashboard_screen.dart"),
            os.path.join(BASE_DIR, "lib", "screens", "meal_detail_screen.dart"),
            os.path.join(BASE_DIR, "test", "controllers", "settings_controller_test.dart"),
            os.path.join(BASE_DIR, "test", "widgets", "gemini_model_selector_card_test.dart"),
            os.path.join(BASE_DIR, "test", "widgets", "usda_api_key_card_test.dart"),
        ]

        for fpath in m4_files:
            self.assertTrue(os.path.exists(fpath), f"File missing: {fpath}")
            with open(fpath, "r", encoding="utf-8") as f:
                content = f.read()

            self.assertNotIn(".withOpacity(", content,
                f"Deprecated .withOpacity( found in {os.path.basename(fpath)}. Must use .withValues(alpha: ...)")

            # Check balanced brackets
            open_braces = content.count("{")
            close_braces = content.count("}")
            self.assertEqual(open_braces, close_braces,
                f"Unbalanced curly braces in {os.path.basename(fpath)}: {open_braces} open vs {close_braces} close")

            open_parens = content.count("(")
            close_parens = content.count(")")
            self.assertEqual(open_parens, close_parens,
                f"Unbalanced parentheses in {os.path.basename(fpath)}: {open_parens} open vs {close_parens} close")

    def test_03_gemini_model_selector_card_requirements(self):
        """Verify all mandated strings, tokens, and logic in GeminiModelSelectorCard."""
        fpath = os.path.join(BASE_DIR, "lib", "widgets", "settings", "gemini_model_selector_card.dart")
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()

        # Required verbatim strings
        self.assertIn("Ingresa tu Gemini API Key para descubrir y seleccionar modelos", content)
        self.assertIn("Modelos en línea desde Google AI Studio", content)
        self.assertIn("Modo offline (modelos por defecto)", content)

        # Mandated semantic badge labels
        self.assertIn("RECOMENDADO (Ultrarrápido)", content)
        self.assertIn("ESTABLE (Alta Velocidad)", content)
        self.assertIn("MÁXIMA PRECISIÓN (Razonamiento)", content)

        # Tokens and components
        self.assertIn("VeCard", content)
        self.assertIn("AppColors.primary", content)
        self.assertIn("AppColors.protein", content)
        self.assertIn("AppColors.carbs", content)
        self.assertIn("DropdownButtonFormField", content)
        self.assertIn("onRefresh", content)
        self.assertIn("isLoading", content)

    def test_04_usda_api_key_card_requirements(self):
        """Verify all mandated fields, descriptions, and buttons in UsdaApiKeyCard."""
        fpath = os.path.join(BASE_DIR, "lib", "widgets", "settings", "usda_api_key_card.dart")
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("USDA FOODDATA CENTRAL (API KEY)", content)
        self.assertIn("Open Food Facts", content)
        self.assertIn("1,000 req/hr", content)
        self.assertIn("VeCard", content)
        self.assertIn("obscureText", content)
        self.assertIn("Clipboard", content)
        self.assertIn("Guardar Key", content)
        self.assertIn("Eliminar", content)
        self.assertIn("CONFIGURADA", content)
        self.assertIn("OPCIONAL", content)

    def test_05_settings_controller_requirements(self):
        """Verify properties, reactive methods, and persistence calls in SettingsController."""
        fpath = os.path.join(BASE_DIR, "lib", "controllers", "settings_controller.dart")
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()

        # Properties
        self.assertIn("selectedGeminiModel", content)
        self.assertIn("usdaApiKey", content)
        self.assertIn("availableGeminiModels", content)
        self.assertIn("isLoadingModels", content)
        self.assertIn("isOnlineModels", content)

        # Methods
        self.assertIn("loadSelectedGeminiModel()", content)
        self.assertIn("saveSelectedGeminiModel(String", content)
        self.assertIn("loadUsdaApiKey()", content)
        self.assertIn("saveUsdaApiKey(String", content)
        self.assertIn("loadAvailableGeminiModels", content)
        self.assertIn("notifyListeners()", content)

        # Persistence integration
        self.assertIn("SecureStorageService.instance.getSelectedGeminiModel", content)
        self.assertIn("SecureStorageService.instance.setSelectedGeminiModel", content)
        self.assertIn("SecureStorageService.instance.getUsdaApiKey", content)
        self.assertIn("SecureStorageService.instance.setUsdaApiKey", content)

    def test_06_settings_screen_card_order_and_navigation(self):
        """Verify card ordering in SettingsScreen."""
        fpath = os.path.join(BASE_DIR, "lib", "screens", "settings_screen.dart")
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()

        # Order check: ApiKeyInputCard -> GeminiModelSelectorCard -> UsdaApiKeyCard -> UserProfileScreen
        idx_api = content.find("ApiKeyInputCard(")
        idx_gemini = content.find("GeminiModelSelectorCard(")
        idx_usda = content.find("UsdaApiKeyCard(")
        idx_profile = content.find("UserProfileScreen")

        self.assertNotEqual(idx_api, -1, "ApiKeyInputCard missing from SettingsScreen")
        self.assertNotEqual(idx_gemini, -1, "GeminiModelSelectorCard missing from SettingsScreen")
        self.assertNotEqual(idx_usda, -1, "UsdaApiKeyCard missing from SettingsScreen")
        self.assertNotEqual(idx_profile, -1, "UserProfileScreen navigation missing from SettingsScreen")

        self.assertLess(idx_api, idx_gemini, "GeminiModelSelectorCard must be placed below ApiKeyInputCard")
        self.assertLess(idx_gemini, idx_usda, "UsdaApiKeyCard must be placed below GeminiModelSelectorCard")
        self.assertLess(idx_usda, idx_profile, "UserProfileScreen card must be placed below UsdaApiKeyCard")
        self.assertIn("Perfil Nutricional y Metas (Mifflin-St Jeor)", content)

    def test_07_dashboard_dynamic_model_and_prompt_injection(self):
        """Verify DashboardScreen dynamic model retrieval and Master Prompt injection into GeminiVisionService."""
        fpath = os.path.join(BASE_DIR, "lib", "screens", "dashboard_screen.dart")
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("SecureStorageService.instance.getSelectedGeminiModel()", content)
        self.assertIn("SecureStorageService.instance.getMasterPrompt()", content)
        self.assertIn("modelName: effectiveModel", content)
        self.assertIn("masterPrompt: masterPrompt", content)
        self.assertIn("Analizando con $effectiveModel...", content)

    def test_08_test_suites_rigor(self):
        """Verify all 3 test files exist and contain genuine test cases."""
        test_files = [
            ("test/controllers/settings_controller_test.dart", ["init()", "saveApiKey", "saveSelectedGeminiModel", "saveUsdaApiKey", "loadAvailableGeminiModels"]),
            ("test/widgets/gemini_model_selector_card_test.dart", ["Ingresa tu Gemini API Key", "Modelos en línea desde Google AI Studio", "Modo offline", "onSelectModel", "onRefresh"]),
            ("test/widgets/usda_api_key_card_test.dart", ["OPCIONAL", "CONFIGURADA", "visibility", "Guardar Key", "Eliminar"]),
        ]

        for rel_path, required_assertions in test_files:
            fpath = os.path.join(BASE_DIR, rel_path)
            self.assertTrue(os.path.exists(fpath), f"Test file missing: {rel_path}")
            with open(fpath, "r", encoding="utf-8") as f:
                content = f.read()
            for assertion in required_assertions:
                self.assertIn(assertion, content, f"Assertion '{assertion}' missing in {rel_path}")


if __name__ == "__main__":
    unittest.main(verbosity=2)

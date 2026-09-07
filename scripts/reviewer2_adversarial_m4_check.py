"""
Reviewer 2 Adversarial and Independent Verification Suite for Phase 2 Milestone 4.
Performs integrity checking, adversarial stress testing, syntax/static analysis,
memory leak / lifecycle verification, and contract compliance.
"""

import os
import re
import unittest

BASE_DIR = r"C:\Users\vmesp\Documents\Cositas\App-Food-Tracker"

class Reviewer2AdversarialSuite(unittest.TestCase):

    def setUp(self):
        self.settings_ctrl_path = os.path.join(BASE_DIR, "lib", "controllers", "settings_controller.dart")
        self.gemini_card_path = os.path.join(BASE_DIR, "lib", "widgets", "settings", "gemini_model_selector_card.dart")
        self.usda_card_path = os.path.join(BASE_DIR, "lib", "widgets", "settings", "usda_api_key_card.dart")
        self.settings_screen_path = os.path.join(BASE_DIR, "lib", "screens", "settings_screen.dart")
        self.dashboard_screen_path = os.path.join(BASE_DIR, "lib", "screens", "dashboard_screen.dart")
        self.meal_detail_path = os.path.join(BASE_DIR, "lib", "screens", "meal_detail_screen.dart")
        self.user_profile_path = os.path.join(BASE_DIR, "lib", "screens", "user_profile_screen.dart")

    def test_01_integrity_check_no_hardcoded_facades_or_cheats(self):
        """Verify absence of integrity violations: no hardcoded fake test responses in source,
        no bypassed tasks, no dummy implementations."""
        src_files = [
            self.settings_ctrl_path,
            self.gemini_card_path,
            self.usda_card_path,
            self.settings_screen_path,
            self.dashboard_screen_path,
        ]

        suspicious_patterns = [
            r'return\s+true\s*;\s*//\s*bypass',
            r'TODO.*implement',
            r'throw\s+UnimplementedError',
            r'mockApiResponse',
            r'fakeResponse',
        ]

        for path in src_files:
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            for pat in suspicious_patterns:
                match = re.search(pat, content, re.IGNORECASE)
                self.assertIsNone(
                    match,
                    f"Integrity violation candidate found in {os.path.basename(path)} matching '{pat}': {match.group(0) if match else ''}"
                )

    def test_02_screen_loc_strict_bound(self):
        """Every screen in lib/screens/ must be strictly < 300 LoC."""
        screens = [
            ("settings_screen.dart", self.settings_screen_path),
            ("dashboard_screen.dart", self.dashboard_screen_path),
            ("meal_detail_screen.dart", self.meal_detail_path),
            ("user_profile_screen.dart", self.user_profile_path),
        ]
        for name, path in screens:
            with open(path, "r", encoding="utf-8") as f:
                lines = f.readlines()
            self.assertLess(len(lines), 300, f"Screen {name} has {len(lines)} lines, exceeding 300 LoC limit!")

    def test_03_settings_controller_reactive_contract_and_fallback(self):
        """Verify all reactive getters, methods, fallback handling, and notification in SettingsController."""
        with open(self.settings_ctrl_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Check required reactive properties
        expected_getters = [
            "String? get selectedGeminiModel",
            "String? get usdaApiKey",
            "bool get hasUsdaApiKey",
            "List<GeminiModelInfo> get availableGeminiModels",
            "bool get isLoadingModels",
            "bool get isOnlineModels",
        ]
        for getter in expected_getters:
            self.assertIn(getter, content, f"Missing getter: {getter}")

        # Check fallback to GeminiModelService.fallbackModels in catch block and offline
        self.assertIn("GeminiModelService.fallbackModels", content)
        self.assertIn("catch (_)", content)
        self.assertIn("_isOnlineModels = false", content)

        # Check notifyListeners calls
        notify_count = content.count("notifyListeners()")
        self.assertGreaterEqual(notify_count, 6, f"Expected at least 6 notifyListeners calls, found {notify_count}")

    def test_04_dashboard_dynamic_vision_invocation_no_hardcoding(self):
        """DashboardScreen must dynamically fetch selected Gemini model and masterPrompt,
        and inject them into GeminiVisionService without hardcoding model strings."""
        with open(self.dashboard_screen_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Ensure no hardcoded model string in _handleAiPhotoScan
        handle_photo_start = content.find("Future<void> _handleAiPhotoScan")
        self.assertNotEqual(handle_photo_start, -1, "_handleAiPhotoScan not found")
        handle_photo_end = content.find("Future<void> _handleBarcodeScan")
        handle_photo_body = content[handle_photo_start:handle_photo_end]

        # Must query storage
        self.assertIn("SecureStorageService.instance.getSelectedGeminiModel()", handle_photo_body)
        self.assertIn("SecureStorageService.instance.getMasterPrompt()", handle_photo_body)

        # Must inject into GeminiVisionService
        self.assertIn("GeminiVisionService(", handle_photo_body)
        self.assertIn("modelName: effectiveModel", handle_photo_body)
        self.assertIn("masterPrompt: masterPrompt", handle_photo_body)

        # Must NOT hardcode 'gemini-2.5-flash' directly as literal parameter
        self.assertNotIn("modelName: 'gemini-2.5-flash'", handle_photo_body)
        self.assertNotIn("modelName: \"gemini-2.5-flash\"", handle_photo_body)

    def test_05_settings_screen_user_profile_navigation(self):
        """SettingsScreen must feature a dedicated navigation card to UserProfileScreen."""
        with open(self.settings_screen_path, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn("Perfil Nutricional y Metas (Mifflin-St Jeor)", content)
        self.assertIn("UserProfileScreen", content)
        self.assertIn("MaterialPageRoute(builder: (_) => const UserProfileScreen())", content)

    def test_06_lifecycle_leak_and_disposal_verification(self):
        """Verify that every controller and listener in stateful widgets is properly disposed."""
        # 1. UsdaApiKeyCard: TextEditingController initialized and disposed
        with open(self.usda_card_path, "r", encoding="utf-8") as f:
            usda_code = f.read()
        self.assertIn("_controller.dispose()", usda_code)
        self.assertIn("super.dispose()", usda_code)

        # 2. SettingsScreen: SettingsController listener added and removed
        with open(self.settings_screen_path, "r", encoding="utf-8") as f:
            settings_code = f.read()
        self.assertIn("_controller.addListener(_onControllerChange)", settings_code)
        self.assertIn("_controller.removeListener(_onControllerChange)", settings_code)

        # 3. DashboardScreen: MealController listener added and removed
        with open(self.dashboard_screen_path, "r", encoding="utf-8") as f:
            dashboard_code = f.read()
        self.assertIn("_mealController.addListener(_onControllerChange)", dashboard_code)
        self.assertIn("_mealController.removeListener(_onControllerChange)", dashboard_code)

    def test_07_gemini_model_selector_card_empty_and_null_resilience(self):
        """Verify GeminiModelSelectorCard resilience to null/empty inputs, preserving safety."""
        with open(self.gemini_card_path, "r", encoding="utf-8") as f:
            content = f.read()

        # Null apiKey check renders banner
        self.assertIn("if (!hasKey)", content)
        self.assertIn("Ingresa tu Gemini API Key para descubrir y seleccionar modelos", content)

        # Null or empty models list fallback
        self.assertIn("effectiveList", content)
        self.assertIn("GeminiModelService.fallbackModels", content)

        # Dropdown selection safety: effectiveSelected must exist in effectiveList
        self.assertIn("effectiveList.any((m) => m.name == selectedModel)", content)
        self.assertIn("effectiveList.first.name", content)

    def test_08_deprecated_with_opacity_ban(self):
        """Ensure no file uses deprecated .withOpacity (Flutter 3.22+ deprecation)."""
        all_dart_files = []
        for root, _, files in os.walk(os.path.join(BASE_DIR, "lib")):
            for file in files:
                if file.endswith(".dart"):
                    all_dart_files.append(os.path.join(root, file))

        for fpath in all_dart_files:
            with open(fpath, "r", encoding="utf-8") as f:
                content = f.read()
            self.assertNotIn(
                ".withOpacity(", content,
                f"Deprecated .withOpacity( found in {os.path.relpath(fpath, BASE_DIR)}. Must use .withValues(alpha: ...)"
            )


if __name__ == "__main__":
    unittest.main(verbosity=2)

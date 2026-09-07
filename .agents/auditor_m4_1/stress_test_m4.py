"""
Adversarial Stress Test Script for Milestone 4 (Settings Cards & Model Selector)
Auditor M4.1 (critic role)
"""

import os
import unittest

PROJECT_ROOT = r"C:\Users\vmesp\Documents\Cositas\App-Food-Tracker"

class AdversarialStressTestM4(unittest.TestCase):

    def test_edge_case_whitespace_handling_in_keys(self):
        """Verify that SettingsController trims keys before persistence."""
        ctrl_path = os.path.join(PROJECT_ROOT, "lib", "controllers", "settings_controller.dart")
        with open(ctrl_path, "r", encoding="utf-8") as f:
            code = f.read()

        # In saveApiKey:
        self.assertIn("final trimmed = key.trim();", code)
        self.assertIn("SecureStorageService.instance.setGeminiApiKey(trimmed)", code)

        # In saveUsdaApiKey:
        self.assertIn("final trimmed = key.trim();", code)
        self.assertIn("SecureStorageService.instance.setUsdaApiKey(trimmed)", code)

        # In saveSelectedGeminiModel:
        self.assertIn("final trimmed = model.trim();", code)
        self.assertIn("SecureStorageService.instance.setSelectedGeminiModel(trimmed)", code)

    def test_edge_case_unknown_or_stale_model_selection(self):
        """Verify fallback when selected model is stale or not present in available list."""
        card_path = os.path.join(PROJECT_ROOT, "lib", "widgets", "settings", "gemini_model_selector_card.dart")
        with open(card_path, "r", encoding="utf-8") as f:
            card_code = f.read()

        # In GeminiModelSelectorCard:
        # effectiveSelected must check if selectedModel exists in effectiveList
        self.assertIn("effectiveList.any((m) => m.name == selectedModel)", card_code)

        # In SettingsController:
        ctrl_path = os.path.join(PROJECT_ROOT, "lib", "controllers", "settings_controller.dart")
        with open(ctrl_path, "r", encoding="utf-8") as f:
            ctrl_code = f.read()

        self.assertIn("GeminiModelService.resolveEffectiveModel(", ctrl_code)
        self.assertIn("if (_selectedGeminiModel == null || !_availableGeminiModels.any((m) => m.name == _selectedGeminiModel))", ctrl_code)

    def test_edge_case_offline_network_resilience(self):
        """Verify that network errors in model loading do not crash the app."""
        ctrl_path = os.path.join(PROJECT_ROOT, "lib", "controllers", "settings_controller.dart")
        with open(ctrl_path, "r", encoding="utf-8") as f:
            ctrl_code = f.read()

        self.assertIn("try {", ctrl_code)
        self.assertIn("final models = await _geminiModelService.fetchAvailableModels(key);", ctrl_code)
        self.assertIn("} catch (_) {", ctrl_code)
        self.assertIn("_availableGeminiModels = GeminiModelService.fallbackModels;", ctrl_code)
        self.assertIn("_isOnlineModels = false;", ctrl_code)

    def test_edge_case_empty_usda_key_behavior(self):
        """Verify deletion behavior when key is empty string."""
        ctrl_path = os.path.join(PROJECT_ROOT, "lib", "controllers", "settings_controller.dart")
        with open(ctrl_path, "r", encoding="utf-8") as f:
            ctrl_code = f.read()

        self.assertIn("if (trimmed.isEmpty) {", ctrl_code)
        self.assertIn("await SecureStorageService.instance.deleteUsdaApiKey();", ctrl_code)
        self.assertIn("_usdaApiKey = null;", ctrl_code)

    def test_edge_case_dashboard_missing_model_fallback(self):
        """Verify DashboardScreen gracefully falls back to default vision model if selectedModel is null."""
        dash_path = os.path.join(PROJECT_ROOT, "lib", "screens", "dashboard_screen.dart")
        with open(dash_path, "r", encoding="utf-8") as f:
            code = f.read()

        self.assertIn("final effectiveModel = selectedModel ?? GeminiVisionService.defaultModel;", code)


if __name__ == "__main__":
    unittest.main(verbosity=2)

import 'settings_profile.controller.dart';
import 'settings_profile.view.dart';
import 'user_profile.view.dart';
import 'onboarding.view.dart';

export 'settings_profile.model.dart';
export 'settings_profile.controller.dart';
export 'settings_profile.view.dart';
export 'user_profile.view.dart';
export 'onboarding.view.dart';

/// Backward-compatible aliases
typedef SettingsController = SettingsProfileController;
typedef SettingsScreen = SettingsProfileView;
typedef UserProfileScreen = UserProfileView;
typedef OnboardingScreen = OnboardingView;

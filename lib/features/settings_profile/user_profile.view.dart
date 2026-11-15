import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../biometrics_weight/biometrics_weight.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/features/settings_profile/models/user_profile.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'package:food_tracker/features/biometrics_weight/services/metabolic_calculator.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';
import 'package:food_tracker/core/ui/components/ve_app_bar.dart';
import 'package:food_tracker/features/settings_profile/widgets/profile/activity_goal_selector_card.dart';
import 'package:food_tracker/features/settings_profile/widgets/profile/biometric_inputs_card.dart';
import 'package:food_tracker/features/settings_profile/widgets/profile/metabolic_summary_bento_card.dart';
import 'settings_profile.controller.dart';

/// User profile and metabolic parameters configuration view.
class UserProfileView extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onProfileSaved;
  final SettingsProfileController? controller;

  const UserProfileView({
    super.key,
    this.isOnboarding = false,
    this.onProfileSaved,
    this.controller,
  });

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  late final SettingsProfileController _controller;
  bool _isLoading = true;
  bool _isSaving = false;

  String? _name;
  int _age = 0;
  String _gender = 'male';
  double _height = 0.0;
  double _weight = 0.0;
  String _activityLevel = 'moderate';
  String _bodyGoal = 'fat_loss';
  int _estimatedSteps = 8000;
  UserProfile? _calculatedProfile;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? SettingsProfileController.instance;
    _loadProfile();
    BiometricsWeightController.instance.addListener(_onMealControllerChanged);
  }

  @override
  void dispose() {
    BiometricsWeightController.instance.removeListener(_onMealControllerChanged);
    super.dispose();
  }

  void _onMealControllerChanged() {
    final currentWeight = BiometricsWeightController.instance.currentWeight;
    if (currentWeight != null && currentWeight > 0 && currentWeight != _weight && mounted) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final saved = await DatabaseService.instance.getUserProfile();
      if (saved != null) {
        _name = saved.name ?? _name;
        _age = saved.age;
        _gender = saved.gender;
        _height = saved.height;
        _weight = saved.weight;
        _activityLevel = saved.activityLevel;
        _bodyGoal = saved.bodyGoal;
        _estimatedSteps = saved.estimatedSteps;
        _calculatedProfile = saved;
      } else {
        _recalculate();
      }
    } catch (_) {
      _recalculate();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _recalculate({bool preserveCustomTargets = false}) {
    final prev = _calculatedProfile;
    final calculated = MetabolicCalculator.calculateProfile(
      name: _name,
      age: _age > 0 ? _age : 25,
      gender: _gender,
      height: _height > 0 ? _height : 170.0,
      weight: _weight > 0 ? _weight : 70.0,
      activityLevel: _activityLevel,
      bodyGoal: _bodyGoal,
      estimatedSteps: _estimatedSteps,
    );
    if (preserveCustomTargets && prev != null && prev.targetCalories > 0) {
      _calculatedProfile = calculated.copyWith(
        targetCalories: prev.targetCalories,
        targetProtein: prev.targetProtein,
        targetCarbs: prev.targetCarbs,
        targetFat: prev.targetFat,
      );
    } else {
      _calculatedProfile = calculated;
    }
  }

  void _onBiometricsChanged({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
  }) {
    setState(() {
      if (name != null) _name = name;
      if (age != null) _age = age;
      if (gender != null) _gender = gender;
      if (height != null) _height = height;
      if (weight != null) _weight = weight;
      _recalculate();
    });
  }

  void _onActivityGoalChanged({
    String? activityLevel,
    String? bodyGoal,
    int? estimatedSteps,
  }) {
    setState(() {
      if (activityLevel != null) _activityLevel = activityLevel;
      if (bodyGoal != null) _bodyGoal = bodyGoal;
      if (estimatedSteps != null) _estimatedSteps = estimatedSteps;
      _recalculate();
    });
  }

  Future<void> _saveProfile() async {
    if (_calculatedProfile == null || _isSaving) return;
    final l10n = AppLocalizations.of(context);

    if (_age < 10 || _age > 120 || _height < 80 || _height > 250 || _weight < 30 || _weight > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterValidBodyMeasurements),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await MetabolicCalculator.saveAndSynchronizeProfile(_calculatedProfile!);
      _controller.notifyProfileUpdated();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileAndGoalsSyncedSuccess),
          backgroundColor: AppColors.protein,
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onProfileSaved?.call();

      if (widget.isOnboarding && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileSaveError('$e')),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: VeAppBar(
        title: widget.isOnboarding ? l10n.configureYourProfile : l10n.metabolicProfile,
        subtitle: widget.isOnboarding
            ? l10n.step1BioParamsAndTdee
            : l10n.mifflinStJeorSubtitle,
        leading: widget.isOnboarding && !Navigator.of(context).canPop()
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                MetabolicSummaryBentoCard(profile: _calculatedProfile),
                const SizedBox(height: 16),
                BiometricInputsCard(
                  initialName: _name,
                  initialAge: _age,
                  initialGender: _gender,
                  initialHeight: _height,
                  initialWeight: _weight,
                  onChanged: _onBiometricsChanged,
                ),
                const SizedBox(height: 16),
                ActivityGoalSelectorCard(
                  initialActivityLevel: _activityLevel,
                  initialBodyGoal: _bodyGoal,
                  initialEstimatedSteps: _estimatedSteps,
                  onChanged: _onActivityGoalChanged,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sync_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                widget.isOnboarding ? l10n.completeOnboardingAndSave : l10n.saveProfileAndSyncGoals,
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

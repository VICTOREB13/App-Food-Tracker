import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../services/metabolic_calculator.dart';
import '../services/theme_manager.dart';
import '../widgets/common/ve_app_bar.dart';
import '../widgets/profile/activity_goal_selector_card.dart';
import '../widgets/profile/biometric_inputs_card.dart';
import '../widgets/profile/metabolic_summary_bento_card.dart';

class UserProfileScreen extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onProfileSaved;

  const UserProfileScreen({
    super.key,
    this.isOnboarding = false,
    this.onProfileSaved,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  // Form State
  String? _name = 'Victor Engineer';
  int _age = 28;
  String _gender = 'male';
  double _height = 175.0;
  double _weight = 75.0;
  String _activityLevel = 'moderate';
  String _bodyGoal = 'fat_loss';
  int _estimatedSteps = 8000;

  UserProfile? _calculatedProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
      }
    } catch (_) {}

    _recalculate();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _recalculate() {
    _calculatedProfile = MetabolicCalculator.calculateProfile(
      name: _name,
      age: _age,
      gender: _gender,
      height: _height,
      weight: _weight,
      activityLevel: _activityLevel,
      bodyGoal: _bodyGoal,
      estimatedSteps: _estimatedSteps,
    );
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

    setState(() => _isSaving = true);
    try {
      await MetabolicCalculator.saveAndSynchronizeProfile(_calculatedProfile!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil metabólico y metas sincronizadas con éxito'),
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
          content: Text('Error al guardar el perfil: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VeAppBar(
        title: widget.isOnboarding ? 'Configura tu Perfil' : 'Perfil Metabólico',
        subtitle: widget.isOnboarding
            ? 'Paso 1: Parámetros Biológicos y Metas TDEE'
            : 'Mifflin-St Jeor & Master Prompt',
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
                // Real-time calculated summary Bento card
                MetabolicSummaryBentoCard(profile: _calculatedProfile),
                const SizedBox(height: 16),

                // Biometrics input card
                BiometricInputsCard(
                  initialName: _name,
                  initialAge: _age,
                  initialGender: _gender,
                  initialHeight: _height,
                  initialWeight: _weight,
                  onChanged: _onBiometricsChanged,
                ),
                const SizedBox(height: 16),

                // Activity level & Body goal selector card
                ActivityGoalSelectorCard(
                  initialActivityLevel: _activityLevel,
                  initialBodyGoal: _bodyGoal,
                  initialEstimatedSteps: _estimatedSteps,
                  onChanged: _onActivityGoalChanged,
                ),
                const SizedBox(height: 24),

                // Save and Sync Goals CTA Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sync_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                widget.isOnboarding
                                    ? 'Completar Onboarding y Guardar Metas'
                                    : 'Guardar Perfil y Sincronizar Metas',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
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

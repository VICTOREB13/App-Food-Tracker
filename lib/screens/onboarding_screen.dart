import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../services/metabolic_calculator.dart';
import '../services/theme_manager.dart';
import '../widgets/onboarding/onboarding_activity_step.dart';
import '../widgets/onboarding/onboarding_biometrics_step.dart';
import '../widgets/onboarding/onboarding_goal_step.dart';
import '../widgets/onboarding/onboarding_welcome_step.dart';
import 'dashboard_screen.dart';

/// Full-screen 4-step first-time onboarding wizard.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Profile fields state
  String _name = 'Victor';
  String _gender = 'male';
  int _age = 28;
  double _height = 175.0;
  double _weight = 75.0;
  String _activityLevel = 'moderate';
  int _estimatedSteps = 8000;
  String _bodyGoal = 'fat_loss';

  late UserProfile _calculatedProfile;

  @override
  void initState() {
    super.initState();
    _recalculate();
    _loadExistingIfAny();
  }

  Future<void> _loadExistingIfAny() async {
    try {
      final existing = await DatabaseService.instance.getUserProfile();
      if (existing != null && mounted) {
        setState(() {
          _name = existing.name ?? _name;
          _gender = existing.gender;
          _age = existing.age;
          _height = existing.height;
          _weight = existing.weight;
          _activityLevel = existing.activityLevel;
          _estimatedSteps = existing.estimatedSteps;
          _bodyGoal = existing.bodyGoal;
          _recalculate();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _recalculate() {
    _calculatedProfile = MetabolicCalculator.calculateProfile(
      name: _name.trim().isEmpty ? 'Comensal' : _name.trim(),
      age: _age,
      gender: _gender,
      height: _height,
      weight: _weight,
      activityLevel: _activityLevel,
      bodyGoal: _bodyGoal,
      estimatedSteps: _estimatedSteps,
    );
  }

  void _nextPage() {
    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  Future<void> _finishOnboarding() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      _recalculate();
      await MetabolicCalculator.saveAndSynchronizeProfile(_calculatedProfile);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar perfil: $e'),
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
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: _prevPage,
                color: AppColors.textPrimary(context),
              )
            : (Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.textSecondary(context),
                  )
                : null),
        title: Column(
          children: [
            Text(
              'PASO ${_currentStep + 1} DE 4',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 140,
                height: 4,
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 4,
                  backgroundColor: AppColors.border(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [
                  OnboardingWelcomeStep(
                    name: _name,
                    onNameChanged: (val) => setState(() {
                      _name = val;
                      _recalculate();
                    }),
                  ),
                  OnboardingBiometricsStep(
                    gender: _gender,
                    age: _age,
                    height: _height,
                    weight: _weight,
                    onChanged: ({gender, age, height, weight}) => setState(() {
                      if (gender != null) _gender = gender;
                      if (age != null) _age = age;
                      if (height != null) _height = height;
                      if (weight != null) _weight = weight;
                      _recalculate();
                    }),
                  ),
                  OnboardingActivityStep(
                    activityLevel: _activityLevel,
                    estimatedSteps: _estimatedSteps,
                    onChanged: ({activityLevel, estimatedSteps}) => setState(() {
                      if (activityLevel != null) _activityLevel = activityLevel;
                      if (estimatedSteps != null) _estimatedSteps = estimatedSteps;
                      _recalculate();
                    }),
                  ),
                  OnboardingGoalStep(
                    bodyGoal: _bodyGoal,
                    profile: _calculatedProfile,
                    onGoalChanged: (val) => setState(() {
                      _bodyGoal = val;
                      _recalculate();
                    }),
                  ),
                ],
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isLastStep = _currentStep == 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(top: BorderSide(color: AppColors.border(context))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            OutlinedButton(
              onPressed: _prevPage,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary(context),
                side: BorderSide(color: AppColors.border(context)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: Text(
                'Atrás',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : (isLastStep ? _finishOnboarding : _nextPage),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLastStep ? 'Guardar y Empezar a Registrar' : 'Continuar',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isLastStep ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

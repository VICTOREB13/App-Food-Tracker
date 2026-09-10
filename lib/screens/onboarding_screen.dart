import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';
import '../services/metabolic_calculator.dart';
import '../services/theme_manager.dart';
import '../widgets/onboarding/onboarding_activity_step.dart';
import '../widgets/onboarding/onboarding_biometrics_step.dart';
import '../widgets/onboarding/onboarding_bottom_nav.dart';
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

  // Profile fields state - empty for clean new user onboarding
  String _name = '';
  String _gender = 'male';
  int _age = 0;
  double _height = 0.0;
  double _weight = 0.0;
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
      age: _age > 0 ? _age : 25,
      gender: _gender,
      height: _height > 0 ? _height : 170.0,
      weight: _weight > 0 ? _weight : 70.0,
      activityLevel: _activityLevel,
      bodyGoal: _bodyGoal,
      estimatedSteps: _estimatedSteps,
    );
  }

  bool get _isCurrentStepValid {
    if (_currentStep == 0) return _name.trim().isNotEmpty;
    if (_currentStep == 1) {
      return _age >= 10 && _age <= 120 && _height >= 80 && _height <= 250 && _weight >= 30 && _weight <= 300;
    }
    return true;
  }

  void _handleContinue() {
    if (_currentStep == 0 && _name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa tu nombre para continuar.'), backgroundColor: AppColors.primary),
      );
      return;
    }
    if (_currentStep == 1 && !_isCurrentStepValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa tus datos corporales válidos para continuar.'), backgroundColor: AppColors.primary),
      );
      return;
    }
    _nextPage();
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
            OnboardingBottomNav(
              currentStep: _currentStep,
              isSaving: _isSaving,
              isValid: _isCurrentStepValid,
              onPrev: _prevPage,
              onNext: _nextPage,
              onFinish: _finishOnboarding,
              onInvalidTap: _handleContinue,
            ),
          ],
        ),
      ),
    );
  }
}

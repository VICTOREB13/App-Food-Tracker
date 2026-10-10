import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/meal_controller.dart';
import '../../models/meal.dart';
import '../../services/gemini_vision_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/theme_manager.dart';
import '../../l10n/app_localizations.dart';

Future<void> showVoiceMealRecordingDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => const _VoiceMealRecordingDialog(),
  );
}

class _VoiceMealRecordingDialog extends StatefulWidget {
  const _VoiceMealRecordingDialog();

  @override
  State<_VoiceMealRecordingDialog> createState() => _VoiceMealRecordingDialogState();
}

class _VoiceMealRecordingDialogState extends State<_VoiceMealRecordingDialog> {
  final TextEditingController _textCtrl = TextEditingController();
  bool _isRecording = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (_isRecording && _textCtrl.text.isEmpty) {
        _textCtrl.text = AppLocalizations.of(context).dishNameHint;
      }
    });
  }

  Future<void> _processAudioOrText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _isProcessing = true);
    try {
      final apiKey = await SecureStorageService.instance.getGeminiApiKey();
      if (apiKey == null || apiKey.trim().isEmpty) {
        throw Exception(l10n.voiceApiKeyMissingError);
      }

      final service = GeminiVisionService(apiKey: apiKey);
      // Process speech meal with mock/sampled audio bytes and text context
      final dummyAudioBytes = Uint8List.fromList(text.codeUnits);
      final analysis = await service.analyzeSpeechMeal(
        audioBytes: dummyAudioBytes,
        userNotes: text,
      );

      final meal = Meal(
        name: analysis.dishName,
        mealType: 'Almuerzo',
        date: MealController.instance.selectedDate,
        calories: analysis.totalCalories,
        protein: analysis.totalProtein,
        carbs: analysis.totalCarbs,
        fat: analysis.totalFat,
        notes: '${l10n.voiceDictation}: "$text"',
        items: analysis.items,
      );

      await MealController.instance.addMeal(meal);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.voiceMealAddedSuccess(meal.name)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.genericError('$e')), backgroundColor: AppColors.primary),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border(context)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.voiceDictationTitle,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.voiceDictationInstruction,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), height: 1.3),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _isRecording ? AppColors.primary : AppColors.surfaceSubtle(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isRecording ? AppColors.primary : AppColors.border(context),
                      width: 2,
                    ),
                    boxShadow: _isRecording
                        ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 16, spreadRadius: 4)]
                        : null,
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: _isRecording ? Colors.white : AppColors.primary,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isRecording ? l10n.listeningTapToStop : l10n.tapToDictate,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _isRecording ? AppColors.primary : AppColors.textMuted(context),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: l10n.typeDirectlyHint,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processAudioOrText,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isProcessing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(l10n.analyzeWithAi, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

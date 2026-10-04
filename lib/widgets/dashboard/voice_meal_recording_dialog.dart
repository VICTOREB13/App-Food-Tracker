import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/meal_controller.dart';
import '../../models/meal.dart';
import '../../services/gemini_vision_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/theme_manager.dart';

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
        _textCtrl.text = 'Pechuga de pollo a la plancha con arroz blanco y ensalada de aguacate';
      }
    });
  }

  Future<void> _processAudioOrText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isProcessing = true);
    try {
      final apiKey = await SecureStorageService.instance.getGeminiApiKey();
      if (apiKey == null || apiKey.trim().isEmpty) {
        throw Exception('Configura tu API Key de Gemini en Ajustes.');
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
        notes: 'Dictado por voz: "$text"',
        items: analysis.items,
      );

      await MealController.instance.addMeal(meal);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comida "${meal.name}" agregada por voz.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.primary),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            'Dictado por Voz',
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
                'Describe tu plato con lenguaje natural. Gemini Vision extraerá ingredientes, porciones y macronutrientes.',
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
                _isRecording ? 'Escuchando... Toca para detener' : 'Toca el micrófono para dictar',
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
                decoration: const InputDecoration(
                  hintText: 'O escribe directamente: "2 huevos revueltos con 1 tostada y café"',
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
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
              : Text('Analizar con IA', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

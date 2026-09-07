import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/settings_screen.dart';
import '../../services/theme_manager.dart';

void showApiKeyPromptDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface(context),
      title: Text('Configurar Gemini API Key', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      content: Text(
        'Para usar visión multimodal y cubicaje con IA necesitas agregar tu clave gratuita de Google Gemini en Ajustes.',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: const Text('Ir a Ajustes'),
        ),
      ],
    ),
  );
}

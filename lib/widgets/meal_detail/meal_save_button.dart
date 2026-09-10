import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';

class MealSaveButton extends StatelessWidget {
  final bool isSaving;
  final bool isEditing;
  final VoidCallback onSave;

  const MealSaveButton({
    super.key,
    required this.isSaving,
    required this.isEditing,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isSaving ? null : onSave,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.save_outlined),
      label: Text(
        isSaving ? 'Guardando...' : (isEditing ? 'Actualizar Comida' : 'Registrar Comida'),
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }
}

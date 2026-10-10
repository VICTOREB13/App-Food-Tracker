import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../models/meal.dart';

class MealFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController notesController;
  final String mealType;
  final ValueChanged<String?> onMealTypeChanged;

  const MealFormFields({
    super.key,
    required this.nameController,
    required this.notesController,
    required this.mealType,
    required this.onMealTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context) ?? AppLocalizationsEs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: l10n.dishNameLabel,
            hintText: l10n.dishNameHint,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: mealType,
          menuMaxHeight: 280,
          decoration: InputDecoration(labelText: l10n.mealTypeLabel),
          items: Meal.validMealTypes
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.toLocalizedMealType(context)),
                  ))
              .toList(),
          onChanged: onMealTypeChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: l10n.notesLabel,
            hintText: l10n.notesHint,
          ),
        ),
      ],
    );
  }
}

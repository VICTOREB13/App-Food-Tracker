import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameController,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            labelText: 'Nombre del plato *',
            hintText: 'Ej. Pechuga a la plancha con arroz',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: mealType,
          menuMaxHeight: 280,
          decoration: const InputDecoration(labelText: 'Tipo de Comida'),
          items: Meal.validMealTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: onMealTypeChanged,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notas / Observaciones',
            hintText: 'Ej. Se usó poco aceite en sofrito, porción mediana',
          ),
        ),
      ],
    );
  }
}

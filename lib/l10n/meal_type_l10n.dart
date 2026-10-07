import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Extension to localize invariant meal keys ('Desayuno', 'Almuerzo', 'Cena', 'Snack', 'Otro')
/// into the current active UI locale without mutating database storage values.
extension MealTypeLocalization on String {
  String toLocalizedMealType(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return this;
    final lower = trim().toLowerCase();
    if (lower == 'desayuno' || lower == 'breakfast') return l10n.breakfast;
    if (lower == 'almuerzo' || lower == 'lunch') return l10n.lunch;
    if (lower == 'cena' || lower == 'dinner') return l10n.dinner;
    if (lower == 'snack') return l10n.snack;
    if (lower == 'otro' || lower == 'other') return l10n.other;
    return this;
  }
}

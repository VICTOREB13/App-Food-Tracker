import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../services/theme_manager.dart';

class DateSelectorBar extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onToday;
  final ValueChanged<DateTime> onDateSelected;

  const DateSelectorBar({
    super.key,
    required this.selectedDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onToday,
    required this.onDateSelected,
  });

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  String _formatDate(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = l10n.localeName;
    try {
      final now = DateTime.now();
      if (selectedDate.year == now.year &&
          selectedDate.month == now.month &&
          selectedDate.day == now.day) {
        return '${l10n.today}, ${DateFormat('d MMM', localeName).format(selectedDate)}';
      }
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      if (selectedDate.year == yesterday.year &&
          selectedDate.month == yesterday.month &&
          selectedDate.day == yesterday.day) {
        return '${l10n.yesterday}, ${DateFormat('d MMM', localeName).format(selectedDate)}';
      }
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      if (selectedDate.year == tomorrow.year &&
          selectedDate.month == tomorrow.month &&
          selectedDate.day == tomorrow.day) {
        return '${l10n.tomorrow}, ${DateFormat('d MMM', localeName).format(selectedDate)}';
      }

      return DateFormat('EEE, d MMM yyyy', localeName).format(selectedDate);
    } catch (_) {
      return '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            onPressed: onPreviousDay,
            color: AppColors.textPrimary(context),
            tooltip: l10n.previousDayTooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppColors.primary,
                        ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) onDateSelected(picked);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: _isToday ? AppColors.primary : AppColors.textSecondary(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(context),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isToday)
                IconButton(
                  icon: const Icon(Icons.today, size: 20),
                  onPressed: onToday,
                  color: AppColors.primary,
                  tooltip: l10n.goToTodayTooltip,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 22),
                onPressed: onNextDay,
                color: AppColors.textPrimary(context),
                tooltip: l10n.nextDayTooltip,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

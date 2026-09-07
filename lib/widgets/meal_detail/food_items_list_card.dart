import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/food_item.dart';
import '../../services/theme_manager.dart';
import '../common/macro_indicator_chip.dart';
import '../common/ve_card.dart';

class FoodItemsListCard extends StatelessWidget {
  final List<FoodItem> items;
  final ValueChanged<FoodItem> onEditItem;
  final ValueChanged<FoodItem> onDeleteItem;
  final VoidCallback onAddItem;

  const FoodItemsListCard({
    super.key,
    required this.items,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DESGLOSE DE INGREDIENTES (${items.length})',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary(context),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                color: AppColors.primary,
                onPressed: onAddItem,
                tooltip: 'Añadir ingrediente manual',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No hay ingredientes desglosados en este plato.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted(context),
                  ),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildItemTile(context, item);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, FoodItem item) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              Text(
                '${item.estimatedGrams.toStringAsFixed(0)}g',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                onPressed: () => onEditItem(item),
                color: AppColors.textSecondary(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16),
                onPressed: () => onDeleteItem(item),
                color: AppColors.primaryLight,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              MacroIndicatorChip(
                label: 'Cal',
                value: '${item.calories.toStringAsFixed(0)} kcal',
                accentColor: AppColors.calories,
                isCompact: true,
              ),
              MacroIndicatorChip(
                label: 'P',
                value: '${item.protein.toStringAsFixed(1)}g',
                accentColor: AppColors.protein,
                isCompact: true,
              ),
              MacroIndicatorChip(
                label: 'C',
                value: '${item.carbs.toStringAsFixed(1)}g',
                accentColor: AppColors.carbs,
                isCompact: true,
              ),
              MacroIndicatorChip(
                label: 'G',
                value: '${item.fat.toStringAsFixed(1)}g',
                accentColor: AppColors.fat,
                isCompact: true,
              ),
            ],
          ),
          if (item.visualJustification != null && item.visualJustification!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.border(context).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Estimación: ${item.visualJustification!}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
import 'package:food_tracker/features/food_entry/services/image_processing_service.dart';
import 'package:food_tracker/core/services/nutrition/nutrition_label_scanner_service.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';
import 'package:food_tracker/core/ui/components/ve_app_bar.dart';
import 'package:food_tracker/core/ui/components/ve_card.dart';
import 'package:food_tracker/features/pantry_inventory/widgets/pantry_consumption_dialog.dart';
import 'package:food_tracker/features/pantry_inventory/widgets/pantry_item_editor_dialog.dart';
import 'pantry_inventory.controller.dart';
import 'pantry_inventory.model.dart';

/// Vertical slice screen for managing pantry catalog, stock levels,
/// and AI brand detection (< 300 LoC budget).
class PantryInventoryView extends StatefulWidget {
  final PantryInventoryController? controller;

  const PantryInventoryView({super.key, this.controller});

  @override
  State<PantryInventoryView> createState() => _PantryInventoryViewState();
}

class _PantryInventoryViewState extends State<PantryInventoryView> {
  late final PantryInventoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PantryInventoryController.instance;
    _controller.loadItems();
  }

  Future<void> _scanLabelWithCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600, maxHeight: 1600);
    if (picked == null) return;

    _controller.setScanning(true);
    try {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final compressed = await ImageProcessingService.instance.compressAndResizeAsync(bytes);
      final scanned = await NutritionLabelScannerService.instance.scanNutritionLabel(imageBytes: compressed);

      if (mounted) {
        _controller.setScanning(false);
        final l10n = AppLocalizations.of(context);
        if (scanned != null) {
          _showEditDialog(scanned);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToExtractNutritionLabel), backgroundColor: AppColors.primary),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _controller.setScanning(false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scanError('$e')), backgroundColor: AppColors.primary),
        );
      }
    }
  }

  Future<void> _showEditDialog([PantryItem? item]) async {
    final saved = await showPantryItemEditorDialog(context, item: item);
    if (saved != null) _controller.loadItems();
  }

  Future<void> _consumeItem(PantryItem item) async {
    final consumed = await showPantryConsumptionDialog(context, item);
    if (consumed == true) _controller.loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final filtered = state.filteredItems;

        return Scaffold(
          appBar: VeAppBar(
            title: l10n.myPantry,
            subtitle: l10n.pantryDescription,
            showVeBadge: false,
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'fab_scan_label',
                onPressed: state.isScanning ? null : _scanLabelWithCamera,
                backgroundColor: AppColors.surface(context),
                child: state.isScanning
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: 'fab_add_pantry',
                onPressed: () => _showEditDialog(),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(l10n.addProductAction, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    VeCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.kitchen_outlined, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.pantryDescription,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: PantryCategory.values.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final category = PantryCategory.values[index];
                          final isSelected = state.selectedCategory == category;
                          return ChoiceChip(
                            label: Text(category.getLocalizedLabel(l10n)),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textPrimary(context),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface(context),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onSelected: (selected) {
                              if (selected) {
                                HapticFeedback.selectionClick();
                                _controller.setCategory(category);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            l10n.noProductsInCategory,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted(context)),
                          ),
                        ),
                      )
                    else
                      ...filtered.map((item) => _buildItemTile(item)),
                    const SizedBox(height: 80),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildItemTile(PantryItem item) {
    final l10n = AppLocalizations.of(context);
    final macroSummary = l10n.pantryMacroSummary(
      item.calories.toInt().toString(),
      item.protein.toStringAsFixed(1),
      item.carbs.toStringAsFixed(1),
      item.fat.toStringAsFixed(1),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: VeCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Expanded(child: Text(item.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700))),
              if (item.isExpired)
                _buildStatusBadge(l10n.pantryExpired, Colors.red)
              else if (item.isExpiringSoon)
                _buildStatusBadge(l10n.pantryExpiringSoon, Colors.orange),
              if (item.hasLowStock)
                _buildStatusBadge(l10n.pantryLowStock, Colors.amber),
              if (item.brand != null && item.brand!.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text(item.brand!, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                macroSummary,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.servingPortion(item.servingSize.toInt().toString())}${item.packageWeight != null ? ' • ${l10n.packageWeightPortion(item.packageWeight!.toInt().toString())}' : ''}',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: Key('consume_pantry_${item.id}'),
                icon: const Icon(Icons.restaurant_outlined, size: 20, color: AppColors.protein),
                tooltip: l10n.logToMealTooltip,
                onPressed: () => _consumeItem(item),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: l10n.delete,
                onPressed: () => _controller.deleteItem(item.id),
              ),
            ],
          ),
          onTap: () => _showEditDialog(item),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

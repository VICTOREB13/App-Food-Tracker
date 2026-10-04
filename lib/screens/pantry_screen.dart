import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pantry_item.dart';
import '../services/database_service.dart';
import '../services/image_processing_service.dart';
import '../services/nutrition_label_scanner_service.dart';
import '../services/theme_manager.dart';
import '../widgets/common/ve_app_bar.dart';
import '../widgets/common/ve_card.dart';
import '../widgets/pantry/pantry_consumption_dialog.dart';
import '../widgets/pantry/pantry_item_editor_dialog.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  List<PantryItem> _items = [];
  String _selectedCategory = 'Todos';
  bool _isLoading = true;
  bool _isScanning = false;

  static const _categories = ['Todos', 'Granos', 'Lácteos', 'Proteínas', 'Snacks', 'Bebidas'];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseService.instance.pantryDao.getPantryItems();
      if (mounted) setState(() { _items = list; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _scanLabelWithCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, maxWidth: 1600, maxHeight: 1600);
    if (picked == null) return;

    setState(() => _isScanning = true);
    try {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      final compressed = await ImageProcessingService.instance.compressAndResizeAsync(bytes);
      final scanned = await NutritionLabelScannerService.instance.scanNutritionLabel(imageBytes: compressed);

      if (mounted) {
        setState(() => _isScanning = false);
        if (scanned != null) {
          _showEditDialog(scanned);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo extraer la etiqueta nutricional.'), backgroundColor: AppColors.primary),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al escanear: $e'), backgroundColor: AppColors.primary),
        );
      }
    }
  }

  Future<void> _showEditDialog([PantryItem? item]) async {
    final saved = await showPantryItemEditorDialog(context, item: item);
    if (saved != null) _loadItems();
  }

  Future<void> _consumeItem(PantryItem item) async {
    await showPantryConsumptionDialog(context, item);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'Todos'
        ? _items
        : _items.where((i) => (i.category ?? '').toLowerCase() == _selectedCategory.toLowerCase()).toList();

    return Scaffold(
      appBar: const VeAppBar(
        title: 'Mi Despensa',
        subtitle: 'Contexto de Marcas Locales',
        showVeBadge: false,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_scan_label',
            onPressed: _isScanning ? null : _scanLabelWithCamera,
            backgroundColor: AppColors.surface(context),
            child: _isScanning
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'fab_add_pantry',
            onPressed: () => _showEditDialog(),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Producto', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
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
                          'Tus productos se inyectan en Gemini Vision para reconocer automáticamente tus marcas habituales.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((c) {
                      final sel = _selectedCategory == c;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: sel,
                          onSelected: (s) { if (s) setState(() => _selectedCategory = c); },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No hay productos en esta categoría.\nUsa el escáner o pulsa "+ Producto".',
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
  }

  Widget _buildItemTile(PantryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: VeCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Expanded(child: Text(item.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700))),
              if (item.brand != null && item.brand!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text(item.brand!, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.calories.toInt()} kcal • P: ${item.protein.toStringAsFixed(1)}g • C: ${item.carbs.toStringAsFixed(1)}g • G: ${item.fat.toStringAsFixed(1)}g',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
              ),
              const SizedBox(height: 2),
              Text(
                'Porción: ${item.servingSize.toInt()}g${item.packageWeight != null ? ' • Empaque: ${item.packageWeight!.toInt()}g' : ''}',
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
                tooltip: 'Registrar a Comida',
                onPressed: () => _consumeItem(item),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Eliminar',
                onPressed: () async {
                  await DatabaseService.instance.pantryDao.deletePantryItem(item.id);
                  _loadItems();
                },
              ),
            ],
          ),
          onTap: () => _showEditDialog(item),
        ),
      ),
    );
  }
}

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
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final brandCtrl = TextEditingController(text: item?.brand ?? '');
    final calCtrl = TextEditingController(text: item != null ? item.calories.toStringAsFixed(0) : '100');
    final protCtrl = TextEditingController(text: item != null ? item.protein.toStringAsFixed(1) : '5.0');
    final carbsCtrl = TextEditingController(text: item != null ? item.carbs.toStringAsFixed(1) : '15.0');
    final fatCtrl = TextEditingController(text: item != null ? item.fat.toStringAsFixed(1) : '2.0');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: AppColors.border(context))),
        title: Text(item == null ? 'Añadir Producto' : 'Editar Producto', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del producto *')),
              const SizedBox(height: 10),
              TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Marca (opcional)')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: calCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Calorías', suffixText: 'kcal'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: protCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Proteína', suffixText: 'g'))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: carbsCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Carbos', suffixText: 'g'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: fatCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Grasas', suffixText: 'g'))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final newItem = PantryItem(
                id: item?.id,
                name: name,
                brand: brandCtrl.text.trim().isNotEmpty ? brandCtrl.text.trim() : null,
                calories: double.tryParse(calCtrl.text.trim()) ?? 0,
                protein: double.tryParse(protCtrl.text.trim()) ?? 0,
                carbs: double.tryParse(carbsCtrl.text.trim()) ?? 0,
                fat: double.tryParse(fatCtrl.text.trim()) ?? 0,
              );
              final dao = DatabaseService.instance.pantryDao;
              if (item == null) {
                await dao.insertPantryItem(newItem);
              } else {
                await dao.updatePantryItem(newItem);
              }
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved == true) _loadItems();
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
          subtitle: Text(
            '${item.calories.toInt()} kcal • P: ${item.protein.toStringAsFixed(1)}g • C: ${item.carbs.toStringAsFixed(1)}g • G: ${item.fat.toStringAsFixed(1)}g',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary(context)),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () async {
              await DatabaseService.instance.pantryDao.deletePantryItem(item.id);
              _loadItems();
            },
          ),
          onTap: () => _showEditDialog(item),
        ),
      ),
    );
  }
}

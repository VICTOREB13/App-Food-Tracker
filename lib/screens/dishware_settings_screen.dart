import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/calibrated_dishware.dart';
import '../services/database_service.dart';
import '../services/theme_manager.dart';
import '../widgets/common/ve_app_bar.dart';
import '../widgets/common/ve_card.dart';

class DishwareSettingsScreen extends StatefulWidget {
  const DishwareSettingsScreen({super.key});

  @override
  State<DishwareSettingsScreen> createState() => _DishwareSettingsScreenState();
}

class _DishwareSettingsScreenState extends State<DishwareSettingsScreen> {
  List<CalibratedDishware> _dishwareList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDishware();
  }

  Future<void> _loadDishware() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseService.instance.dishwareDao.getAllDishware();
      if (mounted) {
        setState(() {
          _dishwareList = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddEditDialog([CalibratedDishware? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final diameterCtrl = TextEditingController(text: existing != null ? existing.diameterCm.toStringAsFixed(1) : '26.0');
    final depthCtrl = TextEditingController(text: existing != null ? existing.depthCm.toStringAsFixed(1) : '2.5');
    bool isDefault = existing?.isDefault ?? (_dishwareList.isEmpty);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: AppColors.border(context))),
          title: Text(existing == null ? 'Calibrar Plato' : 'Editar Plato', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre (ej. Plato Llano Blanco)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: diameterCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Diámetro', suffixText: 'cm'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: depthCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Profundidad', suffixText: 'cm'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Usar como referencia por defecto en IA', style: GoogleFonts.inter(fontSize: 12)),
                  value: isDefault,
                  onChanged: (val) => setDlgState(() => isDefault = val ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final diameter = double.tryParse(diameterCtrl.text.trim()) ?? 26.0;
                final depth = double.tryParse(depthCtrl.text.trim()) ?? 2.0;
                if (name.isEmpty) return;

                final dishware = CalibratedDishware(
                  id: existing?.id,
                  name: name,
                  diameterCm: diameter,
                  depthCm: depth,
                  isDefault: isDefault,
                );

                final dao = DatabaseService.instance.dishwareDao;
                if (existing == null) {
                  await dao.insertDishware(dishware);
                } else {
                  await dao.updateDishware(dishware);
                }
                if (isDefault) {
                  await dao.setDefaultDishware(dishware.id);
                }
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) _loadDishware();
  }

  Future<void> _deleteDishware(CalibratedDishware item) async {
    await DatabaseService.instance.dishwareDao.deleteDishware(item.id);
    _loadDishware();
  }

  Future<void> _setDefault(CalibratedDishware item) async {
    await DatabaseService.instance.dishwareDao.setDefaultDishware(item.id);
    _loadDishware();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const VeAppBar(
        title: 'Calibración de Vajilla',
        subtitle: 'Referencia Métrica para IA',
        showVeBadge: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nuevo Plato', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
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
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.straighten_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El diámetro de tu vajilla se inyecta en Gemini Vision para estimar el volumen y peso de las porciones con escala métrica real.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_dishwareList.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'No tienes vajilla calibrada.\nPulsa "+ Nuevo Plato" para agregar tu primer plato.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted(context)),
                      ),
                    ),
                  )
                else
                  ..._dishwareList.map((dish) => _buildDishTile(dish)),
                const SizedBox(height: 72),
              ],
            ),
    );
  }

  Widget _buildDishTile(CalibratedDishware dish) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: VeCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: dish.isDefault ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface(context),
              shape: BoxShape.circle,
              border: Border.all(color: dish.isDefault ? AppColors.primary : AppColors.border(context)),
            ),
            child: Icon(Icons.radio_button_checked, size: 20, color: dish.isDefault ? AppColors.primary : AppColors.textMuted(context)),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  dish.name,
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (dish.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                  child: Text('POR DEFECTO', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
            ],
          ),
          subtitle: Text(
            'Diámetro: ${dish.diameterCm.toStringAsFixed(1)} cm • Profundidad: ${dish.depthCm.toStringAsFixed(1)} cm',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary(context)),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (val) {
              if (val == 'edit') _showAddEditDialog(dish);
              if (val == 'default') _setDefault(dish);
              if (val == 'delete') _deleteDishware(dish);
            },
            itemBuilder: (_) => [
              if (!dish.isDefault) const PopupMenuItem(value: 'default', child: Text('Establecer por defecto')),
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ),
      ),
    );
  }
}

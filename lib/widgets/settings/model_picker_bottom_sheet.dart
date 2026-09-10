// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/gemini_model_info.dart';
import '../../services/gemini_model_service.dart';
import '../../services/theme_manager.dart';

class ModelPickerBottomSheet extends StatefulWidget {
  final String currentModel;
  final List<GeminiModelInfo> models;

  const ModelPickerBottomSheet({super.key, required this.currentModel, required this.models});

  static Future<String?> show(BuildContext context, {required String currentModel, List<GeminiModelInfo>? models}) {
    final effectiveModels = (models != null && models.isNotEmpty) ? models : GeminiModelService.fallbackModels;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ModelPickerBottomSheet(currentModel: currentModel, models: effectiveModels),
      ),
    );
  }

  @override
  State<ModelPickerBottomSheet> createState() => _ModelPickerBottomSheetState();
}

class _ModelPickerBottomSheetState extends State<ModelPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  late String _selectedModel;

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.currentModel;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GeminiModelInfo> get _filteredModels {
    return widget.models.where((model) {
      final nameLower = model.name.toLowerCase();
      final displayLower = model.displayName.toLowerCase();
      if (_selectedFilter == 'flash' && !nameLower.contains('flash')) return false;
      if (_selectedFilter == 'pro' && !nameLower.contains('pro')) return false;
      if (_searchQuery.isNotEmpty) {
        return nameLower.contains(_searchQuery) || displayLower.contains(_searchQuery);
      }
      return true;
    }).toList();
  }

  String _formatTokens(int count) => count >= 1048576
      ? '${(count / 1048576).toStringAsFixed(1).replaceAll('.0', '')}M'
      : (count >= 1024 ? '${(count / 1024).round()}k' : (count > 0 ? '$count' : '--'));

  Color _badgeColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('think') || lower.contains('pro')) return AppColors.primary;
    if (lower.contains('fast') || lower.contains('flash')) return AppColors.protein;
    return AppColors.carbs;
  }

  String _resolveBadgeLabel(GeminiModelInfo model) {
    final lower = model.name.toLowerCase();
    if (lower.contains('pro')) return 'Think';
    if (lower.contains('flash')) return 'Fast';
    if (model.recommendationLabel != null && model.recommendationLabel!.isNotEmpty) {
      return model.recommendationLabel!;
    }
    return 'Fast';
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredModels;

    return Column(
      children: [
        // Handle bar
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Header Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Icon(Icons.psychology_outlined, size: 22, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Seleccionar Modelo Gemini',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary(context)),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o canonical ID...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: AppColors.surfaceSubtle(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border(context)),
              ),
            ),
          ),
        ),

        // Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip('all', 'Todos'),
              const SizedBox(width: 8),
              _buildFilterChip('flash', 'Flash (Rápidos)'),
              const SizedBox(width: 8),
              _buildFilterChip('pro', 'Pro (Razonamiento)'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),

        // Models List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No se encontraron modelos coincidentes',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final model = filtered[index];
                    final isSelected = model.name == _selectedModel;
                    final badge = _resolveBadgeLabel(model);
                    final badgeCol = _badgeColor(badge);

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedModel = model.name);
                        Navigator.of(context).pop(model.name);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surfaceSubtle(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border(context), width: isSelected ? 1.5 : 1.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Radio<String>(
                              value: model.name,
                              groupValue: _selectedModel,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedModel = val);
                                  Navigator.of(context).pop(val);
                                }
                              },
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          model.displayName,
                                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(color: badgeCol.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4), border: Border.all(color: badgeCol.withValues(alpha: 0.3), width: 0.5)),
                                        child: Text(badge, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: badgeCol)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(model.name, style: GoogleFonts.robotoMono(fontSize: 11, color: AppColors.textSecondary(context))),
                                  if (model.description.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text(model.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted(context), height: 1.3)),
                                  ],
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.input, size: 12, color: AppColors.textMuted(context)),
                                      const SizedBox(width: 4),
                                      Text('In: ${_formatTokens(model.inputTokenLimit)}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted(context))),
                                      const SizedBox(width: 12),
                                      Icon(Icons.output, size: 12, color: AppColors.textMuted(context)),
                                      const SizedBox(width: 4),
                                      Text('Out: ${_formatTokens(model.outputTokenLimit)}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted(context))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filterKey),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceSubtle(context),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textSecondary(context),
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border(context),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    );
  }
}

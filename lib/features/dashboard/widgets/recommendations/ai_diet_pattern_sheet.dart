import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:food_tracker/core/models/diet_pattern_insight.dart';
import 'package:food_tracker/core/interfaces/diet_advisor_service_interface.dart';
import 'package:food_tracker/core/services/ai/diet_advisor_service.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';

/// Modal sheet Dark Bento displaying AI-driven longitudinal diet pattern diagnosis.
class AiDietPatternSheet extends StatefulWidget {
  final int initialDays;
  final IDietAdvisorService? service;

  const AiDietPatternSheet({super.key, this.initialDays = 7, this.service});

  static Future<void> show(BuildContext context, {int initialDays = 7, IDietAdvisorService? service}) {
    return showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => FractionallySizedBox(heightFactor: 0.90, child: AiDietPatternSheet(initialDays: initialDays, service: service)),
    );
  }

  @override
  State<AiDietPatternSheet> createState() => _AiDietPatternSheetState();
}

class _AiDietPatternSheetState extends State<AiDietPatternSheet> {
  late int _selectedDays;
  DietPatternInsight? _insight;
  bool _isLoading = true, _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialDays;
    _loadInsight();
  }

  Future<void> _loadInsight({bool forceRefresh = false}) async {
    if (_insight == null || _selectedDays != _insight!.daysAnalyzed) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }
    try {
      final s = widget.service ?? DietAdvisorService.instance;
      final res = await s.getDietPatternInsights(days: _selectedDays, forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _insight = res;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _insight ??= DietPatternInsight.fallback(days: _selectedDays);
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border(context), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Diagnóstico de Hábitos IA', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context)))),
              if (_isRefreshing)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              else
                IconButton(icon: const Icon(Icons.refresh, size: 20), tooltip: 'Actualizar auditoría', onPressed: () => _loadInsight(forceRefresh: true)),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            children: [
              Text('Período:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
              const Spacer(),
              _buildPeriodChip(7, '7 días'), const SizedBox(width: 6),
              _buildPeriodChip(14, '14 días'), const SizedBox(width: 6),
              _buildPeriodChip(30, '30 días'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Divider(height: 1),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _insight == null
                  ? Center(child: Text('Sin datos suficientes', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context))))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroCard(),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildBentoCard('GRASAS Y ACEITES', _insight!.fatInsight, AppColors.fat, Icons.opacity)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildBentoCard('PROTEÍNA Y METAS', _insight!.proteinInsight, AppColors.protein, Icons.fitness_center)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildBentoCard('FIBRA Y VEGETALES', _insight!.fiberInsight, AppColors.carbs, Icons.eco_rounded)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildBentoCard('CONTROL DE SODIO', _insight!.sodiumInsight, AppColors.caloriesFlame, Icons.shield_outlined)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildListCard('MENÚ VISUAL (MÉTODO DE MANOS)', 'Porciones: puño (carbos), palma (proteína) y pulgar (grasas)', _insight!.visualHandMenu, AppColors.primary, Icons.front_hand_outlined),
                          const SizedBox(height: 10),
                          _buildListCard('SUSTITUCIONES Y SNACKS', 'Alternativas prácticas y de fácil preparación local:', _insight!.suggestedSwaps, AppColors.protein, Icons.swap_horiz_rounded),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return ChoiceChip(
      label: Text(label), selected: isSelected,
      onSelected: (_) { if (_selectedDays != days) { setState(() => _selectedDays = days); _loadInsight(); } },
      selectedColor: AppColors.primary, backgroundColor: AppColors.surfaceSubtle(context),
      labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : AppColors.textSecondary(context)),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border(context)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), visualDensity: VisualDensity.compact,
      showCheckmark: false, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    );
  }

  Widget _buildHeroCard() {
    final isDark = AppColors.isDark(context);
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.psychology_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('RESUMEN LONGITUDINAL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.4)),
            const Spacer(),
            Text('${_insight!.daysAnalyzed} días', style: GoogleFonts.robotoMono(fontSize: 10, color: AppColors.textMuted(context))),
          ]),
          const SizedBox(height: 6),
          Text(_insight!.generalSummary, style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: AppColors.textPrimary(context), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBentoCard(String title, String content, Color color, IconData icon) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.30 : 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: color), const SizedBox(width: 6),
            Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3))),
          ]),
          const SizedBox(height: 6),
          Text(content, style: GoogleFonts.inter(fontSize: 11, height: 1.35, color: AppColors.textPrimary(context))),
        ],
      ),
    );
  }

  Widget _buildListCard(String title, String subtitle, List<String> items, Color color, IconData icon) {
    final isDark = AppColors.isDark(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.30 : 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: color), const SizedBox(width: 6),
            Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.3))),
          ]),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary(context))),
          const SizedBox(height: 6),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(margin: const EdgeInsets.only(top: 5, right: 8), width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    Expanded(child: Text(it, style: GoogleFonts.inter(fontSize: 11, height: 1.35, color: AppColors.textPrimary(context)))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

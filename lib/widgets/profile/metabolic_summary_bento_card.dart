import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_profile.dart';
import '../../services/metabolic_calculator.dart';
import '../../services/secure_storage_service.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class MetabolicSummaryBentoCard extends StatefulWidget {
  final UserProfile? profile;
  final bool isCalculating;

  const MetabolicSummaryBentoCard({super.key, required this.profile, this.isCalculating = false});

  @override
  State<MetabolicSummaryBentoCard> createState() => _MetabolicSummaryBentoCardState();
}

class _MetabolicSummaryBentoCardState extends State<MetabolicSummaryBentoCard> {
  bool _showPromptDetails = false;
  late final TextEditingController _promptController;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: widget.profile?.masterPrompt ?? '');
  }

  @override
  void didUpdateWidget(covariant MetabolicSummaryBentoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile?.masterPrompt != oldWidget.profile?.masterPrompt &&
        widget.profile?.masterPrompt != null) {
      _promptController.text = widget.profile!.masterPrompt!;
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomPrompt() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;
    await SecureStorageService.instance.setMasterPrompt(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prompt personalizado guardado con éxito'), backgroundColor: AppColors.protein),
    );
  }

  Future<void> _resetPromptToCalculated() async {
    if (widget.profile == null) return;
    final calculated = MetabolicCalculator.generateMasterPrompt(widget.profile!);
    setState(() => _promptController.text = calculated);
    await SecureStorageService.instance.setMasterPrompt(calculated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Prompt restablecido a valores calculados'), backgroundColor: AppColors.carbs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    if (profile == null) {
      return VeCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Ingresa tus datos biométricos para calcular el perfil',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)),
            ),
          ),
        ),
      );
    }

    final protCals = profile.targetProtein * 4.0;
    final carbCals = profile.targetCarbs * 4.0;
    final fatCals = profile.targetFat * 9.0;
    final totalMacroCals = protCals + carbCals + fatCals;
    final protRatio = totalMacroCals > 0 ? (protCals / totalMacroCals).clamp(0.0, 1.0) : 0.3;
    final carbRatio = totalMacroCals > 0 ? (carbCals / totalMacroCals).clamp(0.0, 1.0) : 0.4;
    final fatRatio = totalMacroCals > 0 ? (fatCals / totalMacroCals).clamp(0.0, 1.0) : 0.3;
    final genderText = profile.gender == 'female' ? 'Femenino' : 'Masculino';

    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 20, color: AppColors.carbs),
                  const SizedBox(width: 8),
                  Text('RESUMEN METABÓLICO', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: AppColors.textSecondary(context))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.carbs.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.carbs.withValues(alpha: 0.3))),
                child: Text('Mifflin-St Jeor', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.carbs)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Biometrics Chip / Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border(context))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fingerprint_rounded, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('${profile.age} años • ${(profile.height % 1 == 0) ? profile.height.toInt() : profile.height} cm • ${(profile.weight % 1 == 0) ? profile.weight.toInt() : profile.weight} kg • $genderText', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Bento Hero Tile: Target Calories
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.surfaceSubtle(context)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PRESUPUESTO DIARIO OBJETIVO', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(profile.targetCalories.toStringAsFixed(0), style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: AppColors.textPrimary(context))),
                        const SizedBox(width: 4),
                        Text('kcal/día', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.20), shape: BoxShape.circle),
                  child: const Icon(Icons.local_fire_department_rounded, color: AppColors.primary, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Two Bento Tiles: BMR & TDEE
          Row(
            children: [
              Expanded(child: _buildStatTile(context, 'TMB (En reposo)', '${profile.bmr.toStringAsFixed(0)} kcal')),
              const SizedBox(width: 10),
              Expanded(child: _buildStatTile(context, 'TDEE (Gasto total)', '${profile.tdee.toStringAsFixed(0)} kcal')),
            ],
          ),
          const SizedBox(height: 14),
          // Macro Distribution Ratio Bar
          Text('Distribución de Macronutrientes', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(flex: (protRatio * 100).toInt().clamp(1, 100), child: Container(color: AppColors.protein)),
                  const SizedBox(width: 2),
                  Expanded(flex: (carbRatio * 100).toInt().clamp(1, 100), child: Container(color: AppColors.carbs)),
                  const SizedBox(width: 2),
                  Expanded(flex: (fatRatio * 100).toInt().clamp(1, 100), child: Container(color: AppColors.fat)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Macro Breakdown 3 Cards
          Row(
            children: [
              Expanded(child: _buildMacroBadge('Proteínas', profile.targetProtein, protCals, AppColors.protein)),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroBadge('Carbohidratos', profile.targetCarbs, carbCals, AppColors.carbs)),
              const SizedBox(width: 8),
              Expanded(child: _buildMacroBadge('Grasas', profile.targetFat, fatCals, AppColors.fat)),
            ],
          ),
          // Master Prompt Section
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => _showPromptDetails = !_showPromptDetails),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_outlined, size: 18, color: AppColors.primaryLight),
                      const SizedBox(width: 6),
                      Text('Master Prompt IA Multimodal (Editable)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryLight)),
                    ],
                  ),
                  Icon(_showPromptDetails ? Icons.expand_less : Icons.expand_more, size: 20, color: AppColors.textSecondary(context)),
                ],
              ),
            ),
          ),
          if (_showPromptDetails) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _promptController,
              maxLines: 6,
              style: GoogleFonts.robotoMono(fontSize: 11, color: AppColors.textPrimary(context), height: 1.4),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceSubtle(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.border(context))),
                hintText: 'Prompt para Gemini Vision...',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetPromptToCalculated,
                    style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.border(context)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 8)),
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: Text('Restablecer', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveCustomPrompt,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 8)),
                    icon: const Icon(Icons.save_outlined, size: 16),
                    label: Text('Guardar Prompt', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceSubtle(context), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border(context))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary(context))),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
        ],
      ),
    );
  }

  Widget _buildMacroBadge(String label, double grams, double calories, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.30))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text('${grams.toStringAsFixed(0)}g', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
          Text('${calories.toStringAsFixed(0)} kcal', style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textMuted(context))),
        ],
      ),
    );
  }
}


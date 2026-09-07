import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class UsdaApiKeyCard extends StatefulWidget {
  final String? currentApiKey;
  final ValueChanged<String> onSaveApiKey;

  const UsdaApiKeyCard({
    super.key,
    required this.currentApiKey,
    required this.onSaveApiKey,
  });

  @override
  State<UsdaApiKeyCard> createState() => _UsdaApiKeyCardState();
}

class _UsdaApiKeyCardState extends State<UsdaApiKeyCard> {
  late final TextEditingController _controller;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentApiKey ?? '');
  }

  @override
  void didUpdateWidget(covariant UsdaApiKeyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentApiKey != widget.currentApiKey) {
      _controller.text = widget.currentApiKey ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      setState(() {
        _controller.text = data!.text!.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = widget.currentApiKey != null && widget.currentApiKey!.trim().isNotEmpty;

    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dataset_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'USDA FOODDATA CENTRAL (API KEY)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasKey
                      ? AppColors.protein.withValues(alpha: 0.15)
                      : AppColors.carbs.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasKey ? 'CONFIGURADA' : 'OPCIONAL',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: hasKey ? AppColors.protein : AppColors.carbs,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Conexión oficial con USDA FoodData Central (https://fdc.nal.usda.gov) para enriquecer la biblioteca de alimentos y códigos de barras. Si se omite la clave o se agota la cuota (1,000 req/hr), el sistema utiliza Open Food Facts automáticamente como respaldo.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary(context),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: _obscureText,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'DEMO_KEY o tu clave de fdc.nal.usda.gov',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.content_paste_outlined, size: 18),
                    tooltip: 'Pegar del portapapeles',
                    color: AppColors.textMuted(context),
                    onPressed: _pasteFromClipboard,
                  ),
                  IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.textMuted(context),
                    ),
                    tooltip: _obscureText ? 'Mostrar clave' : 'Ocultar clave',
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasKey)
                OutlinedButton(
                  onPressed: () {
                    _controller.clear();
                    widget.onSaveApiKey('');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                    side: const BorderSide(color: AppColors.primaryLight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Eliminar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => widget.onSaveApiKey(_controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check, size: 16),
                label: Text('Guardar Key', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/theme_manager.dart';
import '../common/ve_card.dart';

class ApiKeyInputCard extends StatefulWidget {
  final String? currentApiKey;
  final ValueChanged<String> onSaveApiKey;

  const ApiKeyInputCard({
    super.key,
    required this.currentApiKey,
    required this.onSaveApiKey,
  });

  @override
  State<ApiKeyInputCard> createState() => _ApiKeyInputCardState();
}

class _ApiKeyInputCardState extends State<ApiKeyInputCard> {
  late final TextEditingController _controller;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentApiKey ?? '');
  }

  @override
  void didUpdateWidget(covariant ApiKeyInputCard oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final hasKey = widget.currentApiKey != null && widget.currentApiKey!.isNotEmpty;

    return VeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'GEMINI API KEY (BYOK)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasKey
                      ? AppColors.protein.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasKey ? 'CONFIGURADA' : 'NO CONFIGURADA',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: hasKey ? AppColors.protein : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Food Tracker opera 100% Local-First. Tu API Key de Google Gemini se almacena en el enclave seguro de tu dispositivo y se conecta directamente con los modelos de Google Gemini.',
            textAlign: TextAlign.justify,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: _obscureText,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'AIzaSy...',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.textMuted(context),
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
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

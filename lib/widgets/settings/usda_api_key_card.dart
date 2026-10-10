import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
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
                  l10n.usdaApiKeyHeader,
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
                  hasKey ? l10n.statusConfigured : l10n.statusOptional,
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
            l10n.usdaApiKeyNotice,
            textAlign: TextAlign.justify,
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
              hintText: l10n.usdaApiKeyHint,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.content_paste_outlined, size: 18),
                    tooltip: l10n.pasteFromClipboardTooltip,
                    color: AppColors.textMuted(context),
                    onPressed: _pasteFromClipboard,
                  ),
                  IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 18,
                      color: AppColors.textMuted(context),
                    ),
                    tooltip: _obscureText ? l10n.showKeyTooltip : l10n.hideKeyTooltip,
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
                  child: Text(l10n.delete, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                label: Text(l10n.saveKeyAction, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

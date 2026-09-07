import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pantry_item.dart';
import '../../services/barcode_lookup_service.dart';
import '../../services/theme_manager.dart';

Future<PantryItem?> showBarcodeScannerDialog(BuildContext context) {
  return showDialog<PantryItem>(
    context: context,
    builder: (dialogContext) => const _BarcodeScannerDialog(),
  );
}

class _BarcodeScannerDialog extends StatefulWidget {
  const _BarcodeScannerDialog();

  @override
  State<_BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<_BarcodeScannerDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _searchBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final item = await BarcodeLookupService.instance.lookupBarcode(code);
      if (!mounted) return;
      if (item != null) {
        Navigator.of(context).pop(item);
      } else {
        setState(() {
          _errorMessage = 'Producto no encontrado en USDA ni Open Food Facts.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al consultar código: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.border(context)),
      ),
      title: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: AppColors.carbs, size: 22),
          const SizedBox(width: 8),
          Text(
            'Escanear Código',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresa o escanea el código de barras (EAN/UPC) del alimento:',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary(context)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ej. 737628064502',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _searchBarcode(_codeController.text),
              ),
            ),
            onSubmitted: _searchBarcode,
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textSecondary(context))),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _searchBarcode(_codeController.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('Buscar', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

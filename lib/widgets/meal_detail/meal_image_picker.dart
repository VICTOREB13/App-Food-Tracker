import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/image_processing_service.dart';
import '../../services/theme_manager.dart';

Future<String?> pickAndSaveMealImage({
  required BuildContext context,
  required String mealType,
  required DateTime date,
  String? mealId,
  String? currentPath,
}) async {
  final picker = ImagePicker();
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Cámara'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Galería'),
            onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
        ],
      ),
    ),
  );

  if (source == null) return null;
  final file = await picker.pickImage(source: source);
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  final compressed = ImageProcessingService.instance.compressAndResize(bytes);
  final savedPath = await ImageProcessingService.instance.saveMealImage(
    compressed,
    mealType: mealType,
    date: date,
    mealId: mealId,
  );
  if (currentPath != null && currentPath != savedPath) {
    await ImageProcessingService.instance.deleteMealImage(currentPath);
  }
  return savedPath;
}

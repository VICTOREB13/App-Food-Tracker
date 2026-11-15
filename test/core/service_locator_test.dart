import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/features/food_entry/food_entry.dart';
import 'package:food_tracker/features/settings_profile/settings_profile.dart';
import 'package:food_tracker/core/di/service_locator.dart';
import 'package:food_tracker/core/interfaces/daos_interfaces.dart';
import 'package:food_tracker/core/interfaces/database_service_interface.dart';
import 'package:food_tracker/core/interfaces/image_processing_service_interface.dart';
import 'package:food_tracker/features/food_entry/services/analysis_queue_service.dart';
import 'package:food_tracker/features/data_backup/services/backup_service.dart';
import 'package:food_tracker/core/database/daos/dishware_dao.dart';
import 'package:food_tracker/core/database/daos/fasting_dao.dart';
import 'package:food_tracker/core/database/daos/meal_template_dao.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'package:food_tracker/core/services/ai/gemini_vision_service.dart';
import 'package:food_tracker/features/food_entry/services/image_processing_service.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';

void main() {
  setUp(() async {
    await resetServiceLocator();
  });

  tearDown(() async {
    await resetServiceLocator();
  });

  group('ServiceLocator Dependency Injection Tests', () {
    test('setupServiceLocator registers all core interfaces and concrete services', () {
      setupServiceLocator();

      expect(getIt.isRegistered<IDatabaseService>(), isTrue);
      expect(getIt.isRegistered<DatabaseService>(), isTrue);
      expect(getIt.isRegistered<IMealDao>(), isTrue);
      expect(getIt.isRegistered<IWeightLogDao>(), isTrue);
      expect(getIt.isRegistered<IUserProfileDao>(), isTrue);
      expect(getIt.isRegistered<IPantryDao>(), isTrue);
      expect(getIt.isRegistered<IDishwareDao>(), isTrue);
      expect(getIt.isRegistered<DishwareDao>(), isTrue);
      expect(getIt.isRegistered<IMealTemplateDao>(), isTrue);
      expect(getIt.isRegistered<MealTemplateDao>(), isTrue);
      expect(getIt.isRegistered<IFastingDao>(), isTrue);
      expect(getIt.isRegistered<FastingDao>(), isTrue);
      expect(getIt.isRegistered<IImageProcessingService>(), isTrue);
      expect(getIt.isRegistered<ImageProcessingService>(), isTrue);
      expect(getIt.isRegistered<MealController>(), isTrue);
      expect(getIt.isRegistered<SettingsController>(), isTrue);
      expect(getIt.isRegistered<SecureStorageService>(), isTrue);
      expect(getIt.isRegistered<ThemeManager>(), isTrue);
      expect(getIt.isRegistered<AnalysisQueueService>(), isTrue);
      expect(getIt.isRegistered<BackupService>(), isTrue);
      expect(getIt.isRegistered<GeminiVisionService>(), isTrue);
    });

    test('getIt resolves valid instances matching singleton accessors', () {
      setupServiceLocator();

      final db = getIt<IDatabaseService>();
      expect(db, equals(DatabaseService.instance));

      final imgService = getIt<IImageProcessingService>();
      expect(imgService, equals(ImageProcessingService.instance));

      final mealCtrl = getIt<MealController>();
      expect(mealCtrl, equals(MealController.instance));

      final settingsCtrl = getIt<SettingsController>();
      expect(settingsCtrl, equals(SettingsController.instance));

      final vision = getIt<GeminiVisionService>(param1: 'dummy-key', param2: 'dummy-model');
      expect(vision.apiKey, equals('dummy-key'));
      expect(vision.modelName, equals('dummy-model'));
    });

    test('setupServiceLocator is idempotent when called multiple times', () {
      setupServiceLocator();
      setupServiceLocator(); // Should safely return without throw

      expect(getIt.isRegistered<IDatabaseService>(), isTrue);
    });

    test('resetServiceLocator clears all registrations', () async {
      setupServiceLocator();
      expect(getIt.isRegistered<IDatabaseService>(), isTrue);

      await resetServiceLocator();
      expect(getIt.isRegistered<IDatabaseService>(), isFalse);
    });
  });
}

import 'package:get_it/get_it.dart';

import '../../controllers/meal_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../services/analysis_queue_service.dart';
import '../../services/backup_service.dart';
import '../../services/barcode_lookup_service.dart';
import '../../services/database_service.dart';
import '../../services/gemini_model_service.dart';
import '../../services/gemini_vision_service.dart';
import '../../services/image_processing_service.dart';
import '../../services/open_food_facts_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/theme_manager.dart';
import '../../services/usda_food_data_service.dart';
import '../interfaces/daos_interfaces.dart';
import '../interfaces/database_service_interface.dart';
import '../interfaces/image_processing_service_interface.dart';

/// Global Service Locator instance backed by GetIt.
final GetIt getIt = GetIt.instance;

/// Configures and registers all application dependencies, DAOs, and services.
void setupServiceLocator({bool isTesting = false}) {
  if (getIt.isRegistered<IDatabaseService>()) {
    return;
  }

  // Database & DAOs
  final dbService = DatabaseService.instance;
  getIt.registerLazySingleton<IDatabaseService>(() => dbService);
  getIt.registerLazySingleton<DatabaseService>(() => dbService);
  getIt.registerLazySingleton<IMealDao>(() => dbService.mealDao);
  getIt.registerLazySingleton<IWeightLogDao>(() => dbService.weightLogDao);
  getIt.registerLazySingleton<IUserProfileDao>(() => dbService.userProfileDao);
  getIt.registerLazySingleton<IPantryDao>(() => dbService.pantryDao);

  // Media & Image Processing
  final imageService = ImageProcessingService.instance;
  getIt.registerLazySingleton<IImageProcessingService>(() => imageService);
  getIt.registerLazySingleton<ImageProcessingService>(() => imageService);

  // Security, Storage & Theming
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService.instance);
  getIt.registerLazySingleton<ThemeManager>(() => ThemeManager.instance);

  // Network & AI Services
  getIt.registerLazySingleton<GeminiVisionService>(() => GeminiVisionService.instance);
  getIt.registerLazySingleton<GeminiModelService>(() => GeminiModelService.instance);
  getIt.registerLazySingleton<UsdaFoodDataService>(() => UsdaFoodDataService.instance);
  getIt.registerLazySingleton<BarcodeLookupService>(() => BarcodeLookupService.instance);
  getIt.registerLazySingleton<OpenFoodFactsService>(() => OpenFoodFactsService.instance);

  // Background Workers & System Tasks
  getIt.registerLazySingleton<AnalysisQueueService>(() => AnalysisQueueService.instance);
  getIt.registerLazySingleton<BackupService>(() => BackupService.instance);

  // State Management Controllers
  getIt.registerLazySingleton<SettingsController>(() => SettingsController.instance);
  getIt.registerLazySingleton<MealController>(() => MealController.instance);
}

/// Resets the service locator, primarily used during test teardown.
Future<void> resetServiceLocator() async {
  await getIt.reset();
}

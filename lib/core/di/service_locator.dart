import 'package:get_it/get_it.dart';

import '../../controllers/fasting_controller.dart';
import '../../controllers/meal_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../services/analysis_queue_service.dart';
import '../../services/backup_service.dart';
import '../../services/barcode_lookup_service.dart';
import '../../services/daos/dishware_dao.dart';
import '../../services/daos/fasting_dao.dart';
import '../../services/daos/meal_template_dao.dart';
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
import '../interfaces/offline_food_estimator_service_interface.dart';
import '../interfaces/nutrition_label_scanner_service_interface.dart';
import '../interfaces/clinical_excel_export_service_interface.dart';
import '../interfaces/nutritional_recommendation_service_interface.dart';
import '../../services/offline_food_estimator_service.dart';
import '../../services/nutrition_label_scanner_service.dart';
import '../../services/clinical_excel_export_service.dart';
import '../../services/nutritional_recommendation_service.dart';
import '../../services/home_widget_service.dart';
import '../interfaces/app_update_service_interface.dart';
import '../interfaces/app_installer_service_interface.dart';
import '../../services/app_update_service.dart';
import '../../services/app_installer_service.dart';

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
  getIt.registerLazySingleton<IDishwareDao>(() => dbService.dishwareDao);
  getIt.registerLazySingleton<DishwareDao>(() => dbService.dishwareDao as DishwareDao);
  getIt.registerLazySingleton<IMealTemplateDao>(() => dbService.mealTemplateDao);
  getIt.registerLazySingleton<MealTemplateDao>(() => dbService.mealTemplateDao as MealTemplateDao);
  getIt.registerLazySingleton<IFastingDao>(() => dbService.fastingDao);
  getIt.registerLazySingleton<FastingDao>(() => dbService.fastingDao as FastingDao);

  // Media & Image Processing
  final imageService = ImageProcessingService.instance;
  getIt.registerLazySingleton<IImageProcessingService>(() => imageService);
  getIt.registerLazySingleton<ImageProcessingService>(() => imageService);

  // Security, Storage & Theming
  getIt.registerLazySingleton<SecureStorageService>(() => SecureStorageService.instance);
  getIt.registerLazySingleton<ThemeManager>(() => ThemeManager.instance);

  // Network & AI Services
  getIt.registerLazySingleton<GeminiModelService>(() => GeminiModelService.instance);
  getIt.registerLazySingleton<UsdaFoodDataService>(() => UsdaFoodDataService.instance);
  getIt.registerLazySingleton<BarcodeLookupService>(() => BarcodeLookupService.instance);
  getIt.registerLazySingleton<OpenFoodFactsService>(() => OpenFoodFactsService.instance);
  getIt.registerLazySingleton<IOfflineFoodEstimatorService>(() => OfflineFoodEstimatorService.instance);
  getIt.registerLazySingleton<OfflineFoodEstimatorService>(() => OfflineFoodEstimatorService.instance);
  getIt.registerLazySingleton<INutritionLabelScannerService>(() => NutritionLabelScannerService.instance);
  getIt.registerLazySingleton<NutritionLabelScannerService>(() => NutritionLabelScannerService.instance);
  getIt.registerFactoryParam<GeminiVisionService, String, String?>(
    (apiKey, modelName) => GeminiVisionService(
      apiKey: apiKey,
      modelName: modelName ?? GeminiVisionService.defaultModel,
    ),
  );

  // Background Workers & System Tasks
  getIt.registerLazySingleton<AnalysisQueueService>(() => AnalysisQueueService.instance);
  getIt.registerLazySingleton<BackupService>(() => BackupService.instance);
  getIt.registerLazySingleton<HomeWidgetService>(() => HomeWidgetService.instance);
  getIt.registerLazySingleton<IClinicalExcelExportService>(() => ClinicalExcelExportService.instance);
  getIt.registerLazySingleton<ClinicalExcelExportService>(() => ClinicalExcelExportService.instance);
  getIt.registerLazySingleton<INutritionalRecommendationService>(() => NutritionalRecommendationService.instance);
  getIt.registerLazySingleton<NutritionalRecommendationService>(() => NutritionalRecommendationService.instance);

  // App Update & Installation Services
  getIt.registerLazySingleton<IAppUpdateService>(() => AppUpdateService.instance);
  getIt.registerLazySingleton<AppUpdateService>(() => AppUpdateService.instance);
  getIt.registerLazySingleton<IAppInstallerService>(() => AppInstallerService.instance);
  getIt.registerLazySingleton<AppInstallerService>(() => AppInstallerService.instance);

  // State Management Controllers
  getIt.registerLazySingleton<SettingsController>(() => SettingsController.instance);
  getIt.registerLazySingleton<MealController>(() => MealController.instance);
  getIt.registerLazySingleton<FastingController>(() => FastingController.instance);
}

/// Resets the service locator, primarily used during test teardown.
Future<void> resetServiceLocator() async {
  await getIt.reset();
}

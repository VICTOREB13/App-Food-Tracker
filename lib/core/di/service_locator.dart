import 'package:get_it/get_it.dart';

import 'package:food_tracker/features/biometrics_weight/biometrics_weight.dart';
import 'package:food_tracker/features/fasting_tracker/fasting_tracker.dart';
import 'package:food_tracker/features/dashboard/dashboard.dart';
import 'package:food_tracker/features/food_entry/food_entry.dart';
import 'package:food_tracker/features/settings_profile/settings_profile.dart';
import 'package:food_tracker/features/food_entry/services/analysis_queue_service.dart';
import 'package:food_tracker/features/data_backup/services/backup_service.dart';
import 'package:food_tracker/features/food_entry/services/barcode_lookup_service.dart';
import 'package:food_tracker/core/database/daos/dishware_dao.dart';
import 'package:food_tracker/core/database/daos/fasting_dao.dart';
import 'package:food_tracker/core/database/daos/meal_template_dao.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'package:food_tracker/core/services/ai/gemini_model_service.dart';
import 'package:food_tracker/core/services/ai/gemini_vision_service.dart';
import 'package:food_tracker/core/services/ai/gemini_rest_client.dart';
import 'package:food_tracker/core/services/ai/decision_gate_service.dart';
import 'package:food_tracker/core/services/ai/gemini_cache_service.dart';
import 'package:food_tracker/core/interfaces/decision_gate_service_interface.dart';
import 'package:food_tracker/features/food_entry/services/image_processing_service.dart';
import 'package:food_tracker/core/services/nutrition/open_food_facts_service.dart';
import 'package:food_tracker/core/services/storage/secure_storage_service.dart';
import 'package:food_tracker/core/services/theme/theme_manager.dart';
import 'package:food_tracker/core/services/nutrition/usda_food_data_service.dart';
import '../interfaces/daos_interfaces.dart';
import '../interfaces/database_service_interface.dart';
import '../interfaces/image_processing_service_interface.dart';
import '../interfaces/offline_food_estimator_service_interface.dart';
import '../interfaces/nutrition_label_scanner_service_interface.dart';
import '../interfaces/clinical_excel_export_service_interface.dart';
import '../interfaces/clinical_pdf_export_service_interface.dart';
import '../interfaces/vision_model_provider_interface.dart';
import '../interfaces/nutritional_recommendation_service_interface.dart';
import 'package:food_tracker/features/food_entry/services/offline_food_estimator_service.dart';
import 'package:food_tracker/core/services/nutrition/nutrition_label_scanner_service.dart';
import 'package:food_tracker/core/services/export/clinical_excel_export_service.dart';
import 'package:food_tracker/core/services/export/clinical_pdf_export_service.dart';
import 'package:food_tracker/features/dashboard/services/nutritional_recommendation_service.dart';
import 'package:food_tracker/core/services/platform/home_widget_service.dart';
import '../interfaces/app_update_service_interface.dart';
import '../interfaces/app_installer_service_interface.dart';
import 'package:food_tracker/core/services/platform/app_update_service.dart';
import 'package:food_tracker/core/services/platform/app_installer_service.dart';
import '../interfaces/notification_service_interface.dart';
import 'package:food_tracker/core/services/platform/notification_service.dart';
import '../ports/database_port.dart';
import '../ports/ai_vision_port.dart';
import '../ports/nutrition_catalog_port.dart';
import '../ports/secure_storage_port.dart';
import '../ports/app_widget_sync_port.dart';
import '../adapters/sqflite_database_adapter.dart';
import '../adapters/gemini_ai_vision_adapter.dart';
import '../adapters/nutrition_catalog_adapter.dart';
import '../adapters/encrypted_storage_adapter.dart';
import '../adapters/home_widget_sync_adapter.dart';

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
  final restClient = GeminiRestClient.instance;
  getIt.registerLazySingleton<GeminiRestClient>(() => restClient);
  getIt.registerLazySingleton<IDecisionGateService>(() => DecisionGateService.instance);
  getIt.registerLazySingleton<DecisionGateService>(() => DecisionGateService.instance);
  getIt.registerLazySingleton<GeminiCacheService>(() => GeminiCacheService.instance);
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
  getIt.registerFactoryParam<IVisionModelProvider, String, String?>(
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
  getIt.registerLazySingleton<IClinicalPdfExportService>(() => ClinicalPdfExportService.instance);
  getIt.registerLazySingleton<ClinicalPdfExportService>(() => ClinicalPdfExportService.instance);
  getIt.registerLazySingleton<INutritionalRecommendationService>(() => NutritionalRecommendationService.instance);
  getIt.registerLazySingleton<NutritionalRecommendationService>(() => NutritionalRecommendationService.instance);

  // App Update & Installation Services
  getIt.registerLazySingleton<IAppUpdateService>(() => AppUpdateService.instance);
  getIt.registerLazySingleton<AppUpdateService>(() => AppUpdateService.instance);
  getIt.registerLazySingleton<IAppInstallerService>(() => AppInstallerService.instance);
  getIt.registerLazySingleton<AppInstallerService>(() => AppInstallerService.instance);
  getIt.registerLazySingleton<INotificationService>(() => NotificationService.instance);
  getIt.registerLazySingleton<NotificationService>(() => NotificationService.instance);

  // State Management Controllers
  getIt.registerLazySingleton<SettingsProfileController>(() => SettingsProfileController.instance);
  getIt.registerLazySingleton<MealController>(() => MealController.instance);
  getIt.registerLazySingleton<FoodEntryController>(() => FoodEntryController.instance);
  getIt.registerLazySingleton<FastingTrackerController>(() => FastingTrackerController.instance);
  getIt.registerLazySingleton<BiometricsWeightController>(() => BiometricsWeightController.instance);
  getIt.registerLazySingleton<DashboardController>(() => DashboardController.instance);

  // Hexagonal Architecture Ports & Adapters
  final databaseAdapter = SqfliteDatabaseAdapter(databaseService: dbService);
  getIt.registerLazySingleton<IDatabasePort>(() => databaseAdapter);
  getIt.registerLazySingleton<SqfliteDatabaseAdapter>(() => databaseAdapter);

  final secureStorageAdapter = EncryptedStorageAdapter(service: SecureStorageService.instance);
  getIt.registerLazySingleton<ISecureStoragePort>(() => secureStorageAdapter);
  getIt.registerLazySingleton<EncryptedStorageAdapter>(() => secureStorageAdapter);

  final aiVisionAdapter = GeminiAiVisionAdapter(storage: SecureStorageService.instance);
  getIt.registerLazySingleton<IAiVisionPort>(() => aiVisionAdapter);
  getIt.registerLazySingleton<GeminiAiVisionAdapter>(() => aiVisionAdapter);

  final nutritionCatalogAdapter = NutritionCatalogAdapter(
    barcodeLookupService: BarcodeLookupService.instance,
    usdaService: UsdaFoodDataService.instance,
    offService: OpenFoodFactsService.instance,
  );
  getIt.registerLazySingleton<INutritionCatalogPort>(() => nutritionCatalogAdapter);
  getIt.registerLazySingleton<NutritionCatalogAdapter>(() => nutritionCatalogAdapter);

  final appWidgetSyncAdapter = HomeWidgetSyncAdapter(service: HomeWidgetService.instance);
  getIt.registerLazySingleton<IAppWidgetSyncPort>(() => appWidgetSyncAdapter);
  getIt.registerLazySingleton<HomeWidgetSyncAdapter>(() => appWidgetSyncAdapter);
}

/// Resets the service locator, primarily used during test teardown.
Future<void> resetServiceLocator() async {
  await getIt.reset();
}

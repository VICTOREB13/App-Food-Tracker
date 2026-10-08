import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../controllers/meal_controller.dart';
import '../models/analysis_task.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import 'database_service.dart';
import 'gemini_vision_service.dart';
import 'image_processing_service.dart';
import 'secure_storage_service.dart';
import '../widgets/meal_detail/meal_analysis_pacing.dart';

export '../models/analysis_task.dart';

/// Background task orchestrator managing meal photo optimization, AI analysis, and retries.
class AnalysisQueueService extends ChangeNotifier {
  static final AnalysisQueueService instance = AnalysisQueueService._();
  AnalysisQueueService._();

  final List<AnalysisTask> _tasks = [];
  bool _isWorkerRunning = false;

  List<AnalysisTask> get tasks => List.unmodifiable(_tasks);
  List<AnalysisTask> get activeTasks => _tasks.where((t) => t.isPending).toList();
  List<AnalysisTask> get failedTasks => _tasks.where((t) => t.status == AnalysisStatus.failed).toList();
  List<AnalysisTask> get completedTasks => _tasks.where((t) => t.status == AnalysisStatus.completed).toList();
  List<AnalysisTask> get visibleTasks => _tasks
      .where((t) => t.isPending || t.status == AnalysisStatus.failed || t.status == AnalysisStatus.completed)
      .toList();

  AnalysisTask? get currentActiveTask =>
      _tasks.cast<AnalysisTask?>().firstWhere((t) => t != null && t.isPending, orElse: () => null);
  AnalysisTask? get latestCompletedTask =>
      _tasks.cast<AnalysisTask?>().firstWhere((t) => t != null && t.status == AnalysisStatus.completed, orElse: () => null);
  AnalysisTask? get latestFailedTask =>
      _tasks.cast<AnalysisTask?>().firstWhere((t) => t != null && t.status == AnalysisStatus.failed, orElse: () => null);

  Future<void> init() async {
    try {
      final db = await DatabaseService.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS analysis_queue (
          id TEXT PRIMARY KEY, image_path TEXT NOT NULL, meal_type TEXT NOT NULL,
          date TEXT NOT NULL, status TEXT NOT NULL, progress REAL NOT NULL DEFAULT 0.0,
          stage TEXT NOT NULL DEFAULT 'En cola', error TEXT, result_meal_id TEXT, created_at TEXT NOT NULL
        )
      ''');

      await db.delete('analysis_queue', where: 'status = ?', whereArgs: ['completed']);
      final rows = await db.query('analysis_queue', orderBy: 'created_at DESC', limit: 20);
      _tasks.clear();
      for (final r in rows) {
        final mealId = r['result_meal_id'] as String?;
        final meal = mealId != null ? await DatabaseService.instance.getMealById(mealId) : null;
        final task = AnalysisTask.fromDbMap(r, resultMeal: meal);

        if (task.isPending) {
          final existing = meal ??
              await DatabaseService.instance.getMealById(task.id) ??
              await DatabaseService.instance.getMealByImagePath(task.imagePath);
          if (existing != null) {
            task.resultMeal = existing;
            task.status = AnalysisStatus.completed;
            task.progress = 1.0;
            task.stage = '¡Comida analizada y registrada!';
          } else {
            final fileExists = task.imagePath.isNotEmpty && File(task.imagePath).existsSync();
            task.status = fileExists ? AnalysisStatus.queued : AnalysisStatus.failed;
          }
        }
        _tasks.add(task);
      }
      notifyListeners();
      if (_tasks.any((t) => t.status == AnalysisStatus.queued)) _triggerWorker();
    } catch (e) {
      debugPrint('AnalysisQueueService: Error initializing queue table: $e');
    }
  }

  Future<AnalysisTask> enqueueMealAnalysis({
    required Uint8List rawImageBytes,
    required String mealType,
    required DateTime date,
    String? userContext,
    double? dishwareDiameterCm,
    List<FoodItem>? initialItems,
    String? currentDishName,
  }) async {
    final task = AnalysisTask(
      rawImageBytes: rawImageBytes,
      dishwareDiameterCm: dishwareDiameterCm,
      mealType: mealType,
      date: date,
      userContext: userContext,
      status: AnalysisStatus.queued,
      progress: 0.05,
      stage: 'Optimizando foto...',
    );

    _tasks.insert(0, task);
    await _persistTaskToDb(task);
    notifyListeners();
    _triggerWorker();
    return task;
  }

  void _triggerWorker() {
    if (_isWorkerRunning) return;
    _runWorkerLoop();
  }

  Future<void> _runWorkerLoop() async {
    _isWorkerRunning = true;
    try {
      while (true) {
        final pending = _tasks.cast<AnalysisTask?>().lastWhere(
              (t) => t != null && t.status == AnalysisStatus.queued,
              orElse: () => null,
            );
        if (pending == null) break;
        await _processTask(pending);
      }
    } finally {
      _isWorkerRunning = false;
    }
  }

  Future<void> _updateProgress(AnalysisTask task, double progress, String stage) async {
    task.progress = progress;
    task.stage = stage;
    notifyListeners();
    await _persistTaskToDb(task);
  }

  Future<void> _processTask(AnalysisTask task) async {
    task.status = AnalysisStatus.processing;

    try {
      if (task.imagePath.isEmpty && task.rawImageBytes != null) {
        await _updateProgress(task, 0.20, 'Comprimiendo imagen...');
        final compressed = await ImageProcessingService.instance.compressAndResizeAsync(task.rawImageBytes!);

        await _updateProgress(task, 0.35, 'Guardando foto...');
        final savedPath = await ImageProcessingService.instance.saveMealImage(
          compressed,
          mealType: task.mealType,
          date: task.date,
        );
        task.imagePath = savedPath;
        task.rawImageBytes = null;
        await _persistTaskToDb(task);
      }

      final apiKey = await SecureStorageService.instance.getGeminiApiKey();
      if (apiKey == null || apiKey.trim().isEmpty) {
        throw Exception('Configura tu API Key de Gemini en Ajustes.');
      }

      final selectedModel = await SecureStorageService.instance.getSelectedGeminiModel();
      final masterPrompt = await SecureStorageService.instance.getMasterPrompt();
      final effectiveModel = selectedModel ?? GeminiVisionService.defaultModel;

      await _updateProgress(task, 0.45, 'Consultando $effectiveModel...');

      final file = File(task.imagePath);
      if (!await file.exists()) throw Exception('No se encontró el archivo de imagen guardado.');
      final bytes = await file.readAsBytes();

      final gemini = GeminiVisionService(
        apiKey: apiKey,
        modelName: effectiveModel,
        masterPrompt: masterPrompt,
      );

      double? diameter = task.dishwareDiameterCm;
      String? pantryCtx;
      try {
        diameter ??= (await DatabaseService.instance.dishwareDao.getDefaultDishware())?.diameterCm;
        pantryCtx = await DatabaseService.instance.pantryDao.getPantryPromptContext();
      } catch (_) {}

      Timer? pacingTimer;
      MealAnalysisResult analysis;
      try {
        pacingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
          if (task.status == AnalysisStatus.processing && task.progress < 0.90) {
            task.progress = MealAnalysisPacing.nextProgress(task.progress).clamp(0.45, 0.90);
            notifyListeners();
          }
        });

        analysis = await gemini.analyzeMealPhoto(
          rawImageBytes: bytes,
          userContext: task.userContext,
          dishwareDiameterCm: diameter,
          pantryContext: (pantryCtx != null && pantryCtx.isNotEmpty) ? pantryCtx : null,
        );
      } finally {
        pacingTimer?.cancel();
      }

      await _updateProgress(task, 0.90, 'Calculando macronutrientes y guardando en SQLite...');

      final ingredientsSummary = analysis.items.isNotEmpty
          ? 'Ingredientes: ${analysis.items.map((e) => '${e.name} (${e.estimatedGrams.toStringAsFixed(0)}g)').join(', ')}'
          : null;

      final existingMeal = await DatabaseService.instance.getMealByImagePath(task.imagePath);
      final meal = Meal(
        id: task.resultMeal?.id ?? existingMeal?.id ?? task.id,
        name: analysis.dishName, mealType: task.mealType, date: task.date,
        imagePath: task.imagePath, calories: analysis.totalCalories,
        protein: analysis.totalProtein, carbs: analysis.totalCarbs, fat: analysis.totalFat,
        notes: ingredientsSummary, items: analysis.items, aiBreakdownJson: analysis.rawJson,
      ).recalculateFromItems(analysis.items);

      await DatabaseService.instance.upsertMeal(meal);
      await MealController.instance.loadMeals();

      task.status = AnalysisStatus.completed;
      task.resultMeal = meal;
      await _updateProgress(task, 1.0, '¡Comida analizada y registrada!');
    } catch (e) {
      task.status = AnalysisStatus.failed;
      task.error = GeminiVisionService.userFriendlyErrorMessage(e);
      await _updateProgress(task, task.progress, 'Error al analizar la comida');
    }
  }

  Meal? createManualMealFromFailedTask(String taskId) {
    final task = _tasks.cast<AnalysisTask?>().firstWhere((t) => t != null && t.id == taskId, orElse: () => null);
    if (task == null || task.imagePath.isEmpty) return null;
    return Meal(
      id: task.id, name: 'Comida sin clasificar', mealType: task.mealType,
      date: task.date, imagePath: task.imagePath, notes: task.userContext,
    );
  }

  Future<void> retryTask(String taskId) async {
    final task = _tasks.cast<AnalysisTask?>().firstWhere((t) => t != null && t.id == taskId, orElse: () => null);
    if (task == null) return;

    if ((task.imagePath.isEmpty || !File(task.imagePath).existsSync()) && task.rawImageBytes == null) {
      task.status = AnalysisStatus.failed;
      task.error = 'No se encontró el archivo de imagen para reintentar.';
      notifyListeners();
      await _persistTaskToDb(task);
      return;
    }

    task.status = AnalysisStatus.queued;
    task.error = null;
    await _updateProgress(task, 0.05, 'En cola para reintento...');
    _triggerWorker();
  }

  Future<void> _persistTaskToDb(AnalysisTask task) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.insert('analysis_queue', task.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<void> dismissTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    try {
      final db = await DatabaseService.instance.database;
      await db.delete('analysis_queue', where: 'id = ?', whereArgs: [taskId]);
    } catch (_) {}
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere((t) => t.status == AnalysisStatus.completed);
    notifyListeners();
    try {
      final db = await DatabaseService.instance.database;
      await db.delete('analysis_queue', where: 'status = ?', whereArgs: ['completed']);
    } catch (_) {}
  }

  @visibleForTesting
  void addTaskForTesting(AnalysisTask task) { _tasks.add(task); notifyListeners(); }

  @visibleForTesting
  void clearAllTasksForTesting() { _tasks.clear(); notifyListeners(); }
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../controllers/meal_controller.dart';
import '../models/food_item.dart';
import '../models/meal.dart';
import 'database_service.dart';
import 'gemini_vision_service.dart';
import 'image_processing_service.dart';
import 'secure_storage_service.dart';

enum AnalysisStatus { queued, processing, completed, failed }

class AnalysisTask {
  final String id;
  final String imagePath;
  final String mealType;
  final DateTime date;
  final String? userContext;
  AnalysisStatus status;
  double progress;
  String stage;
  String? error;
  Meal? resultMeal;
  final DateTime createdAt;

  AnalysisTask({
    String? id,
    required this.imagePath,
    required this.mealType,
    required this.date,
    this.userContext,
    this.status = AnalysisStatus.queued,
    this.progress = 0.05,
    this.stage = 'En cola de análisis...',
    this.error,
    this.resultMeal,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isPending =>
      status == AnalysisStatus.queued || status == AnalysisStatus.processing;
}

class AnalysisQueueService extends ChangeNotifier {
  static final AnalysisQueueService instance = AnalysisQueueService._();
  AnalysisQueueService._();

  final List<AnalysisTask> _tasks = [];
  bool _isWorkerRunning = false;

  List<AnalysisTask> get tasks => List.unmodifiable(_tasks);
  List<AnalysisTask> get activeTasks =>
      _tasks.where((t) => t.isPending).toList();

  AnalysisTask? get currentActiveTask =>
      _tasks.cast<AnalysisTask?>().firstWhere(
            (t) => t != null && t.isPending,
            orElse: () => null,
          );

  AnalysisTask? get latestCompletedTask =>
      _tasks.cast<AnalysisTask?>().lastWhere(
            (t) => t != null && t.status == AnalysisStatus.completed,
            orElse: () => null,
          );

  Future<void> init() async {
    try {
      final db = await DatabaseService.instance.database;
      await db.execute('''
        CREATE TABLE IF NOT EXISTS analysis_queue (
          id TEXT PRIMARY KEY,
          image_path TEXT NOT NULL,
          meal_type TEXT NOT NULL,
          date TEXT NOT NULL,
          status TEXT NOT NULL,
          progress REAL NOT NULL DEFAULT 0.0,
          stage TEXT NOT NULL DEFAULT 'En cola',
          error TEXT,
          result_meal_id TEXT,
          created_at TEXT NOT NULL
        )
      ''');

      final rows = await db.query('analysis_queue', orderBy: 'created_at DESC', limit: 8);
      _tasks.clear();
      for (final r in rows) {
        final status = AnalysisStatus.values.firstWhere(
          (s) => s.name == (r['status'] as String? ?? ''),
          orElse: () => AnalysisStatus.failed,
        );
        Meal? meal;
        final mealId = r['result_meal_id'] as String?;
        if (mealId != null) {
          meal = await DatabaseService.instance.getMealById(mealId);
        }
        final task = AnalysisTask(
          id: r['id'] as String,
          imagePath: r['image_path'] as String,
          mealType: r['meal_type'] as String,
          date: DateTime.tryParse(r['date'] as String? ?? '') ?? DateTime.now(),
          status: status,
          progress: (r['progress'] as num?)?.toDouble() ?? 0.0,
          stage: r['stage'] as String? ?? '',
          error: r['error'] as String?,
          resultMeal: meal,
          createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
        );
        if (task.status == AnalysisStatus.processing || task.status == AnalysisStatus.queued) {
          task.status = File(task.imagePath).existsSync() ? AnalysisStatus.queued : AnalysisStatus.failed;
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
    List<FoodItem>? initialItems,
    String? currentDishName,
  }) async {
    final compressed = ImageProcessingService.instance.compressAndResize(rawImageBytes);
    final savedPath = await ImageProcessingService.instance.saveMealImage(
      compressed,
      mealType: mealType,
      date: date,
    );

    final task = AnalysisTask(
      imagePath: savedPath,
      mealType: mealType,
      date: date,
      userContext: userContext,
      status: AnalysisStatus.queued,
      progress: 0.10,
      stage: 'Imagen guardada. Iniciando análisis...',
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
        final pending = _tasks.cast<AnalysisTask?>().firstWhere(
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

  Future<void> _processTask(AnalysisTask task) async {
    task.status = AnalysisStatus.processing;
    task.progress = 0.20;
    task.stage = 'Optimizando imagen y cubicaje...';
    notifyListeners();
    await _persistTaskToDb(task);

    try {
      final apiKey = await SecureStorageService.instance.getGeminiApiKey();
      if (apiKey == null || apiKey.trim().isEmpty) {
        throw Exception('Configura tu API Key de Gemini en Ajustes.');
      }

      final selectedModel = await SecureStorageService.instance.getSelectedGeminiModel();
      final masterPrompt = await SecureStorageService.instance.getMasterPrompt();
      final effectiveModel = selectedModel ?? GeminiVisionService.defaultModel;

      task.progress = 0.40;
      task.stage = 'Consultando $effectiveModel...';
      notifyListeners();
      await _persistTaskToDb(task);

      final file = File(task.imagePath);
      if (!await file.exists()) {
        throw Exception('No se encontró el archivo de imagen guardado.');
      }
      final bytes = await file.readAsBytes();

      final gemini = GeminiVisionService(
        apiKey: apiKey,
        modelName: effectiveModel,
        masterPrompt: masterPrompt,
      );

      task.progress = 0.65;
      task.stage = 'Estimando volumen y desglosando componentes...';
      notifyListeners();
      await _persistTaskToDb(task);

      final analysis = await gemini.analyzeMealPhoto(
        rawImageBytes: bytes,
        userContext: task.userContext,
      );

      task.progress = 0.88;
      task.stage = 'Calculando macronutrientes y guardando en SQLite...';
      notifyListeners();
      await _persistTaskToDb(task);

      final ingredientsSummary = analysis.items.isNotEmpty
          ? 'Ingredientes: ${analysis.items.map((e) => '${e.name} (${e.estimatedGrams.toStringAsFixed(0)}g)').join(', ')}'
          : null;

      final meal = Meal(
        name: analysis.dishName,
        mealType: task.mealType,
        date: task.date,
        imagePath: task.imagePath,
        calories: analysis.totalCalories,
        protein: analysis.totalProtein,
        carbs: analysis.totalCarbs,
        fat: analysis.totalFat,
        notes: ingredientsSummary,
        items: analysis.items,
        aiBreakdownJson: analysis.rawJson,
      ).recalculateFromItems(analysis.items);

      await DatabaseService.instance.upsertMeal(meal);
      await MealController.instance.loadMeals();

      task.status = AnalysisStatus.completed;
      task.progress = 1.0;
      task.stage = '¡Comida analizada y registrada!';
      task.resultMeal = meal;
      notifyListeners();
      await _persistTaskToDb(task);
    } catch (e) {
      task.status = AnalysisStatus.failed;
      task.error = GeminiVisionService.userFriendlyErrorMessage(e);
      task.stage = 'Error al analizar la comida';
      notifyListeners();
      await _persistTaskToDb(task);
    }
  }

  Future<void> _persistTaskToDb(AnalysisTask task) async {
    try {
      final db = await DatabaseService.instance.database;
      await db.insert(
        'analysis_queue',
        {
          'id': task.id,
          'image_path': task.imagePath,
          'meal_type': task.mealType,
          'date': task.date.toIso8601String(),
          'status': task.status.name,
          'progress': task.progress,
          'stage': task.stage,
          'error': task.error,
          'result_meal_id': task.resultMeal?.id,
          'created_at': task.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
  void addTaskForTesting(AnalysisTask task) {
    _tasks.add(task);
    notifyListeners();
  }

  @visibleForTesting
  void clearAllTasksForTesting() {
    _tasks.clear();
    notifyListeners();
  }
}

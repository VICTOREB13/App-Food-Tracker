import 'package:food_tracker/core/adapters/sqflite_database_adapter.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:food_tracker/core/di/service_locator.dart';
import 'package:food_tracker/core/ports/database_port.dart';
import 'package:food_tracker/features/food_entry/models/meal.dart';
import 'package:food_tracker/features/pantry_inventory/models/pantry_item.dart';
import 'package:food_tracker/features/settings_profile/models/user_profile.dart';
import 'package:food_tracker/features/biometrics_weight/models/weight_log.dart';
import 'package:food_tracker/features/data_backup/services/backup_normalizer.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'data_backup.model.dart';

/// State management controller for the Data Backup vertical slice.
/// Orchestrates SAF file picking, Isolate normalization (Isolate.run), repair
/// of truncated JSON, and batch transaction via IDatabasePort (< 300 LoC budget).
class DataBackupController extends ChangeNotifier {
  static DataBackupController instance = DataBackupController();

  final IDatabasePort _db;
  BackupProgress _state = BackupProgress.initial;

  DataBackupController({IDatabasePort? databasePort})
      : _db = databasePort ??
            (getIt.isRegistered<IDatabasePort>() ? getIt<IDatabasePort>() : SqfliteDatabaseAdapter(databaseService: DatabaseService.instance));

  @visibleForTesting
  static void setMockInstance(DataBackupController mock) => instance = mock;

  @visibleForTesting
  static void resetInstance() => instance = DataBackupController();

  BackupProgress get state => _state;
  BackupStatus get status => _state.status;
  bool get isBusy => _state.isBusy;
  bool get isExporting => _state.isExporting;
  bool get isRestoring => _state.isRestoring;
  File? get exportedFile => _state.exportedFile;
  File? get selectedFile => _state.selectedFile;
  BackupMetadata? get previewMetadata => _state.metadata;
  Map<String, int>? get restoreResult => _state.restoreResult;
  String? get errorMessage => _state.errorMessage;

  /// Exposes pure JSON repair algorithm for truncated strings.
  static String repairTruncatedJson(String jsonString) =>
      BackupNormalizer.tryRepairTruncatedJson(jsonString);

  /// Resolves the dedicated local directory for JSON backups.
  Future<Directory> resolveBackupDirectory({String? customDirectoryPath}) async {
    if (customDirectoryPath != null) {
      final dir = Directory(customDirectoryPath);
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final dir = Directory(p.join(downloadDir.path, 'FoodTrackerBackups'));
          if (!await dir.exists()) await dir.create(recursive: true);
          return dir;
        }
      } catch (_) {}
    }

    final docs = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(docs.path, 'backups'));
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    return backupDir;
  }

  /// Exports full database snapshot to an indented JSON string.
  Future<String> exportToJsonString() async {
    final meals = await _db.getAllMeals();
    final pantry = await _db.getPantryItems();
    final weightLogs = await _db.getAllWeightLogs();
    final userProfile = await _db.getUserProfile();

    final exportData = {
      'app': 'Victor Engineer Food Tracker',
      'version': '2.0.0',
      'schema_version': 2,
      'export_date': DateTime.now().toIso8601String(),
      'meals_count': meals.length,
      'pantry_count': pantry.length,
      'weight_logs_count': weightLogs.length,
      'has_user_profile': userProfile != null,
      'meals': meals.map((m) => m.toJson()).toList(),
      'pantry_items': pantry.map((p) => p.toJson()).toList(),
      'weight_logs': weightLogs.map((w) => w.toJson()).toList(),
      'user_profile': userProfile?.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Exports full database snapshot directly into a physical `.json` file.
  Future<File> exportBackup({String? customDirectoryPath}) async {
    _state = _state.copyWith(
      status: BackupStatus.exporting,
      operation: BackupOperationType.export,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final jsonContent = await exportToJsonString();
      final directory = await resolveBackupDirectory(customDirectoryPath: customDirectoryPath);
      final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File(p.join(directory.path, 'food_tracker_backup_$dateStamp.json'));
      await file.writeAsString(jsonContent, flush: true);

      final metadata = await inspectBackupFile(file);
      _state = _state.copyWith(
        status: BackupStatus.success,
        exportedFile: file,
        metadata: metadata,
      );
      notifyListeners();
      return file;
    } catch (e) {
      _state = _state.copyWith(status: BackupStatus.error, errorMessage: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  /// Inspects a backup file in Isolate and updates preview metadata.
  Future<BackupMetadata> inspectBackupFile(File file) async {
    final content = await file.readAsString();
    final normalized = await Isolate.run(() => BackupNormalizer.decodeAndNormalize(content));

    final metadata = BackupMetadata(
      path: file.path,
      filename: p.basename(file.path),
      sizeBytes: await file.length(),
      exportDate: normalized['export_date'] as String?,
      mealsCount: (normalized['meals'] as List?)?.length ?? 0,
      pantryCount: (normalized['pantry_items'] as List?)?.length ?? 0,
      weightLogsCount: (normalized['weight_logs'] as List?)?.length ?? 0,
      hasUserProfile: normalized['user_profile'] != null,
    );

    _state = _state.copyWith(selectedFile: file, metadata: metadata);
    notifyListeners();
    return metadata;
  }

  /// Picks a backup file using the system file picker and previews it.
  Future<File?> pickBackupFile({Future<File?> Function()? customPicker}) async {
    _state = _state.copyWith(status: BackupStatus.picking, errorMessage: null);
    notifyListeners();

    try {
      final File? file;
      if (customPicker != null) {
        file = await customPicker();
      } else {
        final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
        file = (picked != null && picked.path != null && picked.path!.isNotEmpty)
            ? File(picked.path!)
            : null;
      }

      if (file != null && await file.exists()) {
        await inspectBackupFile(file);
        _state = _state.copyWith(status: BackupStatus.idle);
        notifyListeners();
        return file;
      }
      _state = _state.copyWith(status: BackupStatus.idle);
      notifyListeners();
      return null;
    } catch (e) {
      _state = _state.copyWith(status: BackupStatus.error, errorMessage: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  /// Restores database content from file or raw JSON with SQLite transaction guarantees.
  Future<Map<String, int>> restoreBackup({File? file, String? jsonContent}) async {
    _state = _state.copyWith(
      status: BackupStatus.restoring,
      operation: BackupOperationType.restore,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final raw = file != null ? await file.readAsString() : (jsonContent ?? '');
      final normalized = await Isolate.run(() => BackupNormalizer.decodeAndNormalize(raw));
      final db = await _db.database;
      int importedMeals = 0, importedPantry = 0, importedWeightLogs = 0, importedUserProfile = 0;

      await db.transaction((txn) async {
        final batch = txn.batch();
        final meals = normalized['meals'];
        if (meals is List) {
          for (final item in meals.whereType<Map>()) {
            final meal = Meal.fromJson(Map<String, dynamic>.from(item));
            batch.insert('meals', meal.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
            importedMeals++;
          }
        }
        final pantry = normalized['pantry_items'];
        if (pantry is List) {
          for (final item in pantry.whereType<Map>()) {
            final pItem = PantryItem.fromJson(Map<String, dynamic>.from(item));
            batch.insert('pantry_items', pItem.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
            importedPantry++;
          }
        }
        final weightLogs = normalized['weight_logs'];
        if (weightLogs is List) {
          for (final item in weightLogs.whereType<Map>()) {
            final wLog = WeightLog.fromJson(Map<String, dynamic>.from(item));
            batch.insert('weight_logs', wLog.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
            importedWeightLogs++;
          }
        }
        final userProfile = normalized['user_profile'];
        if (userProfile is Map) {
          final profile = UserProfile.fromJson(Map<String, dynamic>.from(userProfile));
          batch.insert('user_profile', profile.toSqliteMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          importedUserProfile = 1;
        }
        await batch.commit(noResult: true);
      });

      final result = {
        'imported_meals': importedMeals,
        'imported_pantry': importedPantry,
        'imported_weight_logs': importedWeightLogs,
        'imported_user_profile': importedUserProfile,
      };
      _state = _state.copyWith(status: BackupStatus.success, restoreResult: result);
      notifyListeners();
      return result;
    } catch (e) {
      _state = _state.copyWith(status: BackupStatus.error, errorMessage: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  /// Lists all `.json` backup files discovered in the default backup locations, sorted newest first.
  Future<List<File>> listAvailableBackups({String? customDirectoryPath}) async {
    final results = <File>[];
    try {
      final dir = await resolveBackupDirectory(customDirectoryPath: customDirectoryPath);
      if (await dir.exists()) {
        results.addAll(dir.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.json')));
      }
      if (customDirectoryPath == null) {
        final docs = await getApplicationDocumentsDirectory();
        if (await docs.exists()) {
          for (final f in docs.listSync().whereType<File>()) {
            if (f.path.toLowerCase().endsWith('.json') && !results.any((r) => r.path == f.path)) {
              results.add(f);
            }
          }
        }
      }
    } catch (_) {}

    results.sort((a, b) {
      try {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      } catch (_) {
        return 0;
      }
    });
    return results;
  }

  /// Resets controller state to initial idle sentinel.
  void resetState() {
    _state = BackupProgress.initial;
    notifyListeners();
  }
}

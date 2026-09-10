import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:food_tracker/models/meal.dart';
import 'package:food_tracker/services/database_service.dart';
import 'package:food_tracker/services/image_processing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempTestDir;
  late Database db;

  setUp(() async {
    tempTestDir = await Directory.systemTemp.createTemp('food_tracker_img_test_');

    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode = WAL;');
          await db.execute('PRAGMA synchronous = NORMAL;');
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE meals (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              meal_type TEXT NOT NULL,
              date TEXT NOT NULL,
              image_path TEXT,
              calories REAL NOT NULL,
              protein REAL NOT NULL,
              carbs REAL NOT NULL,
              fat REAL NOT NULL,
              notes TEXT,
              ai_breakdown_json TEXT
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_meals_date ON meals(date);');
        },
      ),
    );
    DatabaseService.instance.setDatabaseForTesting(db);
  });

  tearDown(() async {
    await db.close();
    await DatabaseService.instance.closeForTesting();
    if (await tempTestDir.exists()) {
      await tempTestDir.delete(recursive: true);
    }
  });

  group('ImageProcessingService Tests', () {
    test('Android public pictures path is configured to user-visible Pictures/FoodTracker/images', () {
      expect(
        ImageProcessingService.androidPublicPicturesPath,
        equals('/storage/emulated/0/Pictures/FoodTracker/images'),
      );
    });

    test('compressAndResize reduces image exceeding maxDimension to max 1024px', () {
      final service = ImageProcessingService.instance;
      // Create a 1400x700 image
      final testImage = img.Image(width: 1400, height: 700);
      img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
      final rawJpg = Uint8List.fromList(img.encodeJpg(testImage));

      final processed = service.compressAndResize(rawJpg, targetMaxDimension: 1024);
      final decoded = img.decodeImage(processed);

      expect(decoded, isNotNull);
      expect(decoded!.width, equals(1024));
      expect(decoded.height, equals(512));
    });

    test('compressAndResize preserves dimensions when image is within maxDimension', () {
      final service = ImageProcessingService.instance;
      final testImage = img.Image(width: 400, height: 300);
      img.fill(testImage, color: img.ColorRgb8(0, 255, 0));
      final rawJpg = Uint8List.fromList(img.encodeJpg(testImage));

      final processed = service.compressAndResize(rawJpg, targetMaxDimension: 1024);
      final decoded = img.decodeImage(processed);

      expect(decoded, isNotNull);
      expect(decoded!.width, equals(400));
      expect(decoded.height, equals(300));
    });

    test('compressAndResize returns original bytes if payload is corrupted/non-image', () {
      final service = ImageProcessingService.instance;
      final corruptBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final result = service.compressAndResize(corruptBytes);
      expect(result, equals(corruptBytes));
    });

    test('MealImageFileInfo implements value equality, hashCode, and holds filePath', () {
      final date = DateTime(2026, 6, 30);
      final info1 = MealImageFileInfo(
        date: date,
        year: '2026',
        month: '06',
        day: '30',
        typeCode: 'B',
        mealType: 'Desayuno',
        index: 1,
        fileName: '2026_06_30_B_01.jpg',
        filePath: '/storage/emulated/0/Pictures/FoodTracker/images/2026_06_30_B_01.jpg',
      );

      final info2 = MealImageFileInfo(
        date: date,
        year: '2026',
        month: '06',
        day: '30',
        typeCode: 'B',
        mealType: 'Desayuno',
        index: 1,
        fileName: '2026_06_30_B_01.jpg',
        filePath: '/storage/emulated/0/Pictures/FoodTracker/images/2026_06_30_B_01.jpg',
      );

      expect(info1, equals(info2));
      expect(info1.hashCode, equals(info2.hashCode));
      expect(info1.toString(), contains('2026_06_30'));
      expect(info1.filePath, equals('/storage/emulated/0/Pictures/FoodTracker/images/2026_06_30_B_01.jpg'));
    });

    test('getMealTypeCode maps correctly for Spanish, English, letter codes, and fallbacks', () {
      // Breakfast / Desayuno -> B
      expect(ImageProcessingService.getMealTypeCode('Breakfast'), equals('B'));
      expect(ImageProcessingService.getMealTypeCode('BREAKFAST'), equals('B'));
      expect(ImageProcessingService.getMealTypeCode('Desayuno'), equals('B'));
      expect(ImageProcessingService.getMealTypeCode('desayuno continental'), equals('B'));
      expect(ImageProcessingService.getMealTypeCode('b'), equals('B'));
      expect(ImageProcessingService.getMealTypeCode('B'), equals('B'));

      // Lunch / Almuerzo -> L
      expect(ImageProcessingService.getMealTypeCode('Lunch'), equals('L'));
      expect(ImageProcessingService.getMealTypeCode('LUNCH'), equals('L'));
      expect(ImageProcessingService.getMealTypeCode('Almuerzo'), equals('L'));
      expect(ImageProcessingService.getMealTypeCode('almuerzo ejecutivo'), equals('L'));
      expect(ImageProcessingService.getMealTypeCode('comida'), equals('L'));
      expect(ImageProcessingService.getMealTypeCode('lonche'), equals('L'));
      expect(ImageProcessingService.getMealTypeCode('l'), equals('L'));
      expect(ImageProcessingService.getMealTypeCode('L'), equals('L'));

      // Dinner / Cena -> D
      expect(ImageProcessingService.getMealTypeCode('Dinner'), equals('D'));
      expect(ImageProcessingService.getMealTypeCode('DINNER'), equals('D'));
      expect(ImageProcessingService.getMealTypeCode('Cena'), equals('D'));
      expect(ImageProcessingService.getMealTypeCode('cena ligera'), equals('D'));
      expect(ImageProcessingService.getMealTypeCode('supper'), equals('D'));
      expect(ImageProcessingService.getMealTypeCode('d'), equals('D'));
      expect(ImageProcessingService.getMealTypeCode('D'), equals('D'));

      // Snack / Merienda -> S (including prompt keyword 'Snarck')
      expect(ImageProcessingService.getMealTypeCode('Snack'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('SNACK'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('Snarck'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('snarck'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('Merienda'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('merienda tarde'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('colacion'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('colación'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('tentempié'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('botana'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('piqueo'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('onces'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('aperitivo'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('s'), equals('S'));
      expect(ImageProcessingService.getMealTypeCode('S'), equals('S'));

      // Fallback / Other -> O
      expect(ImageProcessingService.getMealTypeCode('Other'), equals('O'));
      expect(ImageProcessingService.getMealTypeCode('Otro'), equals('O'));
      expect(ImageProcessingService.getMealTypeCode('o'), equals('O'));
      expect(ImageProcessingService.getMealTypeCode('O'), equals('O'));
      expect(ImageProcessingService.getMealTypeCode(null), equals('O'));
      expect(ImageProcessingService.getMealTypeCode(''), equals('O'));
      expect(ImageProcessingService.getMealTypeCode('   '), equals('O'));
      expect(ImageProcessingService.getMealTypeCode('Bebida misteriosa'), equals('O'));
    });

    test('inferMealTypeByTime returns appropriate meal type according to hour and handles midnight transition', () {
      expect(ImageProcessingService.inferMealTypeByTime(DateTime(2026, 6, 30, 8, 30)), equals('Desayuno'));
      expect(ImageProcessingService.inferMealTypeByTime(DateTime(2026, 6, 30, 13, 0)), equals('Almuerzo'));
      expect(ImageProcessingService.inferMealTypeByTime(DateTime(2026, 6, 30, 18, 15)), equals('Snack'));
      expect(ImageProcessingService.inferMealTypeByTime(DateTime(2026, 6, 30, 21, 45)), equals('Cena'));
      expect(ImageProcessingService.inferMealTypeByTime(DateTime(2026, 6, 30, 2, 0)), equals('Cena'));

      // Midnight boundary: 23:59:59 -> Cena, 00:00:01 -> Cena
      expect(ImageProcessingService.inferMealTypeByTime(DateTime(2026, 6, 30, 23, 59, 59)), equals('Cena'));
      expect(ImageProcessingService.inferMealTypeByTime(DateTime(2026, 7, 1, 0, 0, 1)), equals('Cena'));
      expect(ImageProcessingService.inferMealTypeByTime(DateTime(2026, 7, 1, 4, 59, 59)), equals('Cena'));
      expect(ImageProcessingService.inferMealTypeByTime(DateTime(2026, 7, 1, 5, 0, 0)), equals('Desayuno'));
    });

    test('normalizeFilePath handles plain file paths and file:// URI schemes', () {
      expect(
        ImageProcessingService.normalizeFilePath('/storage/emulated/0/test.jpg'),
        equals('/storage/emulated/0/test.jpg'),
      );
      final sampleFile = File(p.join(tempTestDir.path, 'norm_test.jpg'));
      final uriStr = sampleFile.uri.toString();
      expect(
        ImageProcessingService.normalizeFilePath(uriStr),
        equals(sampleFile.path),
      );
    });

    test('saveMealImage saves image with exact YYYY_MM_DD_{TYPE}_{INDEX}.jpg nomenclature', () async {
      final service = ImageProcessingService.instance;
      final testBytes = Uint8List.fromList([10, 20, 30, 40]);
      final targetSubdir = Directory(p.join(tempTestDir.path, 'custom_storage', 'images'));
      final targetDate = DateTime(2026, 6, 30, 9, 0);

      // Save first Breakfast image for 2026-06-30
      final savedPath = await service.saveMealImage(
        testBytes,
        mealType: 'Breakfast',
        date: targetDate,
        customDirectory: targetSubdir,
      );

      expect(savedPath, isNotEmpty);
      expect(p.basename(savedPath), equals('2026_06_30_B_01.jpg'));

      final savedFile = File(savedPath);
      expect(await savedFile.exists(), isTrue);
      expect(await savedFile.readAsBytes(), equals(testBytes));
    });

    test('saveMealImage automatically infers mealType by time when mealType is omitted', () async {
      final service = ImageProcessingService.instance;
      final testBytes = Uint8List.fromList([42, 43]);
      final targetSubdir = Directory(p.join(tempTestDir.path, 'inferred_storage', 'images'));

      // 08:30 AM -> Desayuno (B)
      final morningDate = DateTime(2026, 6, 30, 8, 30);
      final morningPath = await service.saveMealImage(
        testBytes,
        date: morningDate,
        customDirectory: targetSubdir,
      );
      expect(p.basename(morningPath), equals('2026_06_30_B_01.jpg'));

      // 13:30 PM -> Almuerzo (L)
      final lunchDate = DateTime(2026, 6, 30, 13, 30);
      final lunchPath = await service.saveMealImage(
        testBytes,
        date: lunchDate,
        customDirectory: targetSubdir,
      );
      expect(p.basename(lunchPath), equals('2026_06_30_L_01.jpg'));
    });

    test('saveMealImage increments index sequentially for same date and meal type', () async {
      final service = ImageProcessingService.instance;
      final testBytes = Uint8List.fromList([1, 2, 3]);
      final targetSubdir = Directory(p.join(tempTestDir.path, 'sequential_storage', 'images'));
      final targetDate = DateTime(2026, 6, 30);

      // First breakfast: 2026_06_30_B_01.jpg
      final path1 = await service.saveMealImage(
        testBytes,
        mealType: 'Desayuno',
        date: targetDate,
        customDirectory: targetSubdir,
      );
      expect(p.basename(path1), equals('2026_06_30_B_01.jpg'));

      // Second breakfast on same day: 2026_06_30_B_02.jpg
      final path2 = await service.saveMealImage(
        testBytes,
        mealType: 'Desayuno',
        date: targetDate,
        customDirectory: targetSubdir,
      );
      expect(p.basename(path2), equals('2026_06_30_B_02.jpg'));

      // Third breakfast on same day: 2026_06_30_B_03.jpg
      final path3 = await service.saveMealImage(
        testBytes,
        mealType: 'Desayuno',
        date: targetDate,
        customDirectory: targetSubdir,
      );
      expect(p.basename(path3), equals('2026_06_30_B_03.jpg'));
    });

    test('saveMealImage tracks independent indices for different meal types on same date', () async {
      final service = ImageProcessingService.instance;
      final testBytes = Uint8List.fromList([5, 6, 7]);
      final targetSubdir = Directory(p.join(tempTestDir.path, 'multi_meal_storage', 'images'));
      final targetDate = DateTime(2026, 6, 30);

      // Breakfast 01
      final b1 = await service.saveMealImage(
        testBytes,
        mealType: 'Breakfast',
        date: targetDate,
        customDirectory: targetSubdir,
      );
      expect(p.basename(b1), equals('2026_06_30_B_01.jpg'));

      // Lunch 01
      final l1 = await service.saveMealImage(
        testBytes,
        mealType: 'Lunch',
        date: targetDate,
        customDirectory: targetSubdir,
      );
      expect(p.basename(l1), equals('2026_06_30_L_01.jpg'));

      // Dinner 01
      final d1 = await service.saveMealImage(
        testBytes,
        mealType: 'Dinner',
        date: targetDate,
        customDirectory: targetSubdir,
      );
      expect(p.basename(d1), equals('2026_06_30_D_01.jpg'));

      // Snack 01
      final s1 = await service.saveMealImage(
        testBytes,
        mealType: 'Snack',
        date: targetDate,
        customDirectory: targetSubdir,
      );
      expect(p.basename(s1), equals('2026_06_30_S_01.jpg'));

      // Second Lunch on same day: 2026_06_30_L_02.jpg
      final l2 = await service.saveMealImage(
        testBytes,
        mealType: 'Almuerzo',
        date: targetDate,
        customDirectory: targetSubdir,
      );
      expect(p.basename(l2), equals('2026_06_30_L_02.jpg'));
    });

    test('saveMealImage respects explicitIndex and avoids collisions safely', () async {
      final service = ImageProcessingService.instance;
      final testBytes = Uint8List.fromList([8, 9, 10]);
      final targetSubdir = Directory(p.join(tempTestDir.path, 'explicit_index_storage', 'images'));
      final targetDate = DateTime(2026, 6, 30);

      final explicitPath = await service.saveMealImage(
        testBytes,
        mealType: 'Cena',
        date: targetDate,
        index: 5,
        customDirectory: targetSubdir,
      );
      expect(p.basename(explicitPath), equals('2026_06_30_D_05.jpg'));

      // If explicit index 5 already exists, collision guard advances to 06
      final collisionPath = await service.saveMealImage(
        testBytes,
        mealType: 'Cena',
        date: targetDate,
        index: 5,
        customDirectory: targetSubdir,
      );
      expect(p.basename(collisionPath), equals('2026_06_30_D_06.jpg'));
    });

    test('getNextMealImageIndex handles unpadded dates and full meal type names safely', () async {
      final testDir = Directory(p.join(tempTestDir.path, 'pad_storage'));
      await testDir.create(recursive: true);

      // Create 2026_06_05_B_01.jpg
      final sample = File(p.join(testDir.path, '2026_06_05_B_01.jpg'));
      await sample.writeAsString('test');

      // Call getNextMealImageIndex with unpadded month "6", unpadded day "5", and word "Breakfast"
      final nextIdx = await ImageProcessingService.getNextMealImageIndex(
        directory: testDir,
        year: '2026',
        month: '6',
        day: '5',
        typeCode: 'Breakfast',
      );
      expect(nextIdx, equals(2));
    });

    test('generateMealImageFileName generates correct nomenclature with auto and explicit indices', () async {
      final testDir = Directory(p.join(tempTestDir.path, 'gen_storage'));
      await testDir.create(recursive: true);

      final name1 = await ImageProcessingService.generateMealImageFileName(
        date: DateTime(2026, 6, 30),
        mealType: 'Breakfast',
        directory: testDir,
      );
      expect(name1, equals('2026_06_30_B_01.jpg'));

      final explicit = await ImageProcessingService.generateMealImageFileName(
        date: DateTime(2026, 6, 30),
        mealType: 'Lunch',
        explicitIndex: 9,
      );
      expect(explicit, equals('2026_06_30_L_09.jpg'));
    });

    test('parseMealImageFileName strictly validates calendar dates (Feb 31, April 31, leap years) and rejects invalid', () {
      final info = ImageProcessingService.parseMealImageFileName('2026_06_30_B_01.jpg');
      expect(info, isNotNull);
      expect(info!.year, equals('2026'));
      expect(info.month, equals('06'));
      expect(info.day, equals('30'));
      expect(info.typeCode, equals('B'));
      expect(info.mealType, equals('Desayuno'));
      expect(info.index, equals(1));
      expect(info.date, equals(DateTime(2026, 6, 30)));

      // Valid path parsing preserves filePath
      final fullPathInfo = ImageProcessingService.parseMealImageFileName('/storage/emulated/0/Pictures/2026_12_25_D_02.jpeg');
      expect(fullPathInfo, isNotNull);
      expect(fullPathInfo!.filePath, equals('/storage/emulated/0/Pictures/2026_12_25_D_02.jpeg'));
      expect(fullPathInfo.fileName, equals('2026_12_25_D_02.jpeg'));

      // Calendar integrity checks
      expect(ImageProcessingService.parseMealImageFileName('2026_02_31_B_01.jpg'), isNull); // Feb 31 does not exist
      expect(ImageProcessingService.parseMealImageFileName('2026_04_31_B_01.jpg'), isNull); // Apr 31 does not exist
      expect(ImageProcessingService.parseMealImageFileName('2026_02_29_B_01.jpg'), isNull); // 2026 is not a leap year
      expect(ImageProcessingService.parseMealImageFileName('2024_02_29_B_01.jpg'), isNotNull); // 2024 IS a leap year
      expect(ImageProcessingService.parseMealImageFileName('2026_13_01_B_01.jpg'), isNull); // Month 13 does not exist
      expect(ImageProcessingService.parseMealImageFileName('2026_00_01_B_01.jpg'), isNull); // Month 0 does not exist
      expect(ImageProcessingService.parseMealImageFileName('2026_06_00_B_01.jpg'), isNull); // Day 0 does not exist
      expect(ImageProcessingService.parseMealImageFileName('2026_06_30_B_00.jpg'), isNull); // Index 0 is invalid

      expect(ImageProcessingService.isMealImageFileName('2026_06_30_B_01.jpg'), isTrue);
      expect(ImageProcessingService.isMealImageFileName('/some/path/2026_12_25_D_02.jpeg'), isTrue);
      expect(ImageProcessingService.isMealImageFileName('2026_02_31_B_01.jpg'), isFalse);
      expect(ImageProcessingService.isMealImageFileName('invalid_file.jpg'), isFalse);
      expect(ImageProcessingService.isMealImageFileName('meal_12345.jpg'), isFalse);
      expect(ImageProcessingService.parseMealImageFileName('not_a_meal.png'), isNull);
    });

    test('filterMealImages and listMealImages filter correctly by DateTime and criteria', () async {
      final files = [
        '/pics/2026_06_30_B_01.jpg',
        '/pics/2026_06_30_B_02.jpg',
        '/pics/2026_06_30_L_01.jpg',
        '/pics/2026_07_01_B_01.jpg',
        '/pics/2025_06_30_D_01.jpg',
        '/pics/random_image.jpg',
      ];

      // Filter by day
      final june30 = ImageProcessingService.filterMealImages(files, year: 2026, month: 6, day: 30);
      expect(june30.length, equals(3));

      // Filter by DateTime directly
      final june30ByDate = ImageProcessingService.filterMealImages(files, date: DateTime(2026, 6, 30));
      expect(june30ByDate.length, equals(3));

      // Filter by meal type Breakfast
      final breakfasts = ImageProcessingService.filterMealImages(files, mealType: 'Desayuno');
      expect(breakfasts.length, equals(3));

      // Filter by June 30 + Breakfast
      final june30Breakfasts = ImageProcessingService.filterMealImages(
        files,
        date: DateTime(2026, 6, 30),
        mealType: 'Breakfast',
      );
      expect(june30Breakfasts.length, equals(2));
      expect(june30Breakfasts.map((e) => e.fileName).toList(), equals(['2026_06_30_B_01.jpg', '2026_06_30_B_02.jpg']));

      // Test listMealImages on real directory
      final listDir = Directory(p.join(tempTestDir.path, 'list_test'));
      await listDir.create(recursive: true);
      await File(p.join(listDir.path, '2026_06_30_B_01.jpg')).writeAsString('a');
      await File(p.join(listDir.path, '2026_06_30_L_01.jpg')).writeAsString('b');
      await File(p.join(listDir.path, 'other_file.txt')).writeAsString('c');

      final dirBreakfasts = await ImageProcessingService.listMealImages(
        directory: listDir,
        mealType: 'Desayuno',
      );
      expect(dirBreakfasts.length, equals(1));
      expect(dirBreakfasts.first.fileName, equals('2026_06_30_B_01.jpg'));
    });

    test('saveMealImage falls back gracefully when primary candidate fails', () async {
      final service = ImageProcessingService.instance;
      final testBytes = Uint8List.fromList([100, 101, 102]);

      // Execution without customDirectory on test platform will fall back safely to temp directory
      final savedPath = await service.saveMealImage(
        testBytes,
        mealType: 'Almuerzo',
        date: DateTime(2026, 6, 30),
      );
      expect(savedPath, isNotEmpty);
      expect(savedPath, contains('FoodTracker'));
      expect(savedPath, contains('images'));
      expect(p.basename(savedPath), startsWith('2026_06_30_L_'));

      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), equals(testBytes));

      // Clean up
      await file.delete();
    });

    test('deleteMealImage handles null, empty, whitespace, and existing files safely', () async {
      final service = ImageProcessingService.instance;

      // Null, empty, whitespace - no throw
      await expectLater(service.deleteMealImage(null), completes);
      await expectLater(service.deleteMealImage(''), completes);
      await expectLater(service.deleteMealImage('   '), completes);

      // Nonexistent file - no throw
      await expectLater(service.deleteMealImage(p.join(tempTestDir.path, 'missing.jpg')), completes);

      // Existing file
      final testFile = File(p.join(tempTestDir.path, 'to_delete.jpg'));
      await testFile.writeAsString('dummy');
      expect(await testFile.exists(), isTrue);

      await service.deleteMealImage(testFile.path);
      expect(await testFile.exists(), isFalse);

      // file:// URI scheme formatted path
      final uriFile = File(p.join(tempTestDir.path, 'uri_delete.jpg'));
      await uriFile.writeAsString('dummy');
      expect(await uriFile.exists(), isTrue);

      final fileUri = uriFile.uri.toString();
      await service.deleteMealImage(fileUri);
      expect(await uriFile.exists(), isFalse);
    });

    test('pruneOldMealPhotos with retentionDays <= 0 returns 0 immediately', () async {
      final service = ImageProcessingService.instance;
      expect(await service.pruneOldMealPhotos(retentionDays: 0), equals(0));
      expect(await service.pruneOldMealPhotos(retentionDays: -5), equals(0));
    });

    test('pruneOldMealPhotos deletes old photos from disk and clears SQLite imagePath', () async {
      final service = ImageProcessingService.instance;
      final dbService = DatabaseService.instance;
      final now = DateTime.now();

      // Create physical files
      final oldFile = File(p.join(tempTestDir.path, 'old_meal.jpg'));
      await oldFile.writeAsString('old_image_bytes');
      expect(await oldFile.exists(), isTrue);

      final recentFile = File(p.join(tempTestDir.path, 'recent_meal.jpg'));
      await recentFile.writeAsString('recent_image_bytes');
      expect(await recentFile.exists(), isTrue);

      final missingPath = p.join(tempTestDir.path, 'already_deleted.jpg');

      // Insert meals in DB
      final oldMeal = Meal(
        id: 'old-1',
        name: 'Comida Antigua',
        date: now.subtract(const Duration(days: 45)),
        imagePath: oldFile.path,
      );

      final recentMeal = Meal(
        id: 'recent-1',
        name: 'Comida Reciente',
        date: now.subtract(const Duration(days: 5)),
        imagePath: recentFile.path,
      );

      final oldMealMissingFile = Meal(
        id: 'old-missing',
        name: 'Comida Sin Archivo Físico',
        date: now.subtract(const Duration(days: 40)),
        imagePath: missingPath,
      );

      await dbService.insertMeal(oldMeal);
      await dbService.insertMeal(recentMeal);
      await dbService.insertMeal(oldMealMissingFile);

      // Prune with 30 days retention
      final deleted = await service.pruneOldMealPhotos(retentionDays: 30);
      expect(deleted, equals(1)); // Only 1 physical file actually existed to be deleted

      // Physical file for old meal should be deleted
      expect(await oldFile.exists(), isFalse);

      // Physical file for recent meal must remain intact
      expect(await recentFile.exists(), isTrue);

      // DB checks
      final updatedOld = await dbService.getMealById('old-1');
      expect(updatedOld!.imagePath, isNull);
      expect(updatedOld.name, equals('Comida Antigua'));

      final updatedMissing = await dbService.getMealById('old-missing');
      expect(updatedMissing!.imagePath, isNull);

      final updatedRecent = await dbService.getMealById('recent-1');
      expect(updatedRecent!.imagePath, equals(recentFile.path));
    });

    test('pruneOldMealPhotos handles file:// URI formatted paths in database', () async {
      final service = ImageProcessingService.instance;
      final dbService = DatabaseService.instance;
      final now = DateTime.now();

      final uriFile = File(p.join(tempTestDir.path, 'uri_meal.jpg'));
      await uriFile.writeAsString('uri_bytes');
      expect(await uriFile.exists(), isTrue);

      final mealWithUri = Meal(
        id: 'meal-uri-1',
        name: 'Comida URI',
        date: now.subtract(const Duration(days: 60)),
        imagePath: uriFile.uri.toString(),
      );

      await dbService.insertMeal(mealWithUri);

      final deleted = await service.pruneOldMealPhotos(retentionDays: 30);
      expect(deleted, equals(1));
      expect(await uriFile.exists(), isFalse);

      final updated = await dbService.getMealById('meal-uri-1');
      expect(updated!.imagePath, isNull);
    });
  });
}

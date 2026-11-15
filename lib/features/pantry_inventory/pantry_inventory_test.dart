import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/core/errors/failures.dart';
import 'package:food_tracker/core/errors/result.dart';
import 'package:food_tracker/core/interfaces/daos_interfaces.dart';
import 'pantry_inventory.dart';

class _FakePantryDao implements IPantryDao {
  final List<PantryItem> items = [];

  @override
  Future<int> insertPantryItem(PantryItem item) async {
    items.add(item);
    return 1;
  }

  @override
  Future<int> updatePantryItem(PantryItem item) async {
    final idx = items.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      items[idx] = item;
    }
    return 1;
  }

  @override
  Future<int> deletePantryItem(String id) async {
    items.removeWhere((i) => i.id == id);
    return 1;
  }

  @override
  Future<List<PantryItem>> getPantryItems({
    String? query,
    String? category,
    bool? onlyFavorites,
  }) async {
    return items.where((item) {
      if (category != null && category.isNotEmpty) {
        if (item.category?.toLowerCase() != category.toLowerCase()) return false;
      }
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final nameMatch = item.name.toLowerCase().contains(q);
        final brandMatch = item.brand?.toLowerCase().contains(q) ?? false;
        if (!nameMatch && !brandMatch) return false;
      }
      if (onlyFavorites == true && !item.isFavorite) return false;
      return true;
    }).toList();
  }

  @override
  Future<String> getPantryPromptContext() async {
    if (items.isEmpty) return '';
    return 'Despensa del usuario: ${items.map((e) => e.name).join(", ")}';
  }

  @override
  Future<Result<int, DatabaseFailure>> insertPantryItemResult(PantryItem item) async {
    await insertPantryItem(item);
    return const Result.ok(1);
  }

  @override
  Future<Result<List<PantryItem>, DatabaseFailure>> getPantryItemsResult({
    String? query,
    String? category,
    bool? onlyFavorites,
  }) async {
    final list = await getPantryItems(query: query, category: category, onlyFavorites: onlyFavorites);
    return Result.ok(list);
  }
}

void main() {
  group('PantryCategory & Expiration Classification Domain Tests', () {
    test('PantryCategory.fromString resolves canonical and localized labels', () {
      expect(PantryCategory.fromString('Granos'), equals(PantryCategory.grains));
      expect(PantryCategory.fromString('grains'), equals(PantryCategory.grains));
      expect(PantryCategory.fromString('Lácteos'), equals(PantryCategory.dairy));
      expect(PantryCategory.fromString('Proteínas'), equals(PantryCategory.proteins));
      expect(PantryCategory.fromString('Snacks'), equals(PantryCategory.snacks));
      expect(PantryCategory.fromString('Bebidas'), equals(PantryCategory.beverages));
      expect(PantryCategory.fromString(null), equals(PantryCategory.all));
      expect(PantryCategory.fromString('Desconocido'), equals(PantryCategory.all));
    });

    test('expiration status classifiers compute fresh, expiring soon, and expired', () {
      final now = DateTime.now();
      final freshItem = PantryItem(
        name: 'Arroz',
        expirationDate: now.add(const Duration(days: 60)),
      );
      final expiringItem = PantryItem(
        name: 'Yogurt',
        expirationDate: now.add(const Duration(days: 3)),
      );
      final expiredItem = PantryItem(
        name: 'Leche',
        expirationDate: now.subtract(const Duration(days: 2)),
      );
      final unknownItem = PantryItem(name: 'Sal');

      expect(PantryExpirationStatus.fromItem(freshItem), equals(PantryExpirationStatus.fresh));
      expect(freshItem.isExpiringSoon, isFalse);
      expect(freshItem.isExpired, isFalse);

      expect(PantryExpirationStatus.fromItem(expiringItem), equals(PantryExpirationStatus.expiringSoon));
      expect(expiringItem.isExpiringSoon, isTrue);
      expect(expiringItem.isExpired, isFalse);

      expect(PantryExpirationStatus.fromItem(expiredItem), equals(PantryExpirationStatus.expired));
      expect(expiredItem.isExpiringSoon, isFalse);
      expect(expiredItem.isExpired, isTrue);

      expect(PantryExpirationStatus.fromItem(unknownItem), equals(PantryExpirationStatus.unknown));
    });

    test('low stock detection evaluates package weight threshold', () {
      final lowStockItem = PantryItem(
        name: 'Avena',
        packageWeight: 500.0,
        stockQuantity: 80.0, // 80 <= 100 (20%)
      );
      final normalStockItem = PantryItem(
        name: 'Avena',
        packageWeight: 500.0,
        stockQuantity: 250.0,
      );

      expect(lowStockItem.hasLowStock, isTrue);
      expect(normalStockItem.hasLowStock, isFalse);
    });
  });

  group('PantryInventoryState Sentinel & Immutability', () {
    test('initial state contains safe sentinel defaults', () {
      const state = PantryInventoryState.initial;
      expect(state.items, isEmpty);
      expect(state.selectedCategory, equals(PantryCategory.all));
      expect(state.searchQuery, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isScanning, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.knownBrands, isEmpty);
      expect(state.totalCount, equals(0));
    });

    test('copyWith updates state and clears errorMessage via sentinel', () {
      final item = PantryItem(name: 'Almendras', brand: 'Kirkland');
      final state1 = PantryInventoryState.initial.copyWith(
        items: [item],
        selectedCategory: PantryCategory.snacks,
        errorMessage: 'Initial error',
      );
      expect(state1.items.length, equals(1));
      expect(state1.selectedCategory, equals(PantryCategory.snacks));
      expect(state1.errorMessage, equals('Initial error'));
      expect(state1.knownBrands, equals(['Kirkland']));

      final state2 = state1.copyWith(errorMessage: null);
      expect(state2.errorMessage, isNull);
      expect(state2.items.length, equals(1));
    });

    test('filteredItems applies category and search query filters', () {
      final item1 = PantryItem(name: 'Avena Quaker', brand: 'Quaker', category: 'Granos');
      final item2 = PantryItem(name: 'Leche Alpina', brand: 'Alpina', category: 'Lácteos');
      final state = PantryInventoryState(items: [item1, item2]);

      final grainFiltered = state.copyWith(selectedCategory: PantryCategory.grains);
      expect(grainFiltered.filteredItems.length, equals(1));
      expect(grainFiltered.filteredItems.first.name, equals('Avena Quaker'));

      final queryFiltered = state.copyWith(searchQuery: 'alpina');
      expect(queryFiltered.filteredItems.length, equals(1));
      expect(queryFiltered.filteredItems.first.brand, equals('Alpina'));
    });
  });

  group('PantryInventoryController Operations', () {
    late _FakePantryDao fakeDao;
    late PantryInventoryController controller;

    setUp(() {
      fakeDao = _FakePantryDao();
      controller = PantryInventoryController(pantryDao: fakeDao);
    });

    tearDown(() {
      controller.dispose();
    });

    test('loads empty items and saves new item successfully', () async {
      await controller.loadItems();
      expect(controller.items, isEmpty);

      final item = PantryItem(
        id: 'pantry-1',
        name: 'Pasta Integrale',
        brand: 'Barilla',
        category: 'Granos',
        packageWeight: 500.0,
        stockQuantity: 500.0,
      );

      await controller.saveItem(item);
      expect(controller.items.length, equals(1));
      expect(controller.items.first.name, equals('Pasta Integrale'));
      expect(fakeDao.items.length, equals(1));
    });

    test('brand detection locates items by brand or keywords', () async {
      final item = PantryItem(
        id: 'pantry-2',
        name: 'Whey Isolate',
        brand: 'Optimum Nutrition',
        matchKeywords: 'proteina,on,gold standard',
      );
      await controller.saveItem(item);

      expect(controller.detectBrand('Compré Optimum Nutrition'), isNotNull);
      expect(controller.detectBrand('proteina en polvo')?.id, equals('pantry-2'));
      expect(controller.detectBrand('Desconocido'), isNull);
      expect(controller.findItemsByBrand('Optimum Nutrition').length, equals(1));
    });

    test('updateStock and consumeStock adjust inventory accurately', () async {
      final item = PantryItem(
        id: 'pantry-3',
        name: 'Arroz Integral',
        packageWeight: 1000.0,
        stockQuantity: 1000.0,
      );
      await controller.saveItem(item);

      final updated = await controller.consumeStock('pantry-3', 250.0);
      expect(updated?.stockQuantity, equals(750.0));
      expect(controller.items.first.stockQuantity, equals(750.0));

      final direct = await controller.updateStock('pantry-3', 500.0);
      expect(direct?.stockQuantity, equals(500.0));
      expect(controller.items.first.stockQuantity, equals(500.0));
    });

    test('deletes pantry item cleanly', () async {
      final item = PantryItem(id: 'pantry-del', name: 'Atún');
      await controller.saveItem(item);
      expect(controller.items.length, equals(1));

      final success = await controller.deleteItem('pantry-del');
      expect(success, isTrue);
      expect(controller.items, isEmpty);
      expect(fakeDao.items, isEmpty);
    });

    test('getPromptContext delegates to DAO context generator', () async {
      final item = PantryItem(id: 'pantry-ctx', name: 'Yogurt Griego');
      await controller.saveItem(item);

      final prompt = await controller.getPromptContext();
      expect(prompt, contains('Yogurt Griego'));
    });
  });
}

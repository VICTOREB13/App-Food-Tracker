import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:food_tracker/core/di/service_locator.dart';
import 'package:food_tracker/core/interfaces/daos_interfaces.dart';
import 'package:food_tracker/core/ports/database_port.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'pantry_inventory.model.dart';

/// State management controller for the Pantry Inventory vertical slice.
/// Handles pantry catalog items, brand detection, package weights, expiration warnings,
/// and persistence through IDatabasePort or IPantryDao (< 300 LoC budget).
class PantryInventoryController extends ChangeNotifier {
  static PantryInventoryController instance = PantryInventoryController();

  final IPantryDao _dao;
  PantryInventoryState _state = PantryInventoryState.initial;

  PantryInventoryController({
    IDatabasePort? databasePort,
    IPantryDao? pantryDao,
  }) : _dao = pantryDao ??
            (databasePort?.pantryDao ??
                (getIt.isRegistered<IDatabasePort>()
                    ? getIt<IDatabasePort>().pantryDao
                    : (getIt.isRegistered<IPantryDao>()
                        ? getIt<IPantryDao>()
                        : DatabaseService.instance.pantryDao)));

  @visibleForTesting
  static void setMockInstance(PantryInventoryController mock) {
    instance = mock;
  }

  @visibleForTesting
  static void resetInstance() {
    instance = PantryInventoryController();
  }

  PantryInventoryState get state => _state;
  List<PantryItem> get items => _state.items;
  List<PantryItem> get filteredItems => _state.filteredItems;
  PantryCategory get selectedCategory => _state.selectedCategory;
  String get searchQuery => _state.searchQuery;
  bool get isLoading => _state.isLoading;
  bool get isScanning => _state.isScanning;
  String? get errorMessage => _state.errorMessage;

  List<PantryItem> get expiringSoonItems => _state.expiringSoonItems;
  List<PantryItem> get expiredItems => _state.expiredItems;
  List<PantryItem> get lowStockItems => _state.lowStockItems;
  List<String> get knownBrands => _state.knownBrands;
  int get expirationWarningsCount => expiringSoonItems.length + expiredItems.length;

  Future<void> init() async {
    await loadItems();
  }

  Future<void> loadItems() async {
    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();
    try {
      final list = await _dao.getPantryItems();
      _state = _state.copyWith(items: list, isLoading: false);
    } catch (e) {
      debugPrint('PantryInventoryController: Error loading items: $e');
      _state = _state.copyWith(isLoading: false, errorMessage: e.toString());
    } finally {
      notifyListeners();
    }
  }

  Future<PantryItem> saveItem(PantryItem item) async {
    final exists = _state.items.any((i) => i.id == item.id);
    if (exists) {
      await _dao.updatePantryItem(item);
      final updatedList = _state.items.map((i) => i.id == item.id ? item : i).toList();
      _state = _state.copyWith(items: updatedList);
    } else {
      await _dao.insertPantryItem(item);
      _state = _state.copyWith(items: [..._state.items, item]);
    }
    notifyListeners();
    return item;
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _dao.deletePantryItem(id);
      final updatedList = _state.items.where((i) => i.id != id).toList();
      _state = _state.copyWith(items: updatedList);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PantryInventoryController: Error deleting item $id: $e');
      return false;
    }
  }

  void setCategory(PantryCategory category) {
    if (_state.selectedCategory == category) return;
    _state = _state.copyWith(selectedCategory: category);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_state.searchQuery == query) return;
    _state = _state.copyWith(searchQuery: query);
    notifyListeners();
  }

  void setScanning(bool scanning) {
    if (_state.isScanning == scanning) return;
    _state = _state.copyWith(isScanning: scanning);
    notifyListeners();
  }

  PantryItem? detectBrand(String text) {
    if (text.trim().isEmpty) return null;
    final lower = text.trim().toLowerCase();
    for (final item in _state.items) {
      if (item.brand != null && item.brand!.trim().isNotEmpty) {
        final bLower = item.brand!.trim().toLowerCase();
        if (lower.contains(bLower) || bLower.contains(lower)) {
          return item;
        }
      }
      if (item.matchKeywords != null && item.matchKeywords!.trim().isNotEmpty) {
        final kwList = item.matchKeywords!.toLowerCase().split(',');
        for (final kw in kwList) {
          if (lower.contains(kw.trim())) return item;
        }
      }
      if (lower.contains(item.name.toLowerCase())) {
        return item;
      }
    }
    return null;
  }

  List<PantryItem> findItemsByBrand(String brand) {
    if (brand.trim().isEmpty) return const [];
    final lower = brand.trim().toLowerCase();
    return _state.items.where((i) => i.brand?.toLowerCase() == lower).toList();
  }

  Future<PantryItem?> updateStock(String id, double newStock) async {
    final idx = _state.items.indexWhere((i) => i.id == id);
    if (idx == -1) return null;
    final item = _state.items[idx];
    final updated = item.copyWith(stockQuantity: newStock < 0.0 ? 0.0 : newStock);
    await _dao.updatePantryItem(updated);
    final updatedList = List<PantryItem>.from(_state.items)..[idx] = updated;
    _state = _state.copyWith(items: updatedList);
    notifyListeners();
    return updated;
  }

  Future<PantryItem?> consumeStock(String id, double gramsConsumed) async {
    final idx = _state.items.indexWhere((i) => i.id == id);
    if (idx == -1) return null;
    final item = _state.items[idx];
    final current = item.stockQuantity ?? item.packageWeight ?? item.servingSize;
    final remaining = (current - gramsConsumed).clamp(0.0, 100000.0);
    return updateStock(id, remaining);
  }

  PantryExpirationStatus checkExpiration(PantryItem item) {
    return PantryExpirationStatus.fromItem(item);
  }

  Future<String> getPromptContext() async {
    return await _dao.getPantryPromptContext();
  }
}

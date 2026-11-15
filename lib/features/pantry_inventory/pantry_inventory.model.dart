import 'package:flutter/foundation.dart';
import 'package:food_tracker/l10n/app_localizations.dart';
export 'package:food_tracker/features/pantry_inventory/models/pantry_item.dart';

/// Predefined pantry item categories.
enum PantryCategory {
  all('Todos'),
  grains('Granos'),
  dairy('Lácteos'),
  proteins('Proteínas'),
  snacks('Snacks'),
  beverages('Bebidas');

  final String canonicalValue;
  const PantryCategory(this.canonicalValue);

  static PantryCategory fromString(String? value) {
    if (value == null || value.trim().isEmpty) return PantryCategory.all;
    final lower = value.trim().toLowerCase();
    for (final c in PantryCategory.values) {
      if (c.canonicalValue.toLowerCase() == lower || c.name.toLowerCase() == lower) {
        return c;
      }
    }
    return PantryCategory.all;
  }

  String getLocalizedLabel(AppLocalizations l10n) {
    switch (this) {
      case PantryCategory.all:
        return l10n.pantryCategoriesAll;
      case PantryCategory.grains:
        return l10n.pantryCategoriesGrains;
      case PantryCategory.dairy:
        return l10n.pantryCategoriesDairy;
      case PantryCategory.proteins:
        return l10n.pantryCategoriesProteins;
      case PantryCategory.snacks:
        return l10n.pantryCategoriesSnacks;
      case PantryCategory.beverages:
        return l10n.pantryCategoriesBeverages;
    }
  }
}

/// Expiration status classifier for pantry items.
enum PantryExpirationStatus {
  fresh,
  expiringSoon,
  expired,
  unknown;

  static PantryExpirationStatus fromItem(PantryItem item) {
    if (item.expirationDate == null) return PantryExpirationStatus.unknown;
    if (item.isExpired) return PantryExpirationStatus.expired;
    if (item.isExpiringSoon) return PantryExpirationStatus.expiringSoon;
    return PantryExpirationStatus.fresh;
  }
}

/// Immutable state container for the Pantry Inventory vertical slice.
@immutable
class PantryInventoryState {
  final List<PantryItem> items;
  final PantryCategory selectedCategory;
  final String searchQuery;
  final bool isLoading;
  final bool isScanning;
  final String? errorMessage;

  static const Object _sentinel = Object();

  const PantryInventoryState({
    this.items = const [],
    this.selectedCategory = PantryCategory.all,
    this.searchQuery = '',
    this.isLoading = false,
    this.isScanning = false,
    this.errorMessage,
  });

  static const PantryInventoryState initial = PantryInventoryState();

  List<PantryItem> get filteredItems {
    final query = searchQuery.trim().toLowerCase();
    return items.where((item) {
      final matchesCategory = selectedCategory == PantryCategory.all ||
          (item.category != null &&
              item.category!.toLowerCase() == selectedCategory.canonicalValue.toLowerCase());
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;
      final nameMatches = item.name.toLowerCase().contains(query);
      final brandMatches = item.brand != null && item.brand!.toLowerCase().contains(query);
      final keywordMatches =
          item.matchKeywords != null && item.matchKeywords!.toLowerCase().contains(query);
      return nameMatches || brandMatches || keywordMatches;
    }).toList();
  }

  List<PantryItem> get expiringSoonItems =>
      items.where((i) => i.isExpiringSoon).toList();

  List<PantryItem> get expiredItems =>
      items.where((i) => i.isExpired).toList();

  List<PantryItem> get lowStockItems =>
      items.where((i) => i.hasLowStock).toList();

  List<String> get knownBrands {
    final brands = <String>{};
    for (final item in items) {
      if (item.brand != null && item.brand!.trim().isNotEmpty) {
        brands.add(item.brand!.trim());
      }
    }
    return brands.toList()..sort();
  }

  int get totalCount => items.length;
  bool get isEmpty => items.isEmpty;

  PantryInventoryState copyWith({
    List<PantryItem>? items,
    PantryCategory? selectedCategory,
    String? searchQuery,
    bool? isLoading,
    bool? isScanning,
    Object? errorMessage = _sentinel,
  }) {
    return PantryInventoryState(
      items: items ?? this.items,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : (errorMessage as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PantryInventoryState &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          selectedCategory == other.selectedCategory &&
          searchQuery == other.searchQuery &&
          isLoading == other.isLoading &&
          isScanning == other.isScanning &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      Object.hash(
        Object.hashAll(items),
        selectedCategory,
        searchQuery,
        isLoading,
        isScanning,
        errorMessage,
      );
}

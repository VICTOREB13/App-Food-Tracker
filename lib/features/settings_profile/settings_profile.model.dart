import 'package:flutter/material.dart';
import 'package:food_tracker/core/models/daily_goals.dart';
import 'package:food_tracker/core/models/gemini_model_info.dart';
import 'package:food_tracker/core/models/storage_mode.dart';
import 'package:food_tracker/features/settings_profile/models/user_profile.dart';

import 'package:food_tracker/core/models/daily_goals.dart';
import 'package:food_tracker/core/models/gemini_model_info.dart';
import 'package:food_tracker/core/models/storage_mode.dart';
import 'package:food_tracker/features/settings_profile/models/user_profile.dart';

/// Immutable state container for the Settings & Profile vertical slice.
/// Implements the Immutable Sentinel Pattern for atomic field updates and BYOK keystore management.
@immutable
class SettingsProfileState {
  final UserProfile? profile;
  final String? geminiApiKey;
  final String? selectedGeminiModel;
  final String? usdaApiKey;
  final List<GeminiModelInfo> availableGeminiModels;
  final bool isLoadingModels;
  final bool isOnlineModels;
  final DailyGoals dailyGoals;
  final Map<String, dynamic> dbStats;
  final StorageMode storageMode;
  final Locale? locale;
  final ThemeMode themeMode;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  static const Object _sentinel = Object();

  const SettingsProfileState({
    this.profile,
    this.geminiApiKey,
    this.selectedGeminiModel,
    this.usdaApiKey,
    this.availableGeminiModels = const [],
    this.isLoadingModels = false,
    this.isOnlineModels = false,
    this.dailyGoals = const DailyGoals(),
    this.dbStats = const {},
    this.storageMode = StorageMode.public,
    this.locale,
    this.themeMode = ThemeMode.dark,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  static const SettingsProfileState initial = SettingsProfileState();

  bool get hasApiKey => geminiApiKey != null && geminiApiKey!.trim().isNotEmpty;
  bool get hasUsdaApiKey => usdaApiKey != null && usdaApiKey!.trim().isNotEmpty;
  bool get isDarkMode => themeMode == ThemeMode.dark;

  SettingsProfileState copyWith({
    Object? profile = _sentinel,
    Object? geminiApiKey = _sentinel,
    Object? selectedGeminiModel = _sentinel,
    Object? usdaApiKey = _sentinel,
    List<GeminiModelInfo>? availableGeminiModels,
    bool? isLoadingModels,
    bool? isOnlineModels,
    DailyGoals? dailyGoals,
    Map<String, dynamic>? dbStats,
    StorageMode? storageMode,
    Object? locale = _sentinel,
    ThemeMode? themeMode,
    bool? isLoading,
    bool? isSaving,
    Object? errorMessage = _sentinel,
  }) {
    return SettingsProfileState(
      profile: identical(profile, _sentinel)
          ? this.profile
          : (profile as UserProfile?),
      geminiApiKey: identical(geminiApiKey, _sentinel)
          ? this.geminiApiKey
          : (geminiApiKey as String?),
      selectedGeminiModel: identical(selectedGeminiModel, _sentinel)
          ? this.selectedGeminiModel
          : (selectedGeminiModel as String?),
      usdaApiKey: identical(usdaApiKey, _sentinel)
          ? this.usdaApiKey
          : (usdaApiKey as String?),
      availableGeminiModels:
          availableGeminiModels ?? this.availableGeminiModels,
      isLoadingModels: isLoadingModels ?? this.isLoadingModels,
      isOnlineModels: isOnlineModels ?? this.isOnlineModels,
      dailyGoals: dailyGoals ?? this.dailyGoals,
      dbStats: dbStats ?? this.dbStats,
      storageMode: storageMode ?? this.storageMode,
      locale: identical(locale, _sentinel) ? this.locale : (locale as Locale?),
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : (errorMessage as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsProfileState &&
          runtimeType == other.runtimeType &&
          profile == other.profile &&
          geminiApiKey == other.geminiApiKey &&
          selectedGeminiModel == other.selectedGeminiModel &&
          usdaApiKey == other.usdaApiKey &&
          listEquals(availableGeminiModels, other.availableGeminiModels) &&
          isLoadingModels == other.isLoadingModels &&
          isOnlineModels == other.isOnlineModels &&
          dailyGoals == other.dailyGoals &&
          mapEquals(dbStats, other.dbStats) &&
          storageMode == other.storageMode &&
          locale == other.locale &&
          themeMode == other.themeMode &&
          isLoading == other.isLoading &&
          isSaving == other.isSaving &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      profile.hashCode ^
      (geminiApiKey?.hashCode ?? 0) ^
      (selectedGeminiModel?.hashCode ?? 0) ^
      (usdaApiKey?.hashCode ?? 0) ^
      availableGeminiModels.hashCode ^
      isLoadingModels.hashCode ^
      isOnlineModels.hashCode ^
      dailyGoals.hashCode ^
      dbStats.hashCode ^
      storageMode.hashCode ^
      (locale?.hashCode ?? 0) ^
      themeMode.hashCode ^
      isLoading.hashCode ^
      isSaving.hashCode ^
      (errorMessage?.hashCode ?? 0);
}

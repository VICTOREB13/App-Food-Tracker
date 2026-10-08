import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../controllers/settings_controller.dart';
import '../core/interfaces/notification_service_interface.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_es.dart';

/// Service managing local and exact scheduled notifications for meal analysis and intermittent fasting.
class NotificationService implements INotificationService {
  static NotificationService? _mockInstance;
  static final NotificationService _instance = NotificationService._internal();

  static NotificationService get instance => _mockInstance ?? _instance;

  @visibleForTesting
  static void setMockInstance(NotificationService? mock) {
    _mockInstance = mock;
  }

  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  NotificationService._internal({FlutterLocalNotificationsPlugin? plugin})
      : _notificationsPlugin = plugin ?? FlutterLocalNotificationsPlugin();

  factory NotificationService({FlutterLocalNotificationsPlugin? plugin}) {
    if (plugin != null) {
      return NotificationService._internal(plugin: plugin);
    }
    return instance;
  }

  bool get isInitialized => _isInitialized;

  static const String mealChannelId = 'meal_analysis_channel';
  static const String mealChannelName = 'Análisis de Comidas';
  static const String mealChannelDescription = 'Notificaciones sobre el resultado del análisis de tus comidas';

  static const String fastingChannelId = 'fasting_reminder_channel';
  static const String fastingChannelName = 'Ayuno Intermitente';
  static const String fastingChannelDescription = 'Recordatorios al completar tu ventana de ayuno intermitente';

  static const int mealCompletedNotificationId = 2001;
  static const int mealFailedNotificationId = 2002;
  static const int fastingNotificationId = 1001;

  AppLocalizations get _currentL10n {
    try {
      final loc = SettingsController.instance.currentLocale ?? const Locale('es');
      return lookupAppLocalizations(loc);
    } catch (_) {
      return AppLocalizationsEs();
    }
  }

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('NotificationService: Timezone init warning: $e');
    }

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      );

      await _notificationsPlugin.initialize(initSettings);

      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        try {
          await androidImpl?.requestExactAlarmsPermission();
        } catch (_) {}
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService: Plugin initialize warning: $e');
    }
  }

  @override
  Future<void> showMealAnalysisCompleted({
    required String mealName,
    required double calories,
    String? title,
    String? body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        mealChannelId,
        mealChannelName,
        channelDescription: mealChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final calStr = calories.toStringAsFixed(0);
      final effTitle = title ?? _currentL10n.mealAnalysisSuccessTitle;
      final effBody = body ?? _currentL10n.mealAnalysisSuccessBody(mealName, calStr);

      await _notificationsPlugin.show(
        mealCompletedNotificationId,
        effTitle,
        effBody,
        details,
      );
    } catch (e) {
      debugPrint('NotificationService: showMealAnalysisCompleted error: $e');
    }
  }

  @override
  Future<void> showMealAnalysisFailed({
    required String error,
    String? title,
    String? body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        mealChannelId,
        mealChannelName,
        channelDescription: mealChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final effTitle = title ?? _currentL10n.mealAnalysisErrorTitle;
      final effBody = body ?? (error.isNotEmpty ? error : _currentL10n.mealAnalysisErrorFallback);

      await _notificationsPlugin.show(
        mealFailedNotificationId,
        effTitle,
        effBody,
        details,
      );
    } catch (e) {
      debugPrint('NotificationService: showMealAnalysisFailed error: $e');
    }
  }

  @override
  Future<void> scheduleFastingCompleted({
    required DateTime scheduledTime,
    required double targetHours,
    String? title,
    String? body,
  }) async {
    try {
      if (scheduledTime.isBefore(DateTime.now())) return;

      const androidDetails = AndroidNotificationDetails(
        fastingChannelId,
        fastingChannelName,
        channelDescription: fastingChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final targetStr = targetHours.toStringAsFixed(0);
      final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);
      final effTitle = title ?? _currentL10n.fastingCompletedTitle;
      final effBody = body ?? _currentL10n.fastingCompletedBody(targetStr);

      try {
        await _notificationsPlugin.zonedSchedule(
          fastingNotificationId,
          effTitle,
          effBody,
          tzScheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (exactErr) {
        debugPrint('NotificationService: exact alarm failed ($exactErr), falling back to inexact alarm');
        await _notificationsPlugin.zonedSchedule(
          fastingNotificationId,
          effTitle,
          effBody,
          tzScheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } catch (e) {
      debugPrint('NotificationService: scheduleFastingCompleted error: $e');
    }
  }

  @override
  Future<void> cancelFastingReminder() async {
    try {
      await _notificationsPlugin.cancel(fastingNotificationId);
    } catch (e) {
      debugPrint('NotificationService: cancelFastingReminder error: $e');
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService: cancelAllNotifications error: $e');
    }
  }
}

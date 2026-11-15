import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:food_tracker/core/di/service_locator.dart';
import 'package:food_tracker/core/interfaces/fasting_dao_interface.dart';
import 'package:food_tracker/core/ports/database_port.dart';
import 'package:food_tracker/core/database/database_service.dart';
import 'package:food_tracker/core/services/platform/home_widget_service.dart';
import 'package:food_tracker/core/services/platform/notification_service.dart';
import 'fasting_tracker.model.dart';

/// State management controller for the Fasting Tracker vertical slice.
/// Handles intermittent fasting protocols, state transitions, ketosis phase calculation,
/// timer ticks, and persistence through IDatabasePort or IFastingDao.
class FastingTrackerController extends ChangeNotifier {
  static FastingTrackerController instance = FastingTrackerController();

  final IFastingDao _dao;
  FastingState _state = FastingState.initial;
  Timer? _ticker;

  FastingTrackerController({
    IDatabasePort? databasePort,
    IFastingDao? fastingDao,
  }) : _dao = fastingDao ??
            (databasePort?.fastingDao ??
                (getIt.isRegistered<IDatabasePort>()
                    ? getIt<IDatabasePort>().fastingDao
                    : (getIt.isRegistered<IFastingDao>()
                        ? getIt<IFastingDao>()
                        : DatabaseService.instance.fastingDao)));

  @visibleForTesting
  static void setMockInstance(FastingTrackerController mock) {
    instance = mock;
  }

  @visibleForTesting
  static void resetInstance() {
    instance = FastingTrackerController();
  }

  FastingState get state => _state;
  FastingLog? get activeFast => _state.activeFast;
  bool get isFastingActive => _state.isFastingActive;
  bool get isLoading => _state.isLoading;
  double get targetHours => _state.targetHours;
  Duration get targetDuration => _state.targetDuration;
  Duration get elapsedDuration => _state.elapsed;
  Duration get remainingDuration => _state.remaining;
  double get progressRatio => _state.progressRatio;
  KetosisPhase get ketosisPhase => _state.ketosisPhase;
  FastingProtocol get currentProtocol => _state.protocol;
  String get fastingDurationFormatted => _state.formattedElapsed;
  String get remainingDurationFormatted => _state.formattedRemaining;

  Future<void> init() async {
    await loadActiveFast();
  }

  Future<void> loadActiveFast() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();
    try {
      final active = await _dao.getActiveFastingLog();
      final protocol = active != null
          ? FastingProtocol.fromHours(active.targetHours)
          : _state.protocol;
      _state = _state.copyWith(
        activeFast: active,
        protocol: protocol,
      );
      _recalculateDurationsAndPhase();
      _manageTicker();
    } catch (e) {
      debugPrint('FastingTrackerController: Error loading active fast: $e');
      _state = _state.copyWith(activeFast: null);
      _recalculateDurationsAndPhase();
    } finally {
      _state = _state.copyWith(isLoading: false);
      notifyListeners();
      _syncWidgetFasting();
    }
  }

  Future<FastingLog> startFast({
    double? targetHours,
    FastingProtocol? protocol,
    String? notes,
  }) async {
    if (isFastingActive) {
      await stopActiveFast();
    }

    final resolvedProtocol = protocol ??
        (targetHours != null
            ? FastingProtocol.fromHours(targetHours)
            : _state.protocol);
    final resolvedHours = targetHours ?? resolvedProtocol.targetHours;

    final newLog = FastingLog(
      startTime: DateTime.now(),
      targetHours: resolvedHours,
      isActive: true,
      notes: notes,
    );

    await _dao.insertFastingLog(newLog);
    _state = _state.copyWith(
      activeFast: newLog,
      protocol: resolvedProtocol,
    );
    _recalculateDurationsAndPhase();
    _manageTicker();
    notifyListeners();
    _syncWidgetFasting();

    final scheduledEnd = newLog.startTime.add(targetDuration);
    await NotificationService.instance.scheduleFastingCompleted(
      scheduledTime: scheduledEnd,
      targetHours: resolvedHours,
    );
    return newLog;
  }

  Future<FastingLog?> stopActiveFast({String? notes}) async {
    final active = _state.activeFast;
    if (active == null) return null;

    final updated = active.copyWith(
      endTime: DateTime.now(),
      isActive: false,
      notes: notes ?? active.notes,
    );

    await _dao.updateFastingLog(updated);
    _state = _state.copyWith(activeFast: null);
    _recalculateDurationsAndPhase();
    _manageTicker();
    notifyListeners();
    _syncWidgetFasting();

    await NotificationService.instance.cancelFastingReminder();
    return updated;
  }

  void setProtocol(FastingProtocol protocol) {
    if (_state.protocol == protocol) return;
    _state = _state.copyWith(protocol: protocol);
    if (!isFastingActive) {
      notifyListeners();
    }
  }

  void _recalculateDurationsAndPhase() {
    final active = _state.activeFast;
    if (active == null || !active.isActive) {
      _state = _state.copyWith(
        elapsed: Duration.zero,
        remaining: Duration.zero,
        progressRatio: 0.0,
        ketosisPhase: KetosisPhase.anabolic,
      );
      return;
    }

    final now = DateTime.now();
    final elapsed = now.isBefore(active.startTime)
        ? Duration.zero
        : now.difference(active.startTime);

    final targetMinutes = (active.targetHours * 60).round();
    final target = Duration(minutes: targetMinutes);

    final remaining = elapsed >= target ? Duration.zero : target - elapsed;
    final ratio = targetMinutes == 0
        ? 0.0
        : (elapsed.inMinutes / targetMinutes).clamp(0.0, 1.0);
    final phase = KetosisPhase.fromElapsed(elapsed);

    _state = _state.copyWith(
      elapsed: elapsed,
      remaining: remaining,
      progressRatio: ratio,
      ketosisPhase: phase,
    );
  }

  void _syncWidgetFasting() {
    try {
      HomeWidgetService.instance.updateFastingData(
        isActive: isFastingActive,
        timeFormatted: fastingDurationFormatted,
        targetHours: targetHours.round(),
      );
    } catch (_) {}
  }

  void _manageTicker() {
    _ticker?.cancel();
    if (isFastingActive) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
        _recalculateDurationsAndPhase();
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ticker = null;
    super.dispose();
  }
}

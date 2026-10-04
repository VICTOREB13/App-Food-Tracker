import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/interfaces/fasting_dao_interface.dart';
import '../models/fasting_log.dart';
import '../services/database_service.dart';

/// State management controller handling Intermittent Fasting tracking and timer tickers.
class FastingController extends ChangeNotifier {
  static FastingController instance = FastingController();

  final IFastingDao _dao;
  FastingLog? _activeFast;
  bool _isLoading = false;
  Timer? _ticker;

  FastingController({IFastingDao? fastingDao})
      : _dao = fastingDao ?? DatabaseService.instance.fastingDao;

  @visibleForTesting
  static void setMockInstance(FastingController mock) {
    instance = mock;
  }

  @visibleForTesting
  static void resetInstance() {
    instance = FastingController();
  }

  FastingLog? get activeFast => _activeFast;
  bool get isFastingActive => _activeFast != null && _activeFast!.isActive;
  bool get isLoading => _isLoading;

  double get targetHours => _activeFast?.targetHours ?? 16.0;

  Duration get targetDuration =>
      Duration(minutes: (targetHours * 60).round());

  Duration get elapsedDuration {
    if (_activeFast == null) return Duration.zero;
    final now = DateTime.now();
    if (now.isBefore(_activeFast!.startTime)) return Duration.zero;
    return now.difference(_activeFast!.startTime);
  }

  Duration get remainingDuration {
    if (!isFastingActive) return Duration.zero;
    final target = targetDuration;
    final elapsed = elapsedDuration;
    if (elapsed >= target) return Duration.zero;
    return target - elapsed;
  }

  double get progressRatio {
    if (!isFastingActive || targetDuration.inMinutes == 0) return 0.0;
    return (elapsedDuration.inMinutes / targetDuration.inMinutes).clamp(0.0, 1.0);
  }

  String get fastingDurationFormatted {
    final d = elapsedDuration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String get remainingDurationFormatted {
    final d = remainingDuration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  Future<void> init() async {
    await loadActiveFast();
  }

  Future<void> loadActiveFast() async {
    _isLoading = true;
    notifyListeners();
    try {
      _activeFast = await _dao.getActiveFastingLog();
      _manageTicker();
    } catch (e) {
      debugPrint('FastingController: Error loading active fast: $e');
      _activeFast = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FastingLog> startFast({
    double targetHours = 16.0,
    String? notes,
  }) async {
    if (isFastingActive) {
      await stopActiveFast();
    }

    final newLog = FastingLog(
      startTime: DateTime.now(),
      targetHours: targetHours,
      isActive: true,
      notes: notes,
    );

    await _dao.insertFastingLog(newLog);
    _activeFast = newLog;
    _manageTicker();
    notifyListeners();
    return newLog;
  }

  Future<FastingLog?> stopActiveFast({String? notes}) async {
    if (_activeFast == null) return null;

    final updated = _activeFast!.copyWith(
      endTime: DateTime.now(),
      isActive: false,
      notes: notes ?? _activeFast!.notes,
    );

    await _dao.updateFastingLog(updated);
    _activeFast = null;
    _manageTicker();
    notifyListeners();
    return updated;
  }

  void _manageTicker() {
    _ticker?.cancel();
    if (isFastingActive) {
      _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
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

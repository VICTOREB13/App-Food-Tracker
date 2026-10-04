import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_tracker/controllers/fasting_controller.dart';
import 'package:food_tracker/core/errors/failures.dart';
import 'package:food_tracker/core/errors/result.dart';
import 'package:food_tracker/core/interfaces/fasting_dao_interface.dart';
import 'package:food_tracker/models/fasting_log.dart';
import 'package:food_tracker/widgets/dashboard/fasting_window_bento_card.dart';

class _MockFastingDao implements IFastingDao {
  FastingLog? activeLog;

  @override
  Future<int> insertFastingLog(FastingLog log) async {
    if (log.isActive) activeLog = log;
    return 1;
  }

  @override
  Future<int> updateFastingLog(FastingLog log) async {
    activeLog = log.isActive ? log : null;
    return 1;
  }

  @override
  Future<int> deleteFastingLog(String id) async {
    if (activeLog?.id == id) activeLog = null;
    return 1;
  }

  @override
  Future<FastingLog?> getActiveFastingLog() async => activeLog;

  @override
  Future<List<FastingLog>> getAllFastingLogs() async => activeLog != null ? [activeLog!] : [];

  @override
  Future<FastingLog?> getFastingLogById(String id) async => activeLog?.id == id ? activeLog : null;

  @override
  Future<List<FastingLog>> getRecentFastingLogs({int limit = 10}) async =>
      activeLog != null ? [activeLog!] : [];

  @override
  Future<Result<int, DatabaseFailure>> insertFastingLogResult(FastingLog log) async {
    final id = await insertFastingLog(log);
    return Success(id);
  }

  @override
  Future<Result<FastingLog?, DatabaseFailure>> getActiveFastingLogResult() async =>
      Success(activeLog);

  @override
  Future<Result<List<FastingLog>, DatabaseFailure>> getAllFastingLogsResult() async =>
      Success(activeLog != null ? [activeLog!] : []);
}

void main() {
  group('FastingWindowBentoCard Widget Tests', () {
    testWidgets('renders compact pill when inactive and expands on tap', (tester) async {
      final dao = _MockFastingDao();
      final controller = FastingController(fastingDao: dao);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FastingWindowBentoCard(controller: controller),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Compact state assertions
      expect(find.byKey(const Key('fasting_bento_compact_pill')), findsOneWidget);
      expect(find.text('AYUNO INTERMITENTE'), findsOneWidget);
      expect(find.text('• Sin ayuno activo'), findsOneWidget);
      expect(find.byKey(const Key('fasting_compact_start_button')), findsOneWidget);

      // Tap to expand
      await tester.tap(find.byKey(const Key('fasting_bento_compact_pill')));
      await tester.pumpAndSettle();

      // Expanded state assertions
      expect(find.text('Inicia para dar seguimiento a tu ventana de comida'), findsOneWidget);
      expect(find.text('Iniciar'), findsWidgets);
    });

    testWidgets('renders fully expanded view when active fasting in progress', (tester) async {
      final dao = _MockFastingDao();
      final now = DateTime.now();
      dao.activeLog = FastingLog(
        startTime: now.subtract(const Duration(hours: 4)),
        targetHours: 16.0,
        isActive: true,
      );

      final controller = FastingController(fastingDao: dao);
      addTearDown(controller.dispose);
      await controller.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FastingWindowBentoCard(controller: controller),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('AYUNO INTERMITENTE'), findsOneWidget);
      expect(find.text('En curso'), findsOneWidget);
      expect(find.text('Terminar'), findsOneWidget);

      controller.dispose();
    });
  });
}

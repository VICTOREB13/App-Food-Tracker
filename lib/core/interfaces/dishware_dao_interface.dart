import '../../models/calibrated_dishware.dart';
import '../errors/failures.dart';
import '../errors/result.dart';

/// Contract for Calibrated Dishware Data Access Object.
abstract interface class IDishwareDao {
  Future<int> insertDishware(CalibratedDishware dishware);
  Future<int> updateDishware(CalibratedDishware dishware);
  Future<int> deleteDishware(String id);
  Future<CalibratedDishware?> getDishwareById(String id);
  Future<List<CalibratedDishware>> getAllDishware();
  Future<CalibratedDishware?> getDefaultDishware();
  Future<void> setDefaultDishware(String id);

  // Functional Result APIs
  Future<Result<int, DatabaseFailure>> insertDishwareResult(CalibratedDishware dishware);
  Future<Result<List<CalibratedDishware>, DatabaseFailure>> getAllDishwareResult();
  Future<Result<CalibratedDishware?, DatabaseFailure>> getDefaultDishwareResult();
}

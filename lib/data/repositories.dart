/// Storage-agnostic repository contract.
///
/// This is the seam that decouples the UI from any concrete persistence
/// backend. Swap the Hive implementation for SQLite, Isar, or a remote API
/// without touching a single widget.
library;

import 'models.dart';

/// Generates a unique id (microsecond timestamp string).
String newId() => DateTime.now().microsecondsSinceEpoch.toString();

abstract class TickRepository {
  Future<List<HabitTick>> list();
  Future<List<HabitTick>> listByDate(String date);
  Future<HabitTick> add(HabitTick tick);
  Future<void> update(HabitTick tick);
  Future<void> delete(String id);
}

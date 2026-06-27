/// Hive-backed repository implementation (pure Dart, no codegen, unit-testable).
library;

import 'dart:convert';

import 'package:hive_ce/hive.dart';

import 'models.dart';
import 'repositories.dart';

Map<String, dynamic> _decode(dynamic v) =>
    jsonDecode(v as String) as Map<String, dynamic>;

class HiveTickRepository implements TickRepository {
  final Box _box;
  HiveTickRepository(this._box);

  @override
  Future<List<HabitTick>> list() async =>
      _box.values.map((v) => HabitTick.fromJson(_decode(v))).toList();

  @override
  Future<List<HabitTick>> listByDate(String date) async =>
      (await list()).where((t) => t.date == date).toList();

  @override
  Future<HabitTick> add(HabitTick tick) async {
    await _box.put(tick.id, jsonEncode(tick.toJson()));
    return tick;
  }

  @override
  Future<void> update(HabitTick tick) async {
    await _box.put(tick.id, jsonEncode(tick.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}

/// Opens the habit-tick repository. Requires [Hive.init] to have been called.
Future<({TickRepository ticks})> openRepositories(String dirPath) async {
  final tickBox = await Hive.openBox('habit_ticks');
  return (ticks: HiveTickRepository(tickBox));
}

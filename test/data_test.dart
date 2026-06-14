import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:tactile_widget_kit/data/hive_repositories.dart';
import 'package:tactile_widget_kit/data/models.dart';

void main() {
  late Directory tempDir;
  late HiveTickRepository repo;

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('tactile_widget_kit_test_');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    final box = await Hive.openBox('habit_ticks');
    repo = HiveTickRepository(box);
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('habit tick CRUD', () async {
    final tick = HabitTick(
      id: '1',
      date: '2026-09-25',
      label: 'Reading',
      count: 3,
      updatedAt: 1,
    );
    await repo.add(tick);

    expect((await repo.list()).length, 1);
    expect((await repo.listByDate('2026-09-25')).length, 1);
    expect((await repo.listByDate('2026-09-26')).length, 0);

    await repo.update(tick.copyWith(label: 'Writing', updatedAt: 2));
    expect((await repo.list()).first.label, 'Writing');

    await repo.delete('1');
    expect((await repo.list()).length, 0);
  });

  test('habit tick persistence across reads', () async {
    await repo.add(HabitTick(
      id: 'a',
      date: '2026-09-25',
      label: 'Run',
      count: 1,
      updatedAt: 1,
    ));
    await repo.add(HabitTick(
      id: 'b',
      date: '2026-09-25',
      label: 'Read',
      count: 2,
      updatedAt: 2,
    ));

    expect((await repo.listByDate('2026-09-25')).length, 2);
  });
}

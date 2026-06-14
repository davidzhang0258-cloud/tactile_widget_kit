import 'package:flutter_test/flutter_test.dart';

import 'package:tactile_widget_kit/data/models.dart';

void main() {
  test('HabitTick toJson/fromJson round-trip', () {
    final tick = HabitTick(
      id: 't1',
      date: '2026-09-25',
      label: 'Reading',
      count: 3,
      updatedAt: 1,
    );

    final back = HabitTick.fromJson(tick.toJson());

    expect(back.id, 't1');
    expect(back.date, '2026-09-25');
    expect(back.label, 'Reading');
    expect(back.count, 3);
    expect(back.updatedAt, 1);
  });

  test('HabitTick copyWith preserves id and date', () {
    final tick = HabitTick(
      id: 't1',
      date: '2026-09-25',
      label: 'Reading',
      count: 3,
      updatedAt: 1,
    );

    final updated = tick.copyWith(count: 5, label: 'Writing');

    expect(updated.id, 't1');
    expect(updated.date, '2026-09-25');
    expect(updated.count, 5);
    expect(updated.label, 'Writing');
  });
}

/// Generic domain models, decoupled from storage and UI.
///
/// These models are intentionally minimal: they exist to demonstrate the
/// Repository + Hive architecture and the app → widget state-sync loop,
/// not to model any proprietary product domain.
library;

/// A single habit tick — the smallest unit of the demo state-sync loop.
///
/// The sample app increments a [HabitTick] in the UI, persists it through a
/// [TickRepository], and pushes a summary to the native home-screen widget.
class HabitTick {
  final String id;
  final String date; // yyyy-MM-dd
  final String label;
  final int count;
  final int updatedAt; // milliseconds since epoch

  const HabitTick({
    required this.id,
    required this.date,
    required this.label,
    required this.count,
    required this.updatedAt,
  });

  HabitTick copyWith({
    String? label,
    int? count,
    int? updatedAt,
  }) {
    return HabitTick(
      id: id,
      date: date,
      label: label ?? this.label,
      count: count ?? this.count,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'label': label,
        'count': count,
        'updated_at': updatedAt,
      };

  factory HabitTick.fromJson(Map<String, dynamic> json) => HabitTick(
        id: json['id'] as String,
        date: json['date'] as String,
        label: json['label'] as String? ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
        updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
      );
}

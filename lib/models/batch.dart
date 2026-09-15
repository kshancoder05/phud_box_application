enum CycleResult { pass, fail }

CycleResult resultFromString(String s) =>
    s.toUpperCase() == 'PASS' ? CycleResult.pass : CycleResult.fail;

String resultToLabel(CycleResult r) => r == CycleResult.pass ? 'PASS' : 'FAIL';

/// The batch currently inside the chamber, as reported live by the device.
class ActiveBatch {
  final String id;
  final String color;
  final List<String> instruments;
  final String uvIntensity;
  final DateTime? startedAt;

  ActiveBatch({
    required this.id,
    required this.color,
    required this.instruments,
    required this.uvIntensity,
    this.startedAt,
  });

  factory ActiveBatch.fromJson(Map<String, dynamic> json) {
    return ActiveBatch(
      id: json['id'] as String? ?? '--',
      color: json['color'] as String? ?? '--',
      instruments: (json['instruments'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      uvIntensity: json['uv_intensity'] as String? ?? '--',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
    );
  }
}

/// A completed cycle entry shown on the Data Logs screen.
class BatchLog {
  final String id;
  final String color;
  final String date;
  final CycleResult result;
  final String instruments;
  final String time;
  final String uvIntensity;
  final String? expiry;
  final String? error;

  BatchLog({
    required this.id,
    required this.color,
    required this.date,
    required this.result,
    required this.instruments,
    required this.time,
    required this.uvIntensity,
    this.expiry,
    this.error,
  });

  factory BatchLog.fromJson(Map<String, dynamic> json) {
    return BatchLog(
      id: json['id'] as String? ?? '--',
      color: json['color'] as String? ?? '--',
      date: json['date'] as String? ?? '--',
      result: resultFromString(json['result'] as String? ?? 'FAIL'),
      instruments: json['instruments'] as String? ?? '',
      time: json['time'] as String? ?? '',
      uvIntensity: json['uv_intensity'] as String? ?? '',
      expiry: json['expiry'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color,
      'date': date,
      'result': resultToLabel(result),
      'instruments': instruments,
      'time': time,
      'uvIntensity': uvIntensity,
      'expiry': expiry,
      'error': error,
    };
  }

  factory BatchLog.fromMap(Map<String, dynamic> map) {
    return BatchLog(
      id: map['id'] as String? ?? '--',
      color: map['color'] as String? ?? '--',
      date: map['date'] as String? ?? '--',
      result: resultFromString(map['result'] as String? ?? 'FAIL'),
      instruments: map['instruments'] as String? ?? '',
      time: map['time'] as String? ?? '',
      uvIntensity: map['uvIntensity'] as String? ?? '',
      expiry: map['expiry'] as String?,
      error: map['error'] as String?,
    );
  }
}

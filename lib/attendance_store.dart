
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum AttendanceStatus {
  present,
  absent,
  late,
}

class AttendanceRecord {
  final String studentId;
  final String date;
  final AttendanceStatus status;
  final String? markedAt;

  const AttendanceRecord({
    required this.studentId,
    required this.date,
    required this.status,
    this.markedAt,
  });

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'date': date,
        'status': status.name,
        'markedAt': markedAt,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      studentId: json['studentId'] as String,
      date: json['date'] as String,
      status: AttendanceStatus.values.firstWhere(
        (status) => status.name == json['status'],
      ),
      markedAt: json['markedAt'] as String?,
    );
  }
}

class AttendanceStore {
  AttendanceStore._();

  static final AttendanceStore instance = AttendanceStore._();

  static const String _storageKey = 'verdant_attendance_v1';

  final ValueNotifier<List<AttendanceRecord>> records =
      ValueNotifier<List<AttendanceRecord>>([]);

  bool _initialized = false;
  Future<void>? _initialization;
  Future<void> _writeQueue = Future<void>.value();

  List<AttendanceRecord> get attendance => records.value;

  Future<void> initialize() {
    return _initialization ??= _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);

    if (saved != null) {
      final decoded = jsonDecode(saved) as List<dynamic>;
      records.value = decoded
          .map((item) => AttendanceRecord.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList();
    }

    _initialized = true;
  }

  String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  AttendanceRecord? getRecord(String studentId, DateTime date) {
    final key = dateKey(date);

    for (final record in attendance) {
      if (record.studentId == studentId && record.date == key) {
        return record;
      }
    }

    return null;
  }

  void markAttendance({
    required String studentId,
    required DateTime date,
    required AttendanceStatus status,
  }) {
    if (!_initialized) {
      throw StateError('Call AttendanceStore.initialize() first.');
    }

    final key = dateKey(date);
    final now = DateTime.now().toIso8601String();

    final updated = AttendanceRecord(
      studentId: studentId,
      date: key,
      status: status,
      markedAt: now,
    );

    final existingIndex = records.value.indexWhere(
      (record) => record.studentId == studentId && record.date == key,
    );

    final next = List<AttendanceRecord>.from(records.value);

    if (existingIndex >= 0) {
      next[existingIndex] = updated;
    } else {
      next.add(updated);
    }

    records.value = next;
    _save();
  }

  void _save() {
    final snapshot = jsonEncode(
      records.value.map((record) => record.toJson()).toList(),
    );

    _writeQueue = _writeQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final saved = await prefs.setString(_storageKey, snapshot);

      if (!saved) {
        throw StateError('Could not save attendance records.');
      }
    });

    _writeQueue = _writeQueue.catchError((Object error) {
      debugPrint('Attendance storage error: $error');
    });
  }

  Future<void> waitForPendingSaves() => _writeQueue;
}

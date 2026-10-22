
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentRecord {
  final String id;
  final String name;
  final String department;
  final String email;
  final String year;
  final String status;
  final String enrolledOn;

  const StudentRecord({
    required this.id,
    required this.name,
    required this.department,
    required this.email,
    required this.year,
    required this.status,
    required this.enrolledOn,
  });

  StudentRecord copyWith({
    String? name,
    String? department,
    String? email,
    String? year,
    String? status,
    String? enrolledOn,
  }) {
    return StudentRecord(
      id: id,
      name: name ?? this.name,
      department: department ?? this.department,
      email: email ?? this.email,
      year: year ?? this.year,
      status: status ?? this.status,
      enrolledOn: enrolledOn ?? this.enrolledOn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'email': email,
      'year': year,
      'status': status,
      'enrolledOn': enrolledOn,
    };
  }

  factory StudentRecord.fromJson(Map<String, dynamic> json) {
    return StudentRecord(
      id: json['id'] as String,
      name: json['name'] as String,
      department: json['department'] as String,
      email: json['email'] as String,
      year: json['year'] as String,
      status: json['status'] as String,
      enrolledOn: json['enrolledOn'] as String,
    );
  }
}

class StudentStore {
  StudentStore._();

  static final StudentStore instance = StudentStore._();

  static const String _storageKey = 'verdant_students_v1';

  final ValueNotifier<List<StudentRecord>> records =
      ValueNotifier<List<StudentRecord>>(_defaultStudents());

  bool _initialized = false;
  Future<void>? _initialization;
  Future<void> _writeQueue = Future<void>.value();

  List<StudentRecord> get students => records.value;

  static List<StudentRecord> _defaultStudents() {
    return const [
      StudentRecord(
        id: 'STU001',
        name: 'Aarav Sharma',
        department: 'Computer Science',
        email: 'aarav.sharma@example.com',
        year: '3rd Year',
        status: 'Enrolled',
        enrolledOn: '12 Oct 2026',
      ),
      StudentRecord(
        id: 'STU002',
        name: 'Ananya Patel',
        department: 'Information Technology',
        email: 'ananya.patel@example.com',
        year: '2nd Year',
        status: 'Enrolled',
        enrolledOn: '13 Oct 2026',
      ),
      StudentRecord(
        id: 'STU003',
        name: 'Rohan Verma',
        department: 'Computer Science',
        email: 'rohan.verma@example.com',
        year: '4th Year',
        status: 'Pending',
        enrolledOn: '15 Oct 2026',
      ),
      StudentRecord(
        id: 'STU004',
        name: 'Priya Singh',
        department: 'Electronics',
        email: 'priya.singh@example.com',
        year: '1st Year',
        status: 'Enrolled',
        enrolledOn: '16 Oct 2026',
      ),
      StudentRecord(
        id: 'STU005',
        name: 'Kabir Mehta',
        department: 'Information Technology',
        email: 'kabir.mehta@example.com',
        year: '3rd Year',
        status: 'Pending',
        enrolledOn: '18 Oct 2026',
      ),
      StudentRecord(
        id: 'STU006',
        name: 'Ishita Gupta',
        department: 'Computer Science',
        email: 'ishita.gupta@example.com',
        year: '2nd Year',
        status: 'Enrolled',
        enrolledOn: '19 Oct 2026',
      ),
    ];
  }

  Future<void> initialize() {
    return _initialization ??= _loadStudents();
  }

  Future<void> _loadStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_storageKey);

    if (savedData == null) {
      // First launch: keep the demo students and save them.
      _initialized = true;
      await _saveSnapshot();
      return;
    }

    try {
      final decoded = jsonDecode(savedData) as List<dynamic>;

      final loadedStudents = decoded.map((item) {
        return StudentRecord.fromJson(
          Map<String, dynamic>.from(item as Map),
        );
      }).toList();

      records.value = loadedStudents;
      _initialized = true;
    } catch (error) {
      // Do not overwrite existing saved data automatically if it is corrupt.
      throw FormatException(
        'Could not read saved student records. '
        'The saved data has been left unchanged. Details: $error',
      );
    }
  }

  bool containsId(String id) {
    final normalizedId = id.trim().toLowerCase();

    return students.any(
      (student) => student.id.trim().toLowerCase() == normalizedId,
    );
  }

  void addStudent(StudentRecord student) {
    if (!_initialized) {
      throw StateError('StudentStore.initialize() must run first.');
    }

    if (containsId(student.id)) {
      throw ArgumentError('Student ID already exists: ${student.id}');
    }

    records.value = [student, ...students];
    _queueSave();
  }

  void updateStudent(StudentRecord updatedStudent) {
    if (!_initialized) {
      throw StateError('StudentStore.initialize() must run first.');
    }

    records.value = students.map((student) {
      return student.id == updatedStudent.id ? updatedStudent : student;
    }).toList();

    _queueSave();
  }

  void deleteStudent(String id) {
    if (!_initialized) {
      throw StateError('StudentStore.initialize() must run first.');
    }

    records.value = students
        .where((student) => student.id != id)
        .toList();

    _queueSave();
  }

  void _queueSave() {
    final snapshot = jsonEncode(
      students.map((student) => student.toJson()).toList(),
    );

    // Queue writes in order so an older save cannot overwrite a newer one.
    _writeQueue = _writeQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_storageKey, snapshot);

      if (!success) {
        throw StateError('Could not save student records.');
      }
    });

    // Report storage errors without crashing the UI.
    unawaited(
      _writeQueue.then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('Student storage error: $error');
        },
      ),
    );
  }

  Future<void> _saveSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString(
      _storageKey,
      jsonEncode(students.map((student) => student.toJson()).toList()),
    );

    if (!success) {
      throw StateError('Could not save the initial student records.');
    }
  }

  Future<void> waitForPendingSaves() => _writeQueue;
}

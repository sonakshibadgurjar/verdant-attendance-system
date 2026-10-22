
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'student_store.dart';
import 'attendance_store.dart';

class ReportColors {
  static const background = Color(0xFF051F20);
  static const surface = Color(0xFF0B2B26);
  static const card = Color(0xFF163832);
  static const accent = Color(0xFF235347);
  static const lightGreen = Color(0xFF8EB69B);
  static const paleGreen = Color(0xFFDAF1DE);
  static const muted = Color(0xFF9CB8AA);
  static const red = Color(0xFFFF8A80);
  static const orange = Color(0xFFFFCC80);
}

class ReportRecord {
  final String studentId;
  final String name;
  final String department;
  final String email;
  final String year;
  final int present;
  final int absent;
  final int late;

  const ReportRecord({
    required this.studentId,
    required this.name,
    required this.department,
    required this.email,
    required this.year,
    required this.present,
    required this.absent,
    required this.late,
  });

  int get total => present + absent + late;

  double get percentage =>
      total == 0 ? 0 : ((present + late) / total) * 100;
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _searchQuery = '';
  String _selectedDepartment = 'All Departments';
  String _selectedPeriod = 'This Month';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _periods = const [
    'Today',
    'This Week',
    'This Month',
    'Last Month',
    'This Semester',
    'All Time',
  ];

  @override
  void initState() {
    super.initState();
    StudentStore.instance.records.addListener(_refresh);
    AttendanceStore.instance.records.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    StudentStore.instance.records.removeListener(_refresh);
    AttendanceStore.instance.records.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _departments {
    final departments = StudentStore.instance.students
        .map((student) => student.department.trim())
        .where((department) => department.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return ['All Departments', ...departments];
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _matchesPeriod(DateTime date) {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final selectedDate = _dateOnly(date);

    switch (_selectedPeriod) {
      case 'Today':
        return selectedDate == today;

      case 'This Week':
        final weekStart = today.subtract(
          Duration(days: today.weekday - DateTime.monday),
        );
        return !selectedDate.isBefore(weekStart) &&
            !selectedDate.isAfter(today);

      case 'This Month':
        final monthStart = DateTime(now.year, now.month, 1);
        return !selectedDate.isBefore(monthStart) &&
            !selectedDate.isAfter(today);

      case 'Last Month':
        final monthStart = DateTime(now.year, now.month - 1, 1);
        final thisMonthStart = DateTime(now.year, now.month, 1);
        return !selectedDate.isBefore(monthStart) &&
            selectedDate.isBefore(thisMonthStart);

      case 'This Semester':
        final semesterStart = now.month <= 6
            ? DateTime(now.year, 1, 1)
            : DateTime(now.year, 7, 1);
        return !selectedDate.isBefore(semesterStart) &&
            !selectedDate.isAfter(today);

      case 'All Time':
        return !selectedDate.isAfter(today);

      default:
        return true;
    }
  }

  List<ReportRecord> get _allReportRecords {
    final students = StudentStore.instance.students;
    final attendanceRecords = AttendanceStore.instance.attendance;

    return students.map((student) {
      final studentAttendance = attendanceRecords.where((record) {
        if (record.studentId != student.id) return false;

        final date = DateTime.tryParse(record.date);
        if (date == null) return false;

        return _matchesPeriod(date);
      });

      var present = 0;
      var absent = 0;
      var late = 0;

      for (final record in studentAttendance) {
        switch (record.status) {
          case AttendanceStatus.present:
            present++;
            break;
          case AttendanceStatus.absent:
            absent++;
            break;
          case AttendanceStatus.late:
            late++;
            break;
        }
      }

      return ReportRecord(
        studentId: student.id,
        name: student.name,
        department: student.department,
        email: student.email,
        year: student.year,
        present: present,
        absent: absent,
        late: late,
      );
    }).toList();
  }

  List<ReportRecord> get _filteredRecords {
    final query = _searchQuery.trim().toLowerCase();

    return _allReportRecords.where((record) {
      final matchesDepartment =
          _selectedDepartment == 'All Departments' ||
          record.department == _selectedDepartment;

      final matchesSearch = query.isEmpty ||
          record.name.toLowerCase().contains(query) ||
          record.studentId.toLowerCase().contains(query) ||
          record.email.toLowerCase().contains(query) ||
          record.department.toLowerCase().contains(query);

      return matchesDepartment && matchesSearch;
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  int get _totalPresent =>
      _filteredRecords.fold(0, (sum, record) => sum + record.present);

  int get _totalAbsent =>
      _filteredRecords.fold(0, (sum, record) => sum + record.absent);

  int get _totalLate =>
      _filteredRecords.fold(0, (sum, record) => sum + record.late);

  int get _totalMarked => _totalPresent + _totalAbsent + _totalLate;

  double get _overallPercentage => _totalMarked == 0
      ? 0
      : ((_totalPresent + _totalLate) / _totalMarked) * 100;

  Future<void> _exportCsv() async {
    final records = _filteredRecords;

    if (records.isEmpty) {
      _showMessage('No report data available to export.');
      return;
    }

    String escapeCsv(String value) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }

    final lines = <String>[
      [
        'Student ID',
        'Name',
        'Department',
        'Email',
        'Year',
        'Present',
        'Absent',
        'Late',
        'Total Marked',
        'Attendance Percentage',
        'Period',
      ].map(escapeCsv).join(','),
    ];

    for (final record in records) {
      lines.add([
        record.studentId,
        record.name,
        record.department,
        record.email,
        record.year,
        '${record.present}',
        '${record.absent}',
        '${record.late}',
        '${record.total}',
        '${record.percentage.toStringAsFixed(1)}%',
        _selectedPeriod,
      ].map(escapeCsv).join(','));
    }

    await Clipboard.setData(ClipboardData(text: lines.join('\n')));

    if (!mounted) return;
    _showMessage(
      'CSV report copied. Paste it into Excel or Google Sheets.',
    );
  }

  void _showMessage(String message) {
  if (!mounted) return;

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: ReportColors.paleGreen,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: ReportColors.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        showCloseIcon: true,
      ),
    );
}

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;

    return Scaffold(
      backgroundColor: ReportColors.background,
      appBar: AppBar(
        backgroundColor: ReportColors.surface,
        foregroundColor: ReportColors.paleGreen,
        elevation: 0,
        title: const Text(
          'Attendance Reports',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 22),
                  _buildFilters(),
                  const SizedBox(height: 22),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildOverview(),
                  const SizedBox(height: 24),
                  _buildReportList(records),
                  const SizedBox(height: 18),
                  _buildInformationNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reports & Analytics',
                style: TextStyle(
                  color: ReportColors.paleGreen,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Review attendance calculated from saved records.',
                style: TextStyle(
                  color: ReportColors.muted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _exportCsv,
          icon: const Icon(Icons.file_download_outlined, size: 18),
          label: const Text('Export CSV'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ReportColors.lightGreen,
            foregroundColor: ReportColors.background,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportColors.accent),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 650;

          final search = TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(color: ReportColors.paleGreen),
            decoration: _inputDecoration(
              'Search students...',
              Icons.search,
            ).copyWith(
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(
                        Icons.close,
                        color: ReportColors.muted,
                      ),
                    ),
            ),
          );

          final department = DropdownButtonFormField<String>(
            initialValue: _departments.contains(_selectedDepartment)
                ? _selectedDepartment
                : 'All Departments',
            dropdownColor: ReportColors.card,
            style: const TextStyle(color: ReportColors.paleGreen),
            decoration: _inputDecoration('Department', Icons.apartment),
            items: _departments.map((department) {
              return DropdownMenuItem(
                value: department,
                child: Text(
                  department,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedDepartment = value);
              }
            },
          );

          final period = DropdownButtonFormField<String>(
            initialValue: _selectedPeriod,
            dropdownColor: ReportColors.card,
            style: const TextStyle(color: ReportColors.paleGreen),
            decoration: _inputDecoration(
              'Attendance period',
              Icons.calendar_month,
            ),
            items: _periods.map((period) {
              return DropdownMenuItem(
                value: period,
                child: Text(period),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPeriod = value);
              }
            },
          );

          if (narrow) {
            return Column(
              children: [
                search,
                const SizedBox(height: 12),
                department,
                const SizedBox(height: 12),
                period,
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 2, child: search),
              const SizedBox(width: 12),
              Expanded(child: department),
              const SizedBox(width: 12),
              Expanded(child: period),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: ReportColors.muted),
      prefixIcon: Icon(icon, color: ReportColors.lightGreen, size: 20),
      filled: true,
      fillColor: ReportColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: ReportColors.accent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: ReportColors.lightGreen),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 500 ? 2 : 4;
        const gap = 12.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;

        final cards = [
          _SummaryData(
            title: 'Students',
            value: '${_filteredRecords.length}',
            icon: Icons.people_outline,
            color: ReportColors.lightGreen,
          ),
          _SummaryData(
            title: 'Present',
            value: '$_totalPresent',
            icon: Icons.check_circle_outline,
            color: ReportColors.paleGreen,
          ),
          _SummaryData(
            title: 'Absent',
            value: '$_totalAbsent',
            icon: Icons.cancel_outlined,
            color: ReportColors.red,
          ),
          _SummaryData(
            title: 'Late',
            value: '$_totalLate',
            icon: Icons.schedule,
            color: ReportColors.orange,
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards.map((data) {
            return SizedBox(
              width: cardWidth,
              child: _buildSummaryCard(data),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSummaryCard(_SummaryData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportColors.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ReportColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, color: data.color, size: 24),
          const SizedBox(height: 15),
          Text(
            data.value,
            style: const TextStyle(
              color: ReportColors.paleGreen,
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            style: const TextStyle(
              color: ReportColors.muted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final percentage = _overallPercentage;
    final marked = _totalMarked;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ReportColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Overview',
            style: TextStyle(
              color: ReportColors.paleGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Period: $_selectedPeriod',
            style: const TextStyle(
              color: ReportColors.muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: ReportColors.lightGreen,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$marked attendance entries',
                style: const TextStyle(
                  color: ReportColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: ReportColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(
                ReportColors.lightGreen,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: [
              _legendItem(
                'Present',
                _totalPresent,
                ReportColors.paleGreen,
              ),
              _legendItem(
                'Absent',
                _totalAbsent,
                ReportColors.red,
              ),
              _legendItem(
                'Late',
                _totalLate,
                ReportColors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Attendance rate = (Present + Late) ÷ Total marked entries.',
            style: TextStyle(
              color: ReportColors.muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '$label: $count',
          style: const TextStyle(
            color: ReportColors.paleGreen,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildReportList(List<ReportRecord> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Student Attendance',
                style: TextStyle(
                  color: ReportColors.paleGreen,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${records.length} students',
              style: const TextStyle(
                color: ReportColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: ReportColors.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: ReportColors.accent),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 40,
                  color: ReportColors.lightGreen,
                ),
                SizedBox(height: 12),
                Text(
                  'No report records found',
                  style: TextStyle(
                    color: ReportColors.paleGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Try another period or department, or mark attendance first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ReportColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ...records.map(_buildStudentCard),
      ],
    );
  }

  Widget _buildStudentCard(ReportRecord record) {
    final percentage = record.percentage;
    final Color percentageColor = record.total == 0
        ? ReportColors.muted
        : percentage >= 75
            ? ReportColors.lightGreen
            : ReportColors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportColors.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: ReportColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: ReportColors.accent,
                child: Text(
                  record.name.isEmpty
                      ? '?'
                      : record.name.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: ReportColors.paleGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.name,
                      style: const TextStyle(
                        color: ReportColors.paleGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.studentId}  •  ${record.department}',
                      style: const TextStyle(
                        color: ReportColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (record.email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        record.email,
                        style: const TextStyle(
                          color: ReportColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record.total == 0
                        ? '—'
                        : '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: percentageColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Attendance',
                    style: TextStyle(
                      color: ReportColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _countChip(
                  'Present',
                  record.present,
                  ReportColors.paleGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _countChip(
                  'Absent',
                  record.absent,
                  ReportColors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _countChip(
                  'Late',
                  record.late,
                  ReportColors.orange,
                ),
              ),
            ],
          ),
          if (record.total == 0) ...[
            const SizedBox(height: 10),
            const Text(
              'No attendance has been marked for this period.',
              style: TextStyle(
                color: ReportColors.muted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _countChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: ReportColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: ReportColors.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ReportColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: ReportColors.lightGreen,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'These reports use attendance saved in this app. '
              'Students with no marked attendance show zero counts. '
              'CSV export copies the currently filtered report to your clipboard.',
              style: TextStyle(
                color: ReportColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

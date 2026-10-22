import 'package:flutter/material.dart';

import 'attendance_store.dart' as attendance;
import 'student_store.dart';

class LiveColors {
  static const Color background = Color(0xFF051F20);
  static const Color surface = Color(0xFF0B2B26);
  static const Color card = Color(0xFF163832);
  static const Color accent = Color(0xFF235347);
  static const Color lightGreen = Color(0xFF8EB69B);
  static const Color paleGreen = Color(0xFFDAF1DE);

  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFC857);
  static const Color danger = Color(0xFFFF6B6B);
}

class LiveAttendancePage extends StatefulWidget {
  const LiveAttendancePage({super.key});

  @override
  State<LiveAttendancePage> createState() => _LiveAttendancePageState();
}

class _LiveAttendancePageState extends State<LiveAttendancePage> {
  DateTime _attendanceDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    StudentStore.instance.records.addListener(_refresh);
    attendance.AttendanceStore.instance.records.addListener(_refresh);
  }

  @override
  void dispose() {
    StudentStore.instance.records.removeListener(_refresh);
    attendance.AttendanceStore.instance.records.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _chooseAttendanceDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _attendanceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: LiveColors.lightGreen,
              onPrimary: LiveColors.background,
              surface: LiveColors.surface,
              onSurface: LiveColors.paleGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _attendanceDate = selected;
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  List<StudentRecord> get _students {
    return StudentStore.instance.students;
  }

  attendance.AttendanceRecord? _getRecord(String studentId) {
    return attendance.AttendanceStore.instance.getRecord(
      studentId,
      _attendanceDate,
    );
  }

  int _countStatus(attendance.AttendanceStatus status) {
    return _students.where((student) {
      return _getRecord(student.id)?.status == status;
    }).length;
  }

  int get _unmarkedCount {
    return _students.length -
        _countStatus(attendance.AttendanceStatus.present) -
        _countStatus(attendance.AttendanceStatus.absent) -
        _countStatus(attendance.AttendanceStatus.late);
  }

  Color _statusColor(attendance.AttendanceStatus? status) {
    switch (status) {
      case attendance.AttendanceStatus.present:
        return LiveColors.success;
      case attendance.AttendanceStatus.absent:
        return LiveColors.danger;
      case attendance.AttendanceStatus.late:
        return LiveColors.warning;
      case null:
        return LiveColors.lightGreen;
    }
  }

  String _statusLabel(attendance.AttendanceStatus? status) {
    switch (status) {
      case attendance.AttendanceStatus.present:
        return 'Present';
      case attendance.AttendanceStatus.absent:
        return 'Absent';
      case attendance.AttendanceStatus.late:
        return 'Late';
      case null:
        return 'Not marked';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiveColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(isCompact ? 16 : 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isCompact),
                      const SizedBox(height: 24),
                      _buildNotice(),
                      const SizedBox(height: 24),
                      _buildSummaryCards(isCompact),
                      const SizedBox(height: 24),
                      _buildManualAttendancePanel(isCompact),
                      const SizedBox(height: 24),
                      _buildInformationPanel(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: LiveColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.fact_check_outlined,
            color: LiveColors.lightGreen,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Attendance',
                style: TextStyle(
                  color: LiveColors.paleGreen,
                  fontSize: isCompact ? 23 : 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Manage and record daily student attendance.',
                style: TextStyle(
                  color: LiveColors.lightGreen,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LiveColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LiveColors.accent),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: LiveColors.lightGreen,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance management',
                  style: TextStyle(
                    color: LiveColors.paleGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Select a date and mark each student as Present, '
                  'Absent, or Late. Your records are saved locally '
                  'on this device.',
                  style: TextStyle(
                    color: LiveColors.lightGreen,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(bool isCompact) {
    final cards = [
      _SummaryData(
        title: 'Total Students',
        value: '${_students.length}',
        icon: Icons.people_outline,
        color: LiveColors.lightGreen,
      ),
      _SummaryData(
        title: 'Present',
        value: '${_countStatus(attendance.AttendanceStatus.present)}',
        icon: Icons.check_circle_outline,
        color: LiveColors.success,
      ),
      _SummaryData(
        title: 'Absent',
        value: '${_countStatus(attendance.AttendanceStatus.absent)}',
        icon: Icons.cancel_outlined,
        color: LiveColors.danger,
      ),
      _SummaryData(
        title: 'Late',
        value: '${_countStatus(attendance.AttendanceStatus.late)}',
        icon: Icons.schedule,
        color: LiveColors.warning,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 500
            ? 2
            : constraints.maxWidth < 850
                ? 2
                : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 112,
          ),
          itemBuilder: (context, index) {
            final item = cards[index];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: LiveColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LiveColors.accent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(item.icon, color: item.color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: LiveColors.lightGreen,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    item.value,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildManualAttendancePanel(bool isCompact) {
    final students = _students;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 16 : 22),
      decoration: BoxDecoration(
        color: LiveColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LiveColors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_calendar_outlined,
                color: LiveColors.lightGreen,
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Manual Attendance',
                  style: TextStyle(
                    color: LiveColors.paleGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${students.length} students',
                style: const TextStyle(
                  color: LiveColors.lightGreen,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a date, then select an attendance status for each student.',
            style: TextStyle(
              color: LiveColors.lightGreen,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _chooseAttendanceDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Attendance date: ${_formatDate(_attendanceDate)}'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LiveColors.paleGreen,
                side: const BorderSide(color: LiveColors.accent),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      color: LiveColors.lightGreen,
                      size: 36,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No students found.',
                      style: TextStyle(
                        color: LiveColors.paleGreen,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Enroll students first to record attendance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LiveColors.lightGreen,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...students.map((student) {
              final saved = _getRecord(student.id);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: LiveColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LiveColors.accent),
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStudentInfo(
                            student.name,
                            student.id,
                            saved?.status,
                          ),
                          const SizedBox(height: 14),
                          _buildStatusDropdown(student.id, saved?.status),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildStudentInfo(
                              student.name,
                              student.id,
                              saved?.status,
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 190,
                            child: _buildStatusDropdown(
                              student.id,
                              saved?.status,
                            ),
                          ),
                        ],
                      ),
              );
            }),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.pending_actions_outlined,
                color: LiveColors.lightGreen,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_unmarkedCount student(s) not marked for this date.',
                  style: const TextStyle(
                    color: LiveColors.lightGreen,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentInfo(
    String name,
    String studentId,
    attendance.AttendanceStatus? status,
  ) {
    final color = _statusColor(status);

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: LiveColors.accent,
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: const TextStyle(
              color: LiveColors.paleGreen,
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
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LiveColors.paleGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                studentId,
                style: const TextStyle(
                  color: LiveColors.lightGreen,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown(
    String studentId,
    attendance.AttendanceStatus? currentStatus,
  ) {
    return DropdownButtonFormField<attendance.AttendanceStatus>(
      initialValue: currentStatus,
      isExpanded: true,
      dropdownColor: LiveColors.card,
      hint: const Text(
        'Select status',
        style: TextStyle(
          color: LiveColors.lightGreen,
          fontSize: 12,
        ),
      ),
      style: const TextStyle(
        color: LiveColors.paleGreen,
        fontSize: 12,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: LiveColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: LiveColors.accent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: LiveColors.lightGreen),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: attendance.AttendanceStatus.present,
          child: Text('Present'),
        ),
        DropdownMenuItem(
          value: attendance.AttendanceStatus.absent,
          child: Text('Absent'),
        ),
        DropdownMenuItem(
          value: attendance.AttendanceStatus.late,
          child: Text('Late'),
        ),
      ],
      onChanged: (status) {
        if (status == null) return;

        try {
          attendance.AttendanceStore.instance.markAttendance(
            studentId: studentId,
            date: _attendanceDate,
            status: status,
          );

          setState(() {});

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$studentId marked ${_statusLabel(status).toLowerCase()}.',
              ),
              backgroundColor: LiveColors.accent,
              duration: const Duration(seconds: 1),
            ),
          );
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not save attendance: $error'),
              backgroundColor: LiveColors.danger,
            ),
          );
        }
      },
    );
  }

  Widget _buildInformationPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LiveColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LiveColors.accent),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.storage_outlined,
            color: LiveColors.lightGreen,
            size: 22,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local attendance storage',
                  style: TextStyle(
                    color: LiveColors.paleGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Attendance is stored on this device. You can change a '
                  'student’s status for the selected date at any time. '
                  'Camera-based face recognition is not connected to this '
                  'manual attendance page yet.',
                  style: TextStyle(
                    color: LiveColors.lightGreen,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ],
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
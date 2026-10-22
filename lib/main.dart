import 'package:flutter/material.dart';

import 'student_enrollment_page.dart';
import 'students_page.dart';
import 'live_attendance_page.dart';
import 'reports_page.dart';
import 'settings_page.dart';
import 'student_store.dart';
import 'attendance_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StudentStore.instance.initialize();
  await AttendanceStore.instance.initialize();

  runApp(const AttendanceApp());
}

// ============================================================
// COLOR PALETTE
// ============================================================

class AppColors {
  static const background = Color(0xFF051F20);
  static const sidebar = Color(0xFF0B2B26);
  static const surface = Color(0xFF163832);
  static const primary = Color(0xFF235347);
  static const sage = Color(0xFF8EB69B);
  static const light = Color(0xFFDAF1DE);

  static const muted = Color(0xFF9DB7A6);
  static const border = Color(0xFF2B5145);
  static const success = Color(0xFF8EB69B);
}

// ============================================================
// APP
// ============================================================

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Verdant | Face Attendance',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Arial',
        colorScheme: const ColorScheme.dark(
          primary: AppColors.sage,
          surface: AppColors.surface,
          onSurface: AppColors.light,
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String selectedPage = 'Dashboard';

  final List<Map<String, dynamic>> attendance = [
    {
      'id': 'STU001',
      'name': 'Aarav Sharma',
      'time': '09:02 AM',
      'status': 'Present',
    },
    {
      'id': 'STU003',
      'name': 'Priya Verma',
      'time': '09:05 AM',
      'status': 'Present',
    },
    {
      'id': 'STU002',
      'name': 'Rohan Mehta',
      'time': '09:08 AM',
      'status': 'Present',
    },
    {
      'id': 'UNKNOWN',
      'name': 'Unknown Person',
      'time': '09:11 AM',
      'status': 'Unknown',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (isDesktop)
                  SizedBox(
                    width: 248,
                    child: Sidebar(
                      selectedPage: selectedPage,
                      onSelect: _selectPage,
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (!isDesktop)
                        _mobileNavigation()
                      else
                        const SizedBox.shrink(),
                      Expanded(
                        child: selectedPage == 'Dashboard'
                        ? SingleChildScrollView(
                          padding: EdgeInsets.all(isDesktop ? 32 : 18),
                          child: _dashboardContent(isDesktop),
                        )
                        : selectedPage == 'Enrollment'
                        ? StudentEnrollmentPage(
                          onBack: () => _selectPage('Dashboard'),
                        )
                        : _placeholderPage(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectPage(String page) {
    setState(() => selectedPage = page);
  }

  Widget _mobileNavigation() {
    return Container(
      color: AppColors.sidebar,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.center_focus_strong_rounded,
            color: AppColors.sage,
            size: 30,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'VERDANT',
              style: TextStyle(
                color: AppColors.light,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.surface,
            icon: const Icon(Icons.menu_rounded, color: AppColors.light),
            onSelected: _selectPage,
            itemBuilder: (context) =>
                [
                      'Dashboard',
                      'Students',
                      'Enrollment',
                      'Live Attendance',
                      'Reports',
                      'Settings',
                    ]
                    .map(
                      (page) => PopupMenuItem(value: page, child: Text(page)),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _dashboardContent(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar(isDesktop),
        const SizedBox(height: 32),
        _welcomeSection(),
        const SizedBox(height: 26),
        _statistics(isDesktop),
        const SizedBox(height: 26),
        _recognitionPanel(),
        const SizedBox(height: 26),
        _attendanceSection(),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'VERDANT • FACE RECOGNITION & ATTENDANCE',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // TOP BAR

  Widget _topBar(bool isDesktop) {
    return Row(
      children: [
        const Icon(Icons.grid_view_rounded, color: AppColors.sage, size: 20),
        const SizedBox(width: 10),
        const Text(
          'Workspace',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: AppColors.sage, size: 8),
              SizedBox(width: 8),
              Text(
                'System online',
                style: TextStyle(color: AppColors.light, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.light,
          ),
        ),
      ],
    );
  }

  // WELCOME

  Widget _welcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Good morning 👋',
          style: TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 8),
        const Text(
          'Attendance Overview',
          style: TextStyle(
            color: AppColors.light,
            fontSize: 30,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Monitor students, recognize faces, and manage attendance.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _actionButton(
              'Register Student',
              Icons.person_add_alt_1_rounded,
              () => _selectPage('Enrollment'),
            ),
            _actionButton(
              'Live Attendance',
              Icons.videocam_rounded,
              () => _selectPage('Live Attendance'),
              outlined: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor: outlined ? Colors.transparent : AppColors.primary,
        foregroundColor: AppColors.light,
        side: BorderSide(
          color: outlined ? AppColors.border : AppColors.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // STATISTICS

  Widget _statistics(bool isDesktop) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth >= 850
            ? 4
            : constraints.maxWidth >= 480
            ? 2
            : 1;

        final items = [
          _StatData(
            'Total Students',
            '24',
            '+4 registered',
            Icons.groups_rounded,
          ),
          _StatData(
            'Present Today',
            '18',
            '75% of students',
            Icons.how_to_reg_rounded,
          ),
          _StatData(
            'Unknown Faces',
            '02',
            'Needs review',
            Icons.face_retouching_off_rounded,
          ),
          _StatData(
            'Recognition Rate',
            '—',
            'Awaiting API data',
            Icons.center_focus_strong_rounded,
          ),
        ];

        final spacing = 16.0;
        final width = (constraints.maxWidth - spacing * (count - 1)) / count;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map((item) => SizedBox(width: width, child: _statCard(item)))
              .toList(),
        );
      },
    );
  }

  Widget _statCard(_StatData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(data.icon, color: AppColors.sage, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            data.value,
            style: const TextStyle(
              color: AppColors.light,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.subtitle,
            style: const TextStyle(color: AppColors.sage, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // RECOGNITION PANEL

  Widget _recognitionPanel() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surface, AppColors.sidebar],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 550;

          final status = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RECOGNITION ENGINE',
                style: TextStyle(
                  color: AppColors.sage,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your classroom,\nintelligently monitored.',
                style: TextStyle(
                  color: AppColors.light,
                  fontSize: 22,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Connect your backend to start face recognition '
                'and record attendance in real time.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              _actionButton(
                'Open Live Monitoring',
                Icons.arrow_forward_rounded,
                () => _selectPage('Live Attendance'),
              ),
            ],
          );

          final visual = Container(
            width: compact ? double.infinity : 220,
            height: 185,
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 135,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.sage, width: 1.5),
                    borderRadius: BorderRadius.circular(48),
                  ),
                  child: const Icon(
                    Icons.face_rounded,
                    size: 76,
                    color: AppColors.sage,
                  ),
                ),
                Positioned(top: 12, left: 12, child: _corner()),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Transform.rotate(angle: 1.5708, child: _corner()),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Transform.rotate(angle: -1.5708, child: _corner()),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Transform.rotate(angle: 3.1416, child: _corner()),
                ),
              ],
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [status, const SizedBox(height: 24), visual],
            );
          }

          return Row(
            children: [
              Expanded(child: status),
              const SizedBox(width: 20),
              visual,
            ],
          );
        },
      ),
    );
  }

  Widget _corner() {
    return Container(
      width: 15,
      height: 15,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.sage, width: 2),
          left: BorderSide(color: AppColors.sage, width: 2),
        ),
      ),
    );
  }

  // ATTENDANCE TABLE

  Widget _attendanceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        color: AppColors.light,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Illustrative sample records',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _selectPage('Reports'),
                child: const Text(
                  'View reports →',
                  style: TextStyle(color: AppColors.sage),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 42,
              dataRowMinHeight: 58,
              dataRowMaxHeight: 64,
              horizontalMargin: 8,
              columnSpacing: 30,
              headingTextStyle: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              dataTextStyle: const TextStyle(
                color: AppColors.light,
                fontSize: 12,
              ),
              columns: const [
                DataColumn(label: Text('STUDENT')),
                DataColumn(label: Text('STUDENT ID')),
                DataColumn(label: Text('TIME')),
                DataColumn(label: Text('STATUS')),
              ],
              rows: attendance.map((student) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              student['status'] == 'Unknown'
                                  ? Icons.person_off_rounded
                                  : Icons.person_rounded,
                              size: 16,
                              color: AppColors.light,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(student['name']),
                        ],
                      ),
                    ),
                    DataCell(Text(student['id'])),
                    DataCell(Text(student['time'])),
                    DataCell(_statusBadge(student['status'])),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final unknown = status == 'Unknown';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: unknown ? AppColors.background : AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: unknown
              ? AppColors.border
              : AppColors.sage.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: unknown ? AppColors.muted : AppColors.light,
          fontSize: 11,
        ),
      ),
    );
  }

  // TEMPORARY PLACEHOLDER FOR OTHER PAGES

  Widget _placeholderPage() {
    if (selectedPage == 'Students') {
      return const StudentsPage();
    }

    if (selectedPage == 'Live Attendance') {
      return const LiveAttendancePage();
    }

    if (selectedPage == 'Reports') {
      return const ReportsPage();
    }

    if (selectedPage == 'Settings') {
      return const SettingsPage();
    }

    final descriptions = {
      'Students': 'View and manage enrolled students.',
      'Enrollment': 'Register a student using six face photos.',
      'Live Attendance': 'Monitor faces and record attendance.',
      'Reports': 'Review attendance sessions and student records.',
      'Settings': 'Configure the backend connection and system.',
    };

    final icons = {
      'Students': Icons.groups_rounded,
      'Enrollment': Icons.person_add_alt_1_rounded,
      'Live Attendance': Icons.videocam_rounded,
      'Reports': Icons.assessment_rounded,
      'Settings': Icons.settings_rounded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedPage,
          style: const TextStyle(
            color: AppColors.light,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          descriptions[selectedPage] ?? 'System page',
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        const SizedBox(height: 30),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(
                icons[selectedPage] ?? Icons.construction_rounded,
                size: 54,
                color: AppColors.sage,
              ),
              const SizedBox(height: 18),
              Text(
                '$selectedPage is next',
                style: const TextStyle(
                  color: AppColors.light,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'We will build this page and connect it to your '
                'backend in the upcoming steps.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _selectPage('Dashboard'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back to Dashboard'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.light,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SIDEBAR
// ============================================================

class Sidebar extends StatelessWidget {
  final String selectedPage;
  final ValueChanged<String> onSelect;

  const Sidebar({
    super.key,
    required this.selectedPage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 12, 32),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: AppColors.light,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VERDANT',
                      style: TextStyle(
                        color: AppColors.light,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'SMART ATTENDANCE',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 8,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              'WORKSPACE',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _navItem('Dashboard', Icons.grid_view_rounded),
          _navItem('Students', Icons.groups_rounded),
          _navItem('Enrollment', Icons.person_add_alt_1_rounded),
          _navItem('Live Attendance', Icons.videocam_rounded),
          _navItem('Reports', Icons.assessment_rounded),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.sage, size: 23),
                SizedBox(height: 12),
                Text(
                  'Recognition System',
                  style: TextStyle(
                    color: AppColors.light,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Backend connection pending',
                  style: TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          _navItem('Settings', Icons.settings_rounded),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _navItem(String title, IconData icon) {
    final active = selectedPage == title;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        onTap: () => onSelect(title),
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: active ? AppColors.light : AppColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: active ? AppColors.light : AppColors.muted,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (active)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.sage,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STATISTIC MODEL
// ============================================================

class _StatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _StatData(this.title, this.value, this.subtitle, this.icon);
}

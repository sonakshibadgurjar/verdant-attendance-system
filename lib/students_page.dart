
import 'package:flutter/material.dart';
import 'student_store.dart';

const Color bg = Color(0xFF051F20);
const Color surface = Color(0xFF0B2B26);
const Color card = Color(0xFF163832);
const Color accent = Color(0xFF235347);
const Color lightGreen = Color(0xFF8EB69B);
const Color paleGreen = Color(0xFFDAF1DE);
const Color mutedText = Color(0xFFADC8B8);

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final TextEditingController searchController = TextEditingController();

  String selectedFilter = 'All Students';

  final List<String> filters = [
    'All Students',
    'Enrolled',
    'Pending',
  ];

  @override
  void initState() {
    super.initState();
    searchController.addListener(_refresh);
    StudentStore.instance.records.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    searchController.removeListener(_refresh);
    StudentStore.instance.records.removeListener(_refresh);
    searchController.dispose();
    super.dispose();
  }

  List<StudentRecord> get filteredStudents {
    final query = searchController.text.trim().toLowerCase();

    return StudentStore.instance.students.where((student) {
      final matchesFilter = selectedFilter == 'All Students' ||
          student.status == selectedFilter;

      final matchesSearch = student.id.toLowerCase().contains(query) ||
          student.name.toLowerCase().contains(query) ||
          student.department.toLowerCase().contains(query) ||
          student.email.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  int get enrolledCount => StudentStore.instance.students
      .where((student) => student.status == 'Enrolled')
      .length;

  int get pendingCount => StudentStore.instance.students
      .where((student) => student.status == 'Pending')
      .length;

  Future<void> _showStudentDialog({StudentRecord? existing}) async {
    final result = await showDialog<StudentRecord>(
      context: context,
      builder: (_) => _StudentEditorDialog(existing: existing),
    );

    if (!mounted || result == null) return;

    if (existing == null) {
      StudentStore.instance.addStudent(result);
    } else {
      StudentStore.instance.updateStudent(result);
    }
  }

  Future<void> _confirmDelete(StudentRecord student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surface,
        title: const Text(
          'Delete Student?',
          style: TextStyle(color: paleGreen),
        ),
        content: Text(
          'Remove ${student.name} (${student.id}) from the student list?',
          style: const TextStyle(color: mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: mutedText),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    StudentStore.instance.deleteStudent(student.id);
  }

  void _viewStudent(StudentRecord student) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surface,
        title: Text(
          student.name,
          style: const TextStyle(
            color: paleGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Student ID: ${student.id}\n'
          'Department: ${student.department}\n'
          'Email: ${student.email}\n'
          'Year: ${student.year}\n'
          'Status: ${student.status}\n'
          'Added: ${student.enrolledOn}',
          style: const TextStyle(
            color: mutedText,
            height: 1.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(color: lightGreen),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = filteredStudents;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;

            return SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 16 : 28),
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
                              'Students',
                              style: TextStyle(
                                color: paleGreen,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Manage student profiles and enrollment status.',
                              style: TextStyle(color: mutedText),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _showStudentDialog(),
                        icon: const Icon(Icons.person_add_alt_1),
                        label: Text(compact ? 'Add' : 'Add Student'),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: paleGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statCard(
                        'Total Students',
                        '${StudentStore.instance.students.length}',
                        Icons.groups_rounded,
                      ),
                      _statCard(
                        'Enrolled',
                        '$enrolledCount',
                        Icons.check_circle_outline_rounded,
                      ),
                      _statCard(
                        'Pending',
                        '$pendingCount',
                        Icons.hourglass_empty_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student Directory',
                          style: TextStyle(
                            color: paleGreen,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: searchController,
                          style: const TextStyle(color: paleGreen),
                          decoration: _decoration(
                            'Search by name, ID, department, or email',
                          ).copyWith(
                            prefixIcon: const Icon(
                              Icons.search,
                              color: lightGreen,
                            ),
                            suffixIcon: searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: searchController.clear,
                                    icon: const Icon(
                                      Icons.close,
                                      color: mutedText,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: filters.map((filter) {
                            final selected = selectedFilter == filter;

                            return ChoiceChip(
                              label: Text(filter),
                              selected: selected,
                              onSelected: (_) {
                                setState(() => selectedFilter = filter);
                              },
                              selectedColor: accent,
                              backgroundColor: card,
                              labelStyle: TextStyle(
                                color: selected ? paleGreen : mutedText,
                              ),
                              side: BorderSide(
                                color: selected ? lightGreen : accent,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),
                        if (students.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 36),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.person_search_rounded,
                                    size: 44,
                                    color: lightGreen,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No students found',
                                    style: TextStyle(
                                      color: paleGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Try another search or filter.',
                                    style: TextStyle(color: mutedText),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...students.map(
                            (student) => _studentTile(student),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _studentTile(StudentRecord student) {
    final enrolled = student.status == 'Enrolled';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accent,
            foregroundColor: paleGreen,
            child: Text(
              student.name.isEmpty ? '?' : student.name[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    color: paleGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${student.id} • ${student.department}',
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.email,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: enrolled
                        ? accent
                        : const Color(0xFF51421F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    student.status,
                    style: TextStyle(
                      color: enrolled
                          ? paleGreen
                          : const Color(0xFFFFE0A3),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            iconColor: lightGreen,
            color: card,
            onSelected: (value) {
              if (value == 'view') {
                _viewStudent(student);
              } else if (value == 'edit') {
                _showStudentDialog(existing: student);
              } else if (value == 'delete') {
                _confirmDelete(student);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'view',
                child: Text(
                  'View details',
                  style: TextStyle(color: paleGreen),
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Text(
                  'Edit student',
                  style: TextStyle(color: paleGreen),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete student',
                  style: TextStyle(color: paleGreen),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: lightGreen, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: paleGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: const TextStyle(color: mutedText)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentEditorDialog extends StatefulWidget {
  final StudentRecord? existing;

  const _StudentEditorDialog({this.existing});

  @override
  State<_StudentEditorDialog> createState() =>
      _StudentEditorDialogState();
}

class _StudentEditorDialogState extends State<_StudentEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController idController;
  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController departmentController;

  late String year;
  late String status;
  String? errorMessage;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final student = widget.existing;

    idController = TextEditingController(text: student?.id ?? '');
    nameController = TextEditingController(text: student?.name ?? '');
    emailController = TextEditingController(text: student?.email ?? '');
    departmentController =
        TextEditingController(text: student?.department ?? '');

    year = student?.year ?? '1st Year';
    status = student?.status ?? 'Pending';
  }

  @override
  void dispose() {
    idController.dispose();
    nameController.dispose();
    emailController.dispose();
    departmentController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final id = idController.text.trim();
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final department = departmentController.text.trim();

    if (!isEditing && StudentStore.instance.containsId(id)) {
      setState(() {
        errorMessage = 'This Student ID already exists.';
      });
      return;
    }

    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = '${now.day} ${months[now.month - 1]} ${now.year}';

    final result = StudentRecord(
      id: id,
      name: name,
      email: email,
      department: department,
      year: year,
      status: status,
      enrolledOn: widget.existing?.enrolledOn ?? date,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: surface,
      title: Text(
        isEditing ? 'Edit Student' : 'Add Student',
        style: const TextStyle(
          color: paleGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editorField(
                  idController,
                  'Student ID',
                  enabled: !isEditing,
                ),
                _editorField(nameController, 'Full Name'),
                _editorField(emailController, 'Email'),
                _editorField(departmentController, 'Department'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: year,
                  dropdownColor: card,
                  style: const TextStyle(color: paleGreen),
                  decoration: _decoration('Academic Year'),
                  items: const [
                    '1st Year',
                    '2nd Year',
                    '3rd Year',
                    '4th Year',
                  ].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => year = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  dropdownColor: card,
                  style: const TextStyle(color: paleGreen),
                  decoration: _decoration('Enrollment Status'),
                  items: const [
                    'Enrolled',
                    'Pending',
                  ].map((value) {
                    return DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => status = value);
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: mutedText),
          ),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: paleGreen,
          ),
          child: Text(isEditing ? 'Save Changes' : 'Add Student'),
        ),
      ],
    );
  }
}

Widget _editorField(
  TextEditingController controller,
  String label, {
  bool enabled = true,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(color: paleGreen),
      decoration: _decoration(label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
    ),
  );
}

InputDecoration _decoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: mutedText),
    filled: true,
    fillColor: card,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: accent),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: accent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: lightGreen, width: 1.5),
    ),
  );
}

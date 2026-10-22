
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'student_store.dart';

const Color bg = Color(0xFF051F20);
const Color surface = Color(0xFF0B2B26);
const Color card = Color(0xFF163832);
const Color accent = Color(0xFF235347);
const Color lightGreen = Color(0xFF8EB69B);
const Color paleGreen = Color(0xFFDAF1DE);
const Color mutedText = Color(0xFFADC8B8);

class StudentEnrollmentPage extends StatefulWidget {
  final VoidCallback? onBack;

  const StudentEnrollmentPage({
    super.key,
    this.onBack,
  });

  @override
  State<StudentEnrollmentPage> createState() =>
      _StudentEnrollmentPageState();
}

class _StudentEnrollmentPageState
    extends State<StudentEnrollmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdController = TextEditingController();
  final _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<Uint8List?> _photos = List<Uint8List?>.filled(6, null);
  bool _isSubmitting = false;

  int get _photoCount => _photos.where((photo) => photo != null).length;

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(int index) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();

      if (!mounted) return;
      setState(() => _photos[index] = bytes);
    } catch (_) {
      _showMessage('Could not open that image. Please try another photo.');
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos[index] = null);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: card,
        ),
      );
  }

  Future<void> _submitEnrollment() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _showMessage('Please complete the required student details.');
      return;
    }

    if (_photoCount != 6) {
      _showMessage('Please select all six student photos.');
      return;
    }

    final id = _studentIdController.text.trim();
    final name = _nameController.text.trim();
    final store = StudentStore.instance;

    if (store.containsId(id)) {
      _showMessage('This Student ID already exists.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Demo validation delay only. No backend request is made.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      if (store.containsId(id)) {
        _showMessage('This Student ID already exists.');
        return;
      }

      final now = DateTime.now();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final date = '${now.day} ${months[now.month - 1]} ${now.year}';

      store.addStudent(
        StudentRecord(
          id: id,
          name: name,
          department: 'Not specified',
          email: 'Not provided',
          year: '1st Year',
          status: 'Pending',
          enrolledOn: date,
        ),
      );

      // The photo bytes are only kept in this page's memory.
      setState(() {
        _studentIdController.clear();
        _nameController.clear();
        for (var i = 0; i < _photos.length; i++) {
          _photos[i] = null;
        }
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: surface,
          icon: const Icon(
            Icons.check_circle_rounded,
            color: lightGreen,
            size: 50,
          ),
          title: const Text(
            'Student Added',
            style: TextStyle(
              color: paleGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '$name ($id) has been added to the Students list.\n\n'
            'Status: Pending\n\n'
            'This demo has not uploaded the photos or connected to '
            'the face-recognition backend.',
            style: const TextStyle(
              color: mutedText,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Continue',
                style: TextStyle(color: lightGreen),
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      _showMessage('Could not add the student. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      if (widget.onBack != null) ...[
                        IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: lightGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Enrollment',
                              style: TextStyle(
                                color: paleGreen,
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Register a student and prepare their face-photo set.',
                              style: TextStyle(color: mutedText),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: accent),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Student Details',
                            style: TextStyle(
                              color: paleGreen,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _buildField(
                            controller: _studentIdController,
                            label: 'Student ID',
                            hint: 'e.g. STU007',
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Enter student full name',
                          ),
                          const SizedBox(height: 26),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Face Photo Set',
                                  style: TextStyle(
                                    color: paleGreen,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '$_photoCount / 6',
                                style: const TextStyle(
                                  color: lightGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Choose six clear photos of the same student. '
                            'Use good lighting and varied natural angles.',
                            style: TextStyle(
                              color: mutedText,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 6,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: compact ? 2 : 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: compact ? 0.92 : 1.12,
                            ),
                            itemBuilder: (context, index) {
                              return _buildPhotoSlot(index);
                            },
                          ),
                          const SizedBox(height: 24),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _photoCount / 6,
                              minHeight: 7,
                              backgroundColor: card,
                              valueColor:
                                  const AlwaysStoppedAnimation(lightGreen),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _photoCount == 6
                                ? 'All six photos are ready.'
                                : 'Select ${6 - _photoCount} more photo(s) to continue.',
                            style: const TextStyle(color: mutedText),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  _isSubmitting ? null : _submitEnrollment,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: paleGreen,
                                      ),
                                    )
                                  : const Icon(Icons.person_add_alt_1),
                              label: Text(
                                _isSubmitting
                                    ? 'Adding Student...'
                                    : 'Complete Enrollment',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: paleGreen,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 17,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: paleGreen),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: mutedText),
        hintStyle: const TextStyle(color: mutedText),
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
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        if (label == 'Student ID' &&
            !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value.trim())) {
          return 'Use letters, numbers, _ or - only';
        }
        return null;
      },
    );
  }

  Widget _buildPhotoSlot(int index) {
    final photo = _photos[index];

    return InkWell(
      onTap: () => _pickPhoto(index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: photo == null ? accent : lightGreen,
            width: photo == null ? 1 : 1.5,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (photo != null)
              Image.memory(photo, fit: BoxFit.cover)
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    color: lightGreen,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Photo ${index + 1}',
                    style: const TextStyle(
                      color: paleGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to select',
                    style: TextStyle(color: mutedText, fontSize: 12),
                  ),
                ],
              ),
            if (photo != null)
              Positioned(
                top: 6,
                right: 6,
                child: IconButton.filled(
                  tooltip: 'Remove photo',
                  style: IconButton.styleFrom(
                    backgroundColor: bg.withValues(alpha: 0.85),
                    foregroundColor: paleGreen,
                  ),
                  onPressed: () => _removePhoto(index),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
            if (photo != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: bg.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Photo ${index + 1}',
                    style: const TextStyle(
                      color: paleGreen,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

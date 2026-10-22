import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // App color palette
  static const Color background = Color(0xFF051F20);
  static const Color surface = Color(0xFF0B2B26);
  static const Color cardColor = Color(0xFF163832);
  static const Color accent = Color(0xFF235347);
  static const Color lightGreen = Color(0xFF8EB69B);
  static const Color paleGreen = Color(0xFFDAF1DE);
  static const Color mutedText = Color(0xFFAAC3B4);

  // Default settings
  static const bool defaultNotificationsEnabled = true;
  static const bool defaultAutoAttendanceEnabled = true;
  static const bool defaultSoundEnabled = false;
  static const bool defaultRequireConfirmation = true;
  static const String defaultCamera = 'Default Camera';
  static const String defaultSession = '60 minutes';
  static const double defaultThreshold = 0.75;

  // Current settings
  bool notificationsEnabled = defaultNotificationsEnabled;
  bool autoAttendanceEnabled = defaultAutoAttendanceEnabled;
  bool soundEnabled = defaultSoundEnabled;
  bool requireConfirmation = defaultRequireConfirmation;

  String selectedCamera = defaultCamera;
  String selectedSession = defaultSession;

  double recognitionThreshold = defaultThreshold;

  bool isLoading = true;
  bool isSaving = false;

  // Ensures saves run in order, so a previous save cannot overwrite
  // a newer setting value.
  Future<void> _saveQueue = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load previously saved settings when the page opens.
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        notificationsEnabled =
            prefs.getBool('notificationsEnabled') ??
                defaultNotificationsEnabled;

        autoAttendanceEnabled =
            prefs.getBool('autoAttendanceEnabled') ??
                defaultAutoAttendanceEnabled;

        soundEnabled =
            prefs.getBool('soundEnabled') ?? defaultSoundEnabled;

        requireConfirmation =
            prefs.getBool('requireConfirmation') ??
                defaultRequireConfirmation;

        selectedCamera =
            prefs.getString('selectedCamera') ?? defaultCamera;

        selectedSession =
            prefs.getString('selectedSession') ?? defaultSession;

        recognitionThreshold =
            prefs.getDouble('recognitionThreshold') ??
                defaultThreshold;

        // Protect against values outside the supported range.
        recognitionThreshold =
            recognitionThreshold.clamp(0.50, 0.95).toDouble();

        // Protect against outdated or invalid dropdown values.
        if (!['Default Camera', 'Camera 1', 'Camera 2']
            .contains(selectedCamera)) {
          selectedCamera = defaultCamera;
        }

        if (!['30 minutes', '60 minutes', '90 minutes', '120 minutes']
            .contains(selectedSession)) {
          selectedSession = defaultSession;
        }

        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage('Could not load settings. Please try again.');
    }
  }

  // Save a snapshot of all settings.
  Future<void> _saveSettings() {
    final notifications = notificationsEnabled;
    final autoAttendance = autoAttendanceEnabled;
    final sound = soundEnabled;
    final confirmation = requireConfirmation;
    final camera = selectedCamera;
    final session = selectedSession;
    final threshold = recognitionThreshold;

    _saveQueue = _saveQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.setBool('notificationsEnabled', notifications),
        prefs.setBool('autoAttendanceEnabled', autoAttendance),
        prefs.setBool('soundEnabled', sound),
        prefs.setBool('requireConfirmation', confirmation),
        prefs.setString('selectedCamera', camera),
        prefs.setString('selectedSession', session),
        prefs.setDouble('recognitionThreshold', threshold),
      ]);
    });

    return _saveQueue;
  }

  // Update the UI and automatically save the change.
  Future<void> _updateAndSave(VoidCallback update) async {
    if (!mounted || isLoading) return;

    setState(update);

    try {
      await _saveSettings();
    } catch (error) {
      if (mounted) {
        _showMessage('Could not save settings. Please try again.');
      }
    }
  }

  // Save settings when the user presses Apply Settings.
  Future<void> _applySettings() async {
    if (isLoading || isSaving) return;

    setState(() {
      isSaving = true;
    });

    try {
      await _saveSettings();

      if (!mounted) return;
      _showMessage('Settings saved successfully.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not save settings. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  // Restore and save default settings.
  Future<void> _resetSettings() async {
    if (isLoading || isSaving) return;

    setState(() {
      isSaving = true;

      notificationsEnabled = defaultNotificationsEnabled;
      autoAttendanceEnabled = defaultAutoAttendanceEnabled;
      soundEnabled = defaultSoundEnabled;
      requireConfirmation = defaultRequireConfirmation;
      selectedCamera = defaultCamera;
      selectedSession = defaultSession;
      recognitionThreshold = defaultThreshold;
    });

    try {
      await _saveSettings();

      if (!mounted) return;
      _showMessage('Settings restored to defaults.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not reset settings. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: lightGreen),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;

                return SingleChildScrollView(
                  padding: EdgeInsets.all(
                    constraints.maxWidth < 600 ? 16 : 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),

                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildGeneralSettings(),
                                  const SizedBox(height: 20),
                                  _buildCameraSettings(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildAttendanceSettings(),
                                  const SizedBox(height: 20),
                                  _buildSessionSettings(),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _buildGeneralSettings(),
                        const SizedBox(height: 20),
                        _buildCameraSettings(),
                        const SizedBox(height: 20),
                        _buildAttendanceSettings(),
                        const SizedBox(height: 20),
                        _buildSessionSettings(),
                      ],

                      const SizedBox(height: 28),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            color: paleGreen,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Customize your attendance system preferences.',
          style: TextStyle(
            color: mutedText,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accent.withValues(alpha: 0.7),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.cloud_done_rounded,
                color: lightGreen,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your preferences are saved automatically on this device.',
                  style: TextStyle(
                    color: paleGreen,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralSettings() {
    return _buildSection(
      title: 'General Preferences',
      subtitle: 'Manage notifications and confirmations.',
      icon: Icons.tune_rounded,
      children: [
        _buildSwitchTile(
          title: 'Notifications',
          subtitle: 'Enable attendance notifications.',
          value: notificationsEnabled,
          onChanged: (value) {
            _updateAndSave(
              () => notificationsEnabled = value,
            );
          },
        ),
        _buildSwitchTile(
          title: 'Sound Alerts',
          subtitle: 'Play a sound for attendance events.',
          value: soundEnabled,
          onChanged: (value) {
            _updateAndSave(
              () => soundEnabled = value,
            );
          },
        ),
        _buildSwitchTile(
          title: 'Require Confirmation',
          subtitle: 'Confirm actions before proceeding.',
          value: requireConfirmation,
          onChanged: (value) {
            _updateAndSave(
              () => requireConfirmation = value,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCameraSettings() {
    return _buildSection(
      title: 'Camera Settings',
      subtitle: 'Choose the camera for attendance capture.',
      icon: Icons.camera_alt_rounded,
      children: [
        _buildDropdownTile(
          title: 'Camera Source',
          subtitle: 'Preferred camera device.',
          value: selectedCamera,
          options: const [
            'Default Camera',
            'Camera 1',
            'Camera 2',
          ],
          onChanged: (value) {
            _updateAndSave(
              () => selectedCamera = value,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAttendanceSettings() {
    return _buildSection(
      title: 'Attendance Automation',
      subtitle: 'Configure automatic attendance behavior.',
      icon: Icons.fact_check_rounded,
      children: [
        _buildSwitchTile(
          title: 'Automatic Attendance',
          subtitle: 'Enable automatic attendance marking.',
          value: autoAttendanceEnabled,
          onChanged: (value) {
            _updateAndSave(
              () => autoAttendanceEnabled = value,
            );
          },
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recognition Threshold',
                      style: TextStyle(
                        color: paleGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(recognitionThreshold * 100).round()}%',
                      style: const TextStyle(
                        color: paleGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Minimum confidence required for a face match.',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12,
                ),
              ),
              Slider(
                value: recognitionThreshold,
                min: 0.50,
                max: 0.95,
                divisions: 9,
                activeColor: lightGreen,
                inactiveColor: accent,
                label: '${(recognitionThreshold * 100).round()}%',
                onChanged: (value) {
                  _updateAndSave(
                    () => recognitionThreshold = value,
                  );
                },
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '50% · More matches',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '95% · Stricter',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 10,
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

  Widget _buildSessionSettings() {
    return _buildSection(
      title: 'Session Preferences',
      subtitle: 'Set the duration of an attendance session.',
      icon: Icons.schedule_rounded,
      children: [
        _buildDropdownTile(
          title: 'Session Duration',
          subtitle: 'Default attendance session length.',
          value: selectedSession,
          options: const [
            '30 minutes',
            '60 minutes',
            '90 minutes',
            '120 minutes',
          ],
          onChanged: (value) {
            _updateAndSave(
              () => selectedSession = value,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: paleGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: paleGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: mutedText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: paleGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            activeThumbColor: paleGreen,
            activeTrackColor: accent,
            inactiveThumbColor: mutedText,
            inactiveTrackColor: cardColor,
            onChanged: isSaving ? null : onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: paleGreen,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: mutedText,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: cardColor,
          style: const TextStyle(
            color: paleGreen,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: accent.withValues(alpha: 0.8),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: lightGreen,
                width: 1.5,
              ),
            ),
          ),
          iconEnabledColor: lightGreen,
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: isSaving
              ? null
              : (newValue) {
                  if (newValue != null) {
                    onChanged(newValue);
                  }
                },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ElevatedButton.icon(
          onPressed: isSaving ? null : _applySettings,
          icon: isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: background,
                  ),
                )
              : const Icon(Icons.check_circle_outline_rounded),
          label: Text(isSaving ? 'Saving...' : 'Apply Settings'),
          style: ElevatedButton.styleFrom(
            backgroundColor: lightGreen,
            foregroundColor: background,
            disabledBackgroundColor: accent,
            disabledForegroundColor: mutedText,
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: isSaving ? null : _resetSettings,
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Reset to Defaults'),
          style: OutlinedButton.styleFrom(
            foregroundColor: paleGreen,
            side: const BorderSide(color: accent),
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
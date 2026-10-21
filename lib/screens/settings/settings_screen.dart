import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/reminder.dart';
import '../../core/providers/providers.dart';
import '../../core/services/encryption_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/security_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/utils/app_router.dart';
import '../../core/utils/validators.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _opening = false;

  Future<void> _open(Future<void> Function() action) async {
    if (_opening) return;
    _opening = true;
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load settings. Please try again.')),
        );
      }
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(themeMode),
            onTap: () => _open(_showThemePicker),
          ),
          const _SectionHeader(title: 'Profiles'),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('Family Profiles'),
            subtitle: const Text('Manage multiple family members'),
            onTap: () => context.push(AppRoutes.profiles),
          ),
          const _SectionHeader(title: 'Reminders'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Reminder Settings'),
            onTap: () => _open(_showReminderSettings),
          ),
          const _SectionHeader(title: 'Units'),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Weight Unit'),
            subtitle: FutureBuilder(
              future: ref.read(settingsServiceProvider.future),
              builder: (context, snapshot) => Text(snapshot.data?.weightUnit ?? 'kg'),
            ),
            onTap: () => _open(_showWeightUnitPicker),
          ),
          const _SectionHeader(title: 'Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('PIN Lock'),
            onTap: () => _open(_showPinSettings),
          ),
          const _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: const Text('Attachments'),
            subtitle: const Text('Prescriptions, lab reports, PDFs'),
            onTap: () => context.push(AppRoutes.attachments),
          ),
          const _SectionHeader(title: 'Export'),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Reports & Export'),
            onTap: () => context.push(AppRoutes.reports),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Patient Name'),
            onTap: () => _open(() => _editReportSetting(notes: false)),
          ),
          ListTile(
            leading: const Icon(Icons.note_outlined),
            title: const Text('Doctor Notes'),
            onTap: () => _open(() => _editReportSetting(notes: true)),
          ),
          const _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About VitalTrack'),
            onTap: () => context.push(AppRoutes.about),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _showThemePicker() async {
    final mode = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in {'system': 'System', 'light': 'Light', 'dark': 'Dark'}.entries)
              ListTile(
                title: Text(entry.value),
                onTap: () => Navigator.pop(ctx, entry.key),
              ),
          ],
        ),
      ),
    );
    if (mode != null && mounted) {
      await ref.read(themeModeProvider.notifier).setMode(mode);
    }
  }

  Future<void> _showWeightUnitPicker() async {
    final settings = await ref.read(settingsServiceProvider.future);
    if (!mounted) return;
    final unit = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('kg (Kilograms)'), onTap: () => Navigator.pop(ctx, 'kg')),
            ListTile(title: const Text('lbs (Pounds)'), onTap: () => Navigator.pop(ctx, 'lbs')),
          ],
        ),
      ),
    );
    if (unit == null) return;
    await settings.setWeightUnit(unit);
    if (mounted) setState(() {});
  }

  Future<void> _showReminderSettings() async {
    final repo = ref.read(reminderRepositoryProvider);
    final notifications = ref.read(notificationServiceProvider);
    final settings = await ref.read(settingsServiceProvider.future);
    final stored = await repo.getAll();
    final persistedIds = stored.map((r) => r.id).toSet();
    // Defaults are drafts. Merely opening this sheet never writes or schedules.
    final reminders = stored.isEmpty
        ? [
            const Reminder(id: 'default-morning-reminder', title: 'Morning Reminder', time: '08:00', enabled: false),
            const Reminder(id: 'default-evening-reminder', title: 'Evening Reminder', time: '20:00', enabled: false),
          ]
        : stored.map((r) => settings.remindersOptedIn ? r : r.copyWith(enabled: false)).toList();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ReminderSettingsSheet(
        reminders: reminders,
        supported: notifications.isSupported,
        onUpdate: (reminder) async {
          final index = reminders.indexWhere((r) => r.id == reminder.id);
          final previous = reminders[index];
          if (reminder.enabled && !previous.enabled) {
            if (!await notifications.requestPermissions()) {
              throw const ReminderException(
                'Notifications are denied. Allow notifications in device settings, then switch the reminder on again.',
              );
            }
          }
          if (reminder.enabled) {
            if (!settings.remindersOptedIn) {
              // Clear pre-opt-in schedules/unstable legacy IDs only on this
              // explicit action, and keep other legacy defaults disabled.
              await notifications.cancelAll();
              for (final legacy in stored) {
                await repo.update(legacy.copyWith(enabled: false));
              }
            }
            await notifications.scheduleReminder(reminder);
          } else {
            await notifications.cancelReminder(reminder.id);
          }
          try {
            if (persistedIds.contains(reminder.id)) {
              await repo.update(reminder);
            } else {
              await repo.insert(reminder);
              persistedIds.add(reminder.id);
            }
            if (reminder.enabled) await settings.setRemindersOptedIn(true);
            reminders[index] = reminder;
          } catch (_) {
            // Do not leave a newly enabled OS reminder behind after a failed save.
            await notifications.cancelReminder(reminder.id);
            if (persistedIds.contains(previous.id)) await repo.update(previous);
            if (previous.enabled) await notifications.scheduleReminder(previous);
            rethrow;
          }
        },
      ),
    );
  }

  Future<void> _showPinSettings() async {
    final security = ref.read(securityServiceProvider);
    final settings = await ref.read(settingsServiceProvider.future);
    final hasPin = await security.hasPin();
    if (!mounted) return;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PinDialog(security: security, settings: settings, hasPin: hasPin),
    );
  }

  Future<void> _editReportSetting({required bool notes}) async {
    final settings = await ref.read(settingsServiceProvider.future);
    if (!mounted) return;
    var value = notes ? settings.doctorNotes : settings.patientName;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(notes ? 'Doctor Notes' : 'Patient Name'),
        content: TextFormField(
          initialValue: value,
          onChanged: (text) => value = text,
          maxLines: notes ? 4 : 1,
          decoration: InputDecoration(hintText: notes ? 'Notes to include in reports' : 'Name for reports'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      if (notes) {
        await settings.setDoctorNotes(value);
      } else {
        await settings.setPatientName(value);
      }
    }
  }
}

class _PinDialog extends StatefulWidget {
  const _PinDialog({required this.security, required this.settings, required this.hasPin});
  final SecurityService security;
  final SettingsService settings;
  final bool hasPin;

  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _current = TextEditingController();
  final _newPin = TextEditingController();
  final _confirmation = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPin.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save({bool disable = false}) async {
    if (_saving) return;
    if (disable) {
      final error = ReadingValidator.validatePin(_current.text);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
    } else if (!_form.currentState!.validate()) {
      return;
    }
    final current = _current.text;
    final newPin = _newPin.text;
    final confirmation = _confirmation.text;
    setState(() { _saving = true; _error = null; });
    try {
      if (disable) {
        await widget.security.requireCurrentPin(current);
        final wasEnabled = widget.settings.pinEnabled;
        // Persist the disabled flag first, so a preferences failure never leaves
        // an enabled lock without a credential. Restore it if deletion fails.
        await widget.settings.setPinEnabled(false);
        try {
          await widget.security.removePin(currentPin: current);
        } catch (_) {
          await widget.settings.setPinEnabled(wasEnabled);
          rethrow;
        }
      } else {
        await widget.security.setPin(newPin, confirmation: confirmation, currentPin: widget.hasPin ? current : null);
        await widget.settings.setPinEnabled(true);
        isAppUnlocked = true;
      }
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is PinException ? error.message : 'Could not update security settings. Please try again.';
        });
      }
    }
  }

  Widget _field(TextEditingController controller, String label, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 4,
      obscureText: true,
      enableSuggestions: false,
      autocorrect: false,
      decoration: InputDecoration(labelText: label),
      validator: validator ?? ReadingValidator.validatePin,
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(widget.hasPin ? 'Change PIN' : 'Set PIN'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.hasPin) _field(_current, 'Current PIN'),
              _field(_newPin, 'New PIN'),
              _field(_confirmation, 'Confirm new PIN', validator: (value) {
                final error = ReadingValidator.validatePin(value);
                return error ?? (value == _newPin.text ? null : 'PINs do not match');
              }),
              if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_saving) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.hasPin)
          TextButton(onPressed: _saving ? null : () => _save(disable: true), child: const Text('Disable PIN')),
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _saving ? null : _save, child: const Text('Save')),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
    child: Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600,
    )),
  );
}

class _ReminderSettingsSheet extends StatefulWidget {
  const _ReminderSettingsSheet({required this.reminders, required this.supported, required this.onUpdate});
  final List<Reminder> reminders;
  final bool supported;
  final Future<void> Function(Reminder) onUpdate;

  @override
  State<_ReminderSettingsSheet> createState() => _ReminderSettingsSheetState();
}

class _ReminderSettingsSheetState extends State<_ReminderSettingsSheet> {
  late final List<Reminder> _reminders = List.of(widget.reminders);
  bool _saving = false;
  String? _error;

  Future<void> _pickTime(int index) async {
    final parts = _reminders[index].time.split(':');
    final hour = int.tryParse(parts.first) ?? 8;
    final minute = parts.length == 2 ? int.tryParse(parts.last) ?? 0 : 0;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59)),
    );
    if (picked == null || !mounted) return;
    await _update(index, _reminders[index].copyWith(
      time: '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
    ));
  }

  Future<void> _update(int index, Reminder updated) async {
    if (_saving) return;
    setState(() { _saving = true; _error = null; });
    try {
      await widget.onUpdate(updated);
      if (mounted) setState(() => _reminders[index] = updated);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is ReminderException ? error.message : 'Could not save the reminder. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reminder Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(widget.supported
              ? 'Switch on a reminder to allow notifications. Reminders arrive around the selected local time.'
              : 'Local reminders are not supported on this platform.'),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          if (_saving) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          for (var i = 0; i < _reminders.length; i++)
            SwitchListTile(
              title: Text(_reminders[i].title),
              subtitle: Text(_reminders[i].time),
              value: _reminders[i].enabled,
              onChanged: _saving || !widget.supported ? null : (value) => _update(i, _reminders[i].copyWith(enabled: value)),
              secondary: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: _saving || !widget.supported ? null : () => _pickTime(i),
              ),
            ),
        ],
      ),
    ),
  );
}

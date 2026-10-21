import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/reading.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/validators.dart';
import '../../widgets/primary_button.dart';

class AddReadingScreen extends ConsumerStatefulWidget {
  const AddReadingScreen({super.key, this.readingId});

  final String? readingId;

  @override
  ConsumerState<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends ConsumerState<AddReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _medicationTaken = false;
  String? _selectedMood;
  final Set<String> _selectedSymptoms = {};
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.readingId != null) {
      _isEditing = true;
      _loadReading();
    }
  }

  Future<void> _loadReading() async {
    final repo = ref.read(readingRepositoryProvider);
    final reading = await repo.getById(widget.readingId!);
    if (reading == null || !mounted) return;

    _systolicController.text = reading.systolic.toString();
    _diastolicController.text = reading.diastolic.toString();
    _pulseController.text = reading.pulse.toString();
    if (reading.weight != null) _weightController.text = reading.weight.toString();
    _notesController.text = reading.notes ?? '';
    _medicationTaken = reading.medicationTaken;
    _selectedMood = reading.mood;
    _selectedSymptoms.addAll(reading.symptoms);
    _selectedDate = reading.timestamp;
    _selectedTime = TimeOfDay.fromDateTime(reading.timestamp);
    setState(() {});
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _timestamp => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final systolic = int.parse(_systolicController.text.trim());
    final diastolic = int.parse(_diastolicController.text.trim());
    final bpError = ReadingValidator.validateBpRelationship(systolic, diastolic);
    if (bpError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(bpError)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = ref.read(activeProfileProvider).valueOrNull;
      if (profile == null) throw Exception('No active profile');

      final reading = Reading(
        id: _isEditing ? widget.readingId! : const Uuid().v4(),
        systolic: systolic,
        diastolic: diastolic,
        pulse: int.parse(_pulseController.text.trim()),
        weight: _weightController.text.isNotEmpty
            ? double.parse(_weightController.text.trim())
            : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        medicationTaken: _medicationTaken,
        symptoms: _selectedSymptoms.toList(),
        mood: _selectedMood,
        timestamp: _timestamp,
        profileId: profile.id,
      );

      final actions = ref.read(readingActionsProvider);
      if (_isEditing) {
        await actions.updateReading(reading);
      } else {
        await actions.addReading(reading);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Reading updated' : 'Reading saved')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Reading' : 'Add Reading'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Blood Pressure',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _systolicController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Systolic',
                      suffixText: 'mmHg',
                    ),
                    validator: ReadingValidator.validateSystolic,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _diastolicController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Diastolic',
                      suffixText: 'mmHg',
                    ),
                    validator: ReadingValidator.validateDiastolic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pulseController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pulse',
                suffixText: 'BPM',
              ),
              validator: ReadingValidator.validatePulse,
            ),
            const SizedBox(height: 24),
            Text(
              'Date & Time',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (optional)',
                suffixText: 'kg',
              ),
              validator: ReadingValidator.validateWeight,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Medication Taken'),
              value: _medicationTaken,
              onChanged: (v) => setState(() => _medicationTaken = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            Text(
              'Mood',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: AppConstants.moods.map((mood) {
                final selected = _selectedMood == mood;
                return FilterChip(
                  label: Text(mood),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMood = selected ? null : mood),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Symptoms',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: AppConstants.symptoms.map((symptom) {
                final selected = _selectedSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _selectedSymptoms.remove(symptom);
                      } else {
                        _selectedSymptoms.add(symptom);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: _isEditing ? 'Update Reading' : 'Save Reading',
              icon: Icons.check,
              isLoading: _isLoading,
              onPressed: _save,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/providers/providers.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/web_helper.dart';
import '../../widgets/primary_button.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isGenerating = false;

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  Future<void> _generatePdf() async {
    setState(() => _isGenerating = true);
    try {
      final profile = ref.read(activeProfileProvider).valueOrNull;
      final settings = await ref.read(settingsServiceProvider.future);
      final repo = ref.read(readingRepositoryProvider);
      final reportService = ref.read(reportServiceProvider);

      final readings = await repo.getByDateRange(
        profileId: profile!.id,
        start: _startDate,
        end: _endDate.add(const Duration(days: 1)),
      );

      if (readings.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No readings in selected date range')),
          );
        }
        return;
      }

      if (kIsWeb) {
        final bytes = await reportService.generatePdfBytes(
          readings: readings,
          patientName: settings.patientName.isNotEmpty
              ? settings.patientName
              : profile.name,
          startDate: _startDate,
          endDate: _endDate,
          doctorNotes: settings.doctorNotes,
        );
        await Printing.layoutPdf(
          onLayout: (format) async => bytes,
          name: 'vitaltrack_report.pdf',
        );
        return;
      }

      final file = await reportService.generatePdf(
        readings: readings,
        patientName: settings.patientName.isNotEmpty
            ? settings.patientName
            : profile.name,
        startDate: _startDate,
        endDate: _endDate,
        doctorNotes: settings.doctorNotes,
      );
      await reportService.shareFile(file, subject: 'VitalTrack BP Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateCsv() async {
    setState(() => _isGenerating = true);
    try {
      final profile = ref.read(activeProfileProvider).valueOrNull;
      final settings = await ref.read(settingsServiceProvider.future);
      final repo = ref.read(readingRepositoryProvider);
      final reportService = ref.read(reportServiceProvider);

      final readings = await repo.getByDateRange(
        profileId: profile!.id,
        start: _startDate,
        end: _endDate.add(const Duration(days: 1)),
      );

      if (readings.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No readings in selected date range')),
          );
        }
        return;
      }

      if (kIsWeb) {
        final csvString = await reportService.generateCsvString(
          readings: readings,
          patientName: settings.patientName.isNotEmpty
              ? settings.patientName
              : profile.name,
        );
        downloadCsvWeb(csvString, 'vitaltrack_report.csv');
        return;
      }

      final file = await reportService.generateCsv(
        readings: readings,
        patientName: settings.patientName.isNotEmpty
            ? settings.patientName
            : profile.name,
      );
      await reportService.shareFile(file, subject: 'VitalTrack CSV Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Range',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(
                '${AppDateUtils.formatDate(_startDate)} - ${AppDateUtils.formatDate(_endDate)}',
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Export Format',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Generate PDF Report',
              icon: Icons.picture_as_pdf,
              isLoading: _isGenerating,
              onPressed: _generatePdf,
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Export CSV',
              icon: Icons.table_chart,
              isLoading: _isGenerating,
              onPressed: _generateCsv,
            ),
            const SizedBox(height: 32),
            Text(
              'Reports include patient name, date range, statistics, and readings. '
              'Share via the system share sheet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

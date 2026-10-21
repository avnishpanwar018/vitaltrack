import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/reading.dart';
import '../services/statistics_service.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

/// PDF and CSV report generation with system share.
class ReportService {
  ReportService(this._statisticsService);

  final StatisticsService _statisticsService;

  Future<String> generateCsvString({
    required List<Reading> readings,
    required String patientName,
  }) async {
    final rows = <List<dynamic>>[
      [
        'Date',
        'Time',
        'Systolic',
        'Diastolic',
        'Pulse',
        'Weight',
        'Medication',
        'Symptoms',
        'Mood',
        'Notes',
      ],
    ];

    for (final r in readings) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(r.timestamp),
        DateFormat('HH:mm').format(r.timestamp),
        r.systolic,
        r.diastolic,
        r.pulse,
        r.weight ?? '',
        r.medicationTaken ? 'Yes' : 'No',
        r.symptoms.join(', '),
        r.mood ?? '',
        r.notes ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<File> generateCsv({
    required List<Reading> readings,
    required String patientName,
  }) async {
    final csv = await generateCsvString(readings: readings, patientName: patientName);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vitaltrack_report.csv');
    await file.writeAsString(csv);
    return file;
  }

  Future<Uint8List> generatePdfBytes({
    required List<Reading> readings,
    required String patientName,
    required DateTime startDate,
    required DateTime endDate,
    String doctorNotes = '',
  }) async {
    final stats = _statisticsService.compute(readings);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              AppConstants.appName,
              style: const pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Blood Pressure Report'),
          pw.SizedBox(height: 16),
          pw.Text('Patient: ${patientName.isEmpty ? 'N/A' : patientName}'),
          pw.Text(
            'Period: ${AppDateUtils.formatDate(startDate)} - ${AppDateUtils.formatDate(endDate)}',
          ),
          pw.Text('Generated: ${AppDateUtils.formatDateTime(DateTime.now())}'),
          pw.SizedBox(height: 24),
          pw.Text('Statistics', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (stats.avgSystolic != null)
            pw.Text('Average Systolic: ${stats.avgSystolic!.toStringAsFixed(1)} mmHg'),
          if (stats.avgDiastolic != null)
            pw.Text('Average Diastolic: ${stats.avgDiastolic!.toStringAsFixed(1)} mmHg'),
          if (stats.avgPulse != null)
            pw.Text('Average Pulse: ${stats.avgPulse!.toStringAsFixed(1)} BPM'),
          pw.Text('Total Readings: ${stats.count}'),
          if (stats.highestReading != null)
            pw.Text('Highest: ${stats.highestReading!.bpDisplay} mmHg'),
          if (stats.lowestReading != null)
            pw.Text('Lowest: ${stats.lowestReading!.bpDisplay} mmHg'),
          if (doctorNotes.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text('Doctor Notes', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(doctorNotes),
          ],
          if (readings.length > 1) ...[
            pw.SizedBox(height: 24),
            pw.Text('Blood Pressure Trend (Last 15 readings)', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Container(
              height: 120,
              child: pw.Chart(
                grid: pw.CartesianGrid(
                  xAxis: pw.FixedAxis(
                    List.generate(readings.take(15).length, (i) => i.toDouble()),
                    format: (v) => '',
                  ),
                  yAxis: pw.FixedAxis(
                    [60.0, 80.0, 100.0, 120.0, 140.0, 160.0, 180.0, 200.0],
                    format: (v) => '${v.toInt()}',
                  ),
                ),
                datasets: [
                  pw.LineDataSet(
                    legend: 'Systolic',
                    color: PdfColors.red,
                    data: List.generate(
                      readings.take(15).length,
                      (i) {
                        final list = readings.take(15).toList().reversed.toList();
                        return pw.PointChartValue(i.toDouble(), list[i].systolic.toDouble());
                      },
                    ),
                  ),
                  pw.LineDataSet(
                    legend: 'Diastolic',
                    color: PdfColors.blue,
                    data: List.generate(
                      readings.take(15).length,
                      (i) {
                        final list = readings.take(15).toList().reversed.toList();
                        return pw.PointChartValue(i.toDouble(), list[i].diastolic.toDouble());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ] else if (readings.length == 1) ...[
            pw.SizedBox(height: 24),
            pw.Text('Blood Pressure Trend', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Trend chart is available when 2 or more readings are logged.'),
          ],
          pw.SizedBox(height: 24),
          pw.Text('Readings', style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'BP', 'Pulse', 'Notes'],
            data: readings.take(50).map((r) => [
                  AppDateUtils.formatDateTime(r.timestamp),
                  r.bpDisplay,
                  '${r.pulse}',
                  r.notes ?? '',
                ]).toList(),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            AppConstants.medicalDisclaimer,
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            AppConstants.measurementDisclaimer,
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<File> generatePdf({
    required List<Reading> readings,
    required String patientName,
    required DateTime startDate,
    required DateTime endDate,
    String doctorNotes = '',
  }) async {
    final bytes = await generatePdfBytes(
      readings: readings,
      patientName: patientName,
      startDate: startDate,
      endDate: endDate,
      doctorNotes: doctorNotes,
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/vitaltrack_report.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> shareFile(File file, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject ?? '${AppConstants.appName} Report',
    );
  }
}

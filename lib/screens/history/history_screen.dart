import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/bp_classification.dart';
import '../../core/models/reading.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/app_router.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/bp_status_badge.dart';
import '../../widgets/empty_state.dart';

enum HistorySort { newest, oldest }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  HistorySort _sort = HistorySort.newest;
  String _searchQuery = '';
  static const _pageSize = 20;
  int _loadedCount = 0;
  List<Reading> _displayReadings = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _loadGeneration = 0;
  Object? _loadError;

  DateTimeRange? _dateRange;
  int? _minSystolic;
  int? _maxSystolic;
  int? _minDiastolic;
  int? _maxDiastolic;
  int? _minPulse;
  int? _maxPulse;
  bool? _medicationTakenFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isLoadingMore) _loadReadings(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  bool _hasActiveFilters() {
    return _dateRange != null ||
        _minSystolic != null ||
        _maxSystolic != null ||
        _minDiastolic != null ||
        _maxDiastolic != null ||
        _minPulse != null ||
        _maxPulse != null ||
        _medicationTakenFilter != null;
  }

  Future<void> _loadReadings({bool refresh = false}) async {
    if (!mounted || (!refresh && (_isLoadingMore || !_hasMore))) return;
    final generation = ++_loadGeneration;
    final profile = ref.read(activeProfileProvider).valueOrNull;
    if (profile == null) {
      setState(() {
        _displayReadings = [];
        _loadedCount = 0;
        _hasMore = false;
        _isLoadingMore = false;
        _loadError = null;
      });
      return;
    }

    if (refresh) {
      _loadedCount = 0;
      _displayReadings = [];
      _hasMore = true;
    }

    final sort = _sort;
    final medicationTakenFilter = _medicationTakenFilter;
    setState(() {
      _isLoadingMore = true;
      _loadError = null;
    });

    try {
      List<Reading> readings;
      bool hasMore;
      if (_searchQuery.isNotEmpty || _hasActiveFilters()) {
        readings = await ref.read(readingRepositoryProvider).search(
              profileId: profile.id,
              query: _searchQuery.isEmpty ? null : _searchQuery,
              minSystolic: _minSystolic,
              maxSystolic: _maxSystolic,
              minDiastolic: _minDiastolic,
              maxDiastolic: _maxDiastolic,
              minPulse: _minPulse,
              maxPulse: _maxPulse,
              startDate: _dateRange?.start,
              endDate: _dateRange == null ? null : _endOfDay(_dateRange!.end),
            );

        if (medicationTakenFilter != null) {
          readings = readings.where((r) => r.medicationTaken == medicationTakenFilter).toList();
        }

        if (sort == HistorySort.newest) {
          readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        } else {
          readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }

        hasMore = false;
      } else {
        readings = await ref.read(readingRepositoryProvider).getAll(
              profileId: profile.id,
              limit: _pageSize,
              offset: _loadedCount,
              newestFirst: sort == HistorySort.newest,
            );
        hasMore = readings.length == _pageSize;
      }

      if (!mounted || generation != _loadGeneration) return;

      setState(() {
        if (refresh || _loadedCount == 0) {
          _displayReadings = readings;
        } else {
          _displayReadings.addAll(readings);
        }
        _loadedCount = _displayReadings.length;
        _hasMore = hasMore;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _loadError = error;
        _hasMore = false;
      });
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day + 1)
        .subtract(const Duration(microseconds: 1));
  }

  Map<String, List<Reading>> _groupByMonth(List<Reading> readings) {
    final grouped = <String, List<Reading>>{};
    for (final r in readings) {
      final key = AppDateUtils.formatMonthYear(r.timestamp);
      grouped.putIfAbsent(key, () => []).add(r);
    }
    return grouped;
  }

  Future<void> _loadMore() => _loadReadings();

  Future<void> _deleteReading(Reading reading) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reading'),
        content: const Text('Are you sure you want to delete this reading?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(readingActionsProvider).deleteReading(reading.id);
      if (mounted) await _loadReadings(refresh: true);
    }
  }

  Future<void> _showFilterDialog() async {
    final theme = Theme.of(context);
    final minSysController = TextEditingController(text: _minSystolic?.toString() ?? '');
    final maxSysController = TextEditingController(text: _maxSystolic?.toString() ?? '');
    final minDiaController = TextEditingController(text: _minDiastolic?.toString() ?? '');
    final maxDiaController = TextEditingController(text: _maxDiastolic?.toString() ?? '');
    final minPulseController = TextEditingController(text: _minPulse?.toString() ?? '');
    final maxPulseController = TextEditingController(text: _maxPulse?.toString() ?? '');
    bool? tempMedication = _medicationTakenFilter;
    DateTimeRange? tempDateRange = _dateRange;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Filter Readings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date Range', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    tempDateRange == null
                        ? 'Select Date Range'
                        : '${AppDateUtils.formatDate(tempDateRange!.start)} - ${AppDateUtils.formatDate(tempDateRange!.end)}',
                  ),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: ctx,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: tempDateRange,
                    );
                    if (picked != null && ctx.mounted) {
                      setDialogState(() => tempDateRange = picked);
                    }
                  },
                ),
                if (tempDateRange != null)
                  TextButton(
                    onPressed: () => setDialogState(() => tempDateRange = null),
                    child: const Text('Clear Date Filter'),
                  ),
                const Divider(height: 24),
                Text('Systolic (mmHg)', style: theme.textTheme.labelLarge),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minSysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: maxSysController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Diastolic (mmHg)', style: theme.textTheme.labelLarge),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minDiaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: maxDiaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Pulse (BPM)', style: theme.textTheme.labelLarge),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minPulseController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: maxPulseController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max'),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text('Medication', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                DropdownButtonFormField<bool?>(
                  initialValue: tempMedication,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Readings')),
                    DropdownMenuItem(value: true, child: Text('Medication Taken')),
                    DropdownMenuItem(value: false, child: Text('Medication Not Taken')),
                  ],
                  onChanged: (v) => setDialogState(() => tempMedication = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _dateRange = null;
                  _minSystolic = null;
                  _maxSystolic = null;
                  _minDiastolic = null;
                  _maxDiastolic = null;
                  _minPulse = null;
                  _maxPulse = null;
                  _medicationTakenFilter = null;
                });
                _loadReadings(refresh: true);
                Navigator.pop(ctx);
              },
              child: const Text('Reset All', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _dateRange = tempDateRange;
                  _minSystolic = int.tryParse(minSysController.text.trim());
                  _maxSystolic = int.tryParse(maxSysController.text.trim());
                  _minDiastolic = int.tryParse(minDiaController.text.trim());
                  _maxDiastolic = int.tryParse(maxDiaController.text.trim());
                  _minPulse = int.tryParse(minPulseController.text.trim());
                  _maxPulse = int.tryParse(maxPulseController.text.trim());
                  _medicationTakenFilter = tempMedication;
                });
                _loadReadings(refresh: true);
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeProfileProvider, (_, __) => _loadReadings(refresh: true));

    final grouped = _groupByMonth(_displayReadings);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          PopupMenuButton<HistorySort>(
            icon: const Icon(Icons.sort),
            onSelected: (sort) {
              setState(() => _sort = sort);
              _loadReadings(refresh: true);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: HistorySort.newest, child: Text('Newest First')),
              const PopupMenuItem(value: HistorySort.oldest, child: Text('Oldest First')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search notes, medication, mood...',
                    leading: const Icon(Icons.search),
                    onChanged: (q) {
                      _searchQuery = q;
                      _loadReadings(refresh: true);
                    },
                    trailing: _searchQuery.isNotEmpty
                        ? [
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery = '';
                                _loadReadings(refresh: true);
                              },
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: Icon(
                    _hasActiveFilters() ? Icons.filter_alt : Icons.filter_alt_outlined,
                    color: _hasActiveFilters() ? theme.colorScheme.primary : null,
                  ),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadError != null
                ? EmptyStateWidget(
                    icon: Icons.error_outline,
                    title: 'Unable to load readings',
                    message: _loadError.toString(),
                    actionLabel: 'Retry',
                    onAction: () => _loadReadings(refresh: true),
                  )
                : _displayReadings.isEmpty && !_isLoadingMore
                ? EmptyStateWidget(
                    icon: Icons.history,
                    title: 'No readings found',
                    message: 'Your blood pressure history will appear here.',
                    actionLabel: 'Add Reading',
                    onAction: () async {
                      await context.push(AppRoutes.addReading);
                      if (mounted) await _loadReadings(refresh: true);
                    },
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: grouped.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= grouped.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final monthKey = grouped.keys.elementAt(index);
                      final monthReadings = grouped[monthKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Text(
                              monthKey,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          ...monthReadings.map((reading) {
                            final classification = BpClassification.classify(
                              reading.systolic,
                              reading.diastolic,
                            );
                            return Dismissible(
                              key: ValueKey(reading.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                await _deleteReading(reading);
                                return false;
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      classification.color.withValues(alpha: 0.15),
                                  child: Icon(classification.icon,
                                      color: classification.color, size: 20),
                                ),
                                title: Text(
                                  '${reading.bpDisplay} mmHg',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${reading.pulse} BPM · ${AppDateUtils.formatRelative(reading.timestamp)}',
                                ),
                                trailing: BpStatusBadge(
                                  classification: classification,
                                  compact: true,
                                ),
                                onTap: () async {
                                  await context.push(
                                    '${AppRoutes.editReading}/${reading.id}',
                                  );
                                  if (mounted) {
                                    await _loadReadings(refresh: true);
                                  }
                                },
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

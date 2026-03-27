import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stock_entry_app/core/providers.dart';
import 'package:stock_entry_app/domain/models/barcode_total.dart';
import 'package:stock_entry_app/domain/models/date_barcode_total.dart';
import 'package:stock_entry_app/features/reports/state/reports_providers.dart';
import 'package:stock_entry_app/features/reports/ui/entry_management_page.dart';
import 'package:stock_entry_app/features/stock_entry/ui/barcode_scanner_page.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  bool _rangeMode = false;
  DateTime _singleDate = DateTime.now();
  DateTime _rangeStart = DateTime.now().subtract(Duration(days: 1));
  DateTime _rangeEnd = DateTime.now();

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _rangeStart : _rangeEnd;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _rangeStart = picked;
      } else {
        _rangeEnd = picked;
      }
    });
  }

  Future<void> _pickSingleDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _singleDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
    );

    if (picked == null) return;

    setState(() => _singleDate = picked);
  }

  (DateTime start, DateTime end) _normalizedRange() {
    final a = _rangeStart;
    final b = _rangeEnd;
    if (a.isAfter(b)) {
      return (b, a);
    }
    return (a, b);
  }

  Future<void> _exportCsv(ReportsQuery query) async {
    final repo = ref.read(stockRepositoryProvider);

    try {
      final dir = await _resolveExportDirectory();

      final String fileName;
      if (query.isSingleDate) {
        fileName = 'stock_report_${query.startDate}.csv';
      } else {
        fileName = 'stock_report_${query.startDate}_to_${query.endDate}.csv';
      }

      final filePath = p.join(dir.path, fileName);
      final rows = <List<String>>[];

      // Header
      rows.add(const ['Date', 'Barcode', 'Total Quantity']);

      if (query.isSingleDate) {
        final totals = await repo.fetchBarcodeTotalsForRange(
          startDate: query.startDate,
          endDate: query.endDate,
        );
        for (final BarcodeTotal total in totals) {
          rows.add([
            query.startDate,
            total.barcode,
            total.totalQuantity.toString(),
          ]);
        }
      } else {
        final perDayTotals = await repo.fetchDateBarcodeTotalForRange(
          startDate: query.startDate,
          endDate: query.endDate,
        );
        for (final DateBarcodeTotal total in perDayTotals) {
          rows.add([total.date, total.barcode, total.totalQuantity.toString()]);
        }
      }

      final codec = Csv(lineDelimiter: '\n');
      final csvString = codec.encode(rows);
      final file = File(filePath);
      await file.writeAsString(csvString, encoding: utf8);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV report saved to $filePath')));

      await SharePlus.instance.share(
        ShareParams(files: [XFile(filePath)], text: 'Stock report ($fileName)'),
      );
    } catch (e) {
      log('CSV report export failed: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV report export failed :|')));
    }
  }

  Future<Directory> _resolveExportDirectory() async {
    // Export to app-private storage if we can't/won't access Downloads.
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    return getApplicationDocumentsDirectory();
  }

  ReportsQuery _constructReportsQuery(DateTime start, DateTime end) =>
      ReportsQuery(
        startDate: DateFormat('yyyy-MM-dd').format(start),
        endDate: DateFormat('yyyy-MM-dd').format(end),
      );

  Future<void> _exportCurrent() async {
    final (start, end) = _rangeMode
        ? _normalizedRange()
        : (_singleDate, _singleDate);
    await _exportCsv(_constructReportsQuery(start, end));
  }

  Future<void> _pickScanResult() async {
    final cameraStatus = await Permission.camera.request();
    if (!mounted) return;

    if (!cameraStatus.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera permission is required to scan barcodes'),
        ),
      );
    }

    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (scanned == null) return;
    setState(() => _searchController.text = scanned);
  }

  

  @override
  Widget build(BuildContext context) {
    final (start, end) = _rangeMode
        ? _normalizedRange()
        : (_singleDate, _singleDate);
    final query = _constructReportsQuery(start, end);

    final summaryAsync = ref.watch(reportsSummaryProvider(query));
    final search = _searchController.text.trim().toLowerCase();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ToggleButtons(
              isSelected: [_rangeMode == false, _rangeMode == true],
              onPressed: (i) => setState(() => _rangeMode = i == 1),
              borderRadius: BorderRadius.circular(12),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Single Date'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Date Range'),
                ),
              ],
            ),
            SizedBox(height: 12),

            if (!_rangeMode)
              _DatePickerTile(
                label: 'Date',
                value: DateFormat('yyyy-MM-dd').format(_singleDate),
                onPick: _pickSingleDate,
              )
            else ...[
              _DatePickerTile(
                label: 'Start',
                value: DateFormat('yyyy-MM-dd').format(_rangeStart),
                onPick: () => _pickDate(isStart: true),
              ),
              SizedBox(height: 10),
              _DatePickerTile(
                label: 'End',
                value: DateFormat('yyyy-MM-dd').format(_rangeEnd),
                onPick: () => _pickDate(isStart: false),
              ),
            ],

            SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search barcode (optional)',
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Scan barcode',
                  onPressed: _pickScanResult,
                  icon: Icon(Icons.qr_code_scanner),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),

            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _exportCurrent,
                    icon: Icon(Icons.download_outlined),
                    label: Text('Export CSV'),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  tooltip: 'Manage entries',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EntryManagementPage(query: query),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit_outlined),
                ),
              ],
            ),

            SizedBox(height: 12),
            Expanded(
              child: summaryAsync.when(
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, _) {
                  log('Failed to load reports: $e');
                  return Center(child: Text('Failed to load reports'));
                },
                data: (totals) {
                  final filtered = search.isEmpty
                      ? totals
                      : totals
                            .where(
                              (t) => t.barcode.toLowerCase().contains(search),
                            )
                            .toList();

                  if (filtered.isEmpty) {
                    return Center(child: Text('No entries found.'));
                  }

                  return ListView.separated(
                    itemBuilder: (context, i) {
                      final t = filtered[i];
                      return ListTile(
                        title: Text(t.barcode),
                        trailing: Text(
                          t.totalQuantity.toString(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => Divider(height: 1),
                    itemCount: filtered.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final String value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPick,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label: $value'),
            const Icon(Icons.calendar_month_outlined),
          ],
        ),
      ),
    );
  }
}

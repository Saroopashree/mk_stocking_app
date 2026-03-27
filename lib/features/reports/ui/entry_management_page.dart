import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stock_entry_app/core/providers.dart';
import 'package:stock_entry_app/domain/models/stock_entry.dart';
import 'package:stock_entry_app/features/reports/state/reports_providers.dart';
import 'package:stock_entry_app/features/reports/ui/edit_entry_dialog.dart';
import 'package:stock_entry_app/features/stock_entry/ui/barcode_scanner_page.dart';

class EntryManagementPage extends ConsumerStatefulWidget {
  const EntryManagementPage({super.key, required this.query});

  final ReportsQuery query;

  @override
  ConsumerState<EntryManagementPage> createState() =>
      _EntryManagementPageState();
}

class _EntryManagementPageState extends ConsumerState<EntryManagementPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _onEditPress(StockEntry entry) async {
    final updated = await showEditEntryDialog(context, entry);
    if (updated == null) return;

    try {
      await ref.read(stockRepositoryProvider).updateEntry(updated);
      if (!mounted) return;
      ref.invalidate(entriesForReportsProvider(widget.query));
      ref.invalidate(reportsSummaryProvider(widget.query));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Entry updated')));
    } catch (e) {
      if (!mounted) return;
      log('Entry update failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed')));
    }
  }

  Future<void> _confirmDelete(StockEntry entry) async {
    final repo = ref.read(stockRepositoryProvider);
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete entry?'),
        content: Text(
          'Barcode: ${entry.barcode}\nQuantity: ${entry.quantity}\nDate: ${entry.date}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await repo.deleteEntry(entry.id);
      if (!mounted) return;
      ref.invalidate(entriesForReportsProvider(widget.query));
      ref.invalidate(reportsSummaryProvider(widget.query));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Entry deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesForReportsProvider(widget.query));
    final search = _searchController.text.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.query.isSingleDate
              ? 'Entries (${widget.query.startDate})'
              : 'Entries (${widget.query.startDate} - ${widget.query.endDate})',
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Expanded(
              child: entriesAsync.when(
                loading: () => Center(child: CircularProgressIndicator()),
                error: (e, _) {
                  log(('Failed to load entries: $e'));
                  return Center(child: Text('Failed to load entries'));
                },
                data: (entries) {
                  final filtered = search.isEmpty
                      ? entries
                      : entries
                            .where(
                              (e) => e.barcode.toLowerCase().contains(search),
                            )
                            .toList();

                  if (filtered.isEmpty) {
                    return Center(child: Text('No entries found'));
                  }

                  return ListView.separated(
                    itemBuilder: (context, i) {
                      final entry = filtered[i];
                      return ListTile(
                        title: Text(entry.barcode),
                        subtitle: Text('Date: ${entry.date}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Qty: ${entry.quantity}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                SizedBox(width: 14),
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => _onEditPress(entry),
                                  icon: Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed: () => _confirmDelete(entry),
                                  icon: Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ],
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

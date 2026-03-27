import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stock_entry_app/core/providers.dart';
import 'package:stock_entry_app/domain/models/stock_entry.dart';
import 'package:stock_entry_app/features/reports/state/reports_providers.dart';
import 'package:stock_entry_app/features/stock_entry/ui/barcode_scanner_page.dart';

class StockEntryPage extends ConsumerStatefulWidget {
  const StockEntryPage({super.key});

  @override
  ConsumerState<StockEntryPage> createState() => _StockEntryPageState();
}

class _StockEntryPageState extends ConsumerState<StockEntryPage> {
  final _barcodeController = TextEditingController();
  final _quantityController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  final _quantityFocusNode = FocusNode();

  @override
  void dispose() {
    _barcodeController.dispose();
    _quantityController.dispose();
    _quantityFocusNode.dispose();
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

    final scanned = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => BarcodeScannerPage()));

    if (scanned == null) return;
    setState(() => _barcodeController.text = scanned);

    // Auto-focus on the quantity textfield on successful scanning
    _quantityFocusNode.requestFocus();
  }

  Future<void> _saveEntry() async {
    final repo = ref.read(stockRepositoryProvider);

    final barcode = _barcodeController.text.trim().toLowerCase();
    final quantity = int.tryParse(_quantityController.text.trim());

    if (barcode.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a barcode.')));
      return;
    }
    if (quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid integer quantity.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final entry = StockEntry(
        id: 0,
        barcode: barcode,
        quantity: quantity,
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      await repo.insertEntry(entry);

      ref.invalidate(
        reportsSummaryProvider(
          ReportsQuery(
            startDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
            endDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
          ),
        ),
      );
      setState(() {
        _barcodeController.text = "";
        _quantityController.text = "";
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Entry created')));

      // Auto-open camera to scan the next barcode
      _pickScanResult();
    } catch (e) {
      log('Entry creation failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save entry')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Record daily supermarket stock',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _barcodeController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        suffixIcon: IconButton(
                          tooltip: 'Scan barcode',
                          onPressed: _pickScanResult,
                          icon: Icon(Icons.qr_code_scanner),
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      focusNode: _quantityFocusNode,
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Stock quantity',
                        hintText: 'e.g. 6',
                      ),
                    ),
                    SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateLabel),
                            Icon(Icons.calendar_month_outlined),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveEntry,
                      icon: _isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.save_outlined),
                      label: Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

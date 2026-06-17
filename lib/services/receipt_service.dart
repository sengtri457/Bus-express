import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/error/result.dart';
import '../core/utils/date_helpers.dart';

class ReceiptService {
  ReceiptService._();

  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static bool _fontsLoading = false;
  static Completer<void>? _fontsCompleter;

  static Future<void> _ensureFonts() async {
    if (_regularFont != null && _boldFont != null) return;
    if (_fontsLoading) return _fontsCompleter!.future;

    _fontsLoading = true;
    _fontsCompleter = Completer<void>();

    try {
      final regular =
          await http.get(Uri.parse(_robotoRegularUrl));
      final bold =
          await http.get(Uri.parse(_robotoBoldUrl));

      _regularFont = pw.Font.ttf(
        ByteData.view(Uint8List.fromList(regular.bodyBytes).buffer),
      );
      _boldFont = pw.Font.ttf(
        ByteData.view(Uint8List.fromList(bold.bodyBytes).buffer),
      );
    } catch (e) {
      debugPrint('Font download failed, using fallback: $e');
    } finally {
      _fontsLoading = false;
      _fontsCompleter!.complete();
    }
  }

  static const _robotoRegularUrl =
      'https://fonts.gstatic.com/s/roboto/v30/KFOmCnqEu92Fr1Mu4mxP.ttf';
  static const _robotoBoldUrl =
      'https://fonts.gstatic.com/s/roboto/v30/KFOlCnqEu92Fr1MmEU9fBBc9.ttf';

  static Future<Result<Uint8List>> generate({
    required List<Map<String, dynamic>> bookings,
  }) async {
    try {
      await _ensureFonts();

      final doc = pw.Document();

      final first = bookings.first;
      final trip = first['trips'] as Map<String, dynamic>?;
      final schedule = trip?['schedules'] as Map<String, dynamic>?;
      final route = schedule?['routes'] as Map<String, dynamic>?;
      final bus = schedule?['buses'] as Map<String, dynamic>?;

      final totalPrice = bookings.fold<double>(
        0,
        (s, b) => s + (b['total_price'] as num).toDouble(),
      );

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(
            base: _regularFont ?? pw.Font.helvetica(),
            bold: _boldFont ?? pw.Font.helveticaBold(),
          ),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildInfoRow('Receipt #', first['id'] as String),
              _buildInfoRow(
                'Issued',
                DateHelpers.formatFullDate(
                  (first['booked_at'] as String?) ??
                      DateTime.now().toIso8601String(),
                ),
              ),
              _buildInfoRow(
                'Route',
                '${route?['origin'] ?? '?'} to ${route?['destination'] ?? '?'}',
              ),
              _buildInfoRow(
                'Date',
                DateHelpers.formatFullDate(
                  (trip?['trip_date'] as String?) ?? '',
                ),
              ),
              _buildInfoRow(
                'Departure',
                schedule != null
                    ? DateHelpers.formatTime(
                        schedule['departure_time'] as String,
                      )
                    : '-',
              ),
              if (bus != null)
                _buildInfoRow(
                  'Bus',
                  '${bus['model'] ?? '?'} (${bus['plate_number'] ?? '?'})',
                ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Booking Details',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              _buildBookingTable(bookings),
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total: \$${totalPrice.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Booking Ref: #${(first['id'] as String).substring(0, 8).toUpperCase()}',
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Thank you for traveling with Bus Express!',
                style: pw.TextStyle(fontSize: 11, color: PdfColors.grey),
              ),
              pw.Text(
                'This is your official receipt. Please keep it for your records.',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      return Success(bytes);
    } catch (e) {
      return Failure('Failed to generate receipt', error: e);
    }
  }

  static pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'BUS EXPRESS',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.Text(
          'OFFICIAL RECEIPT',
          style: pw.TextStyle(
            fontSize: 14,
            color: PdfColors.blue600,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey),
            ),
          ),
          pw.Text(value, style: pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _buildBookingTable(List<Map<String, dynamic>> bookings) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _tableHeader('Seat'),
            _tableHeader('Status'),
            _tableHeader('Price'),
          ],
        ),
        ...bookings.map(
          (b) => pw.TableRow(
            children: [
              _tableCell(b['seat_number'] as String),
              _tableCell(b['status'] as String),
              _tableCell(
                '\$${(b['total_price'] as num).toStringAsFixed(2)}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 11)),
    );
  }

  static Future<void> share(Uint8List bytes, String bookingId) async {
    if (kIsWeb) return;
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/receipt_$bookingId.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Bus Express Receipt',
    );
  }
}

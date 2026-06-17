import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../core/error/result.dart';

class ResendEmailService {
  ResendEmailService._();

  static const _resendApiUrl = 'https://api.resend.com/emails';

  static Future<Result<void>> sendReceipt({
    required String to,
    required Uint8List pdfBytes,
    required String bookingRef,
    required String origin,
    required String destination,
    required String tripDate,
    required String departureTime,
    required int seatCount,
    required double totalPrice,
    required String passengerName,
  }) async {
    final pdfBase64 = base64Encode(pdfBytes);

    final htmlBody = '''
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; color: #333; max-width: 600px; margin: 0 auto;">
  <div style="background: #1A73E8; padding: 24px; text-align: center; border-radius: 12px 12px 0 0;">
    <h1 style="color: #fff; margin: 0; font-size: 24px;">Bus Express</h1>
    <p style="color: #BBDEFB; margin: 4px 0 0;">Official Receipt</p>
  </div>
  <div style="padding: 24px; border: 1px solid #E5E7EB; border-top: none; border-radius: 0 0 12px 12px;">
    <p>Dear <strong>$passengerName</strong>,</p>
    <p>Thank you for booking with Bus Express. Your booking has been confirmed.</p>
    <table style="width: 100%; border-collapse: collapse; margin: 16px 0;">
      <tr><td style="padding: 8px 0; color: #6B7280;">Route</td><td style="padding: 8px 0; font-weight: 600;">$origin to $destination</td></tr>
      <tr><td style="padding: 8px 0; color: #6B7280;">Date</td><td style="padding: 8px 0; font-weight: 600;">$tripDate</td></tr>
      <tr><td style="padding: 8px 0; color: #6B7280;">Departure</td><td style="padding: 8px 0; font-weight: 600;">$departureTime</td></tr>
      <tr><td style="padding: 8px 0; color: #6B7280;">Seats</td><td style="padding: 8px 0; font-weight: 600;">$seatCount</td></tr>
      <tr><td style="padding: 8px 0; color: #6B7280;">Total</td><td style="padding: 8px 0; font-weight: 600; color: #1A73E8;">\$${totalPrice.toStringAsFixed(2)}</td></tr>
      <tr><td style="padding: 8px 0; color: #6B7280;">Reference</td><td style="padding: 8px 0; font-weight: 600; font-family: monospace;">$bookingRef</td></tr>
    </table>
    <p style="font-size: 12px; color: #9CA3AF;">Your receipt is attached as a PDF. Show the QR code to the conductor when boarding.</p>
    <hr style="border: none; border-top: 1px solid #E5E7EB; margin: 16px 0;">
    <p style="font-size: 11px; color: #9CA3AF;">Bus Express &mdash; Safe travels!</p>
  </div>
</body>
</html>
''';

    final payload = <String, dynamic>{
      'to': to,
      'subject': 'Your Bus Express Receipt - $bookingRef',
      'html': htmlBody,
      'attachments': [
        {
          'filename': 'BusExpress_Receipt_$bookingRef.pdf',
          'content': pdfBase64,
        },
      ],
      'mailtrapApiKey': dotenv.env['MAILTRAP_API_KEY'],
    };

    // Only fall through to direct API if the Edge Function had a network
    // error (connection failed). If it returned a response (even 403 from
    // Resend), surface that error directly.
    final edgeResult = await _tryEdgeFunction(payload);
    if (edgeResult is Success) return edgeResult;
    if (edgeResult is Failure && !edgeResult.message.startsWith('NETWORK_ERROR:')) {
      return edgeResult;
    }

    final directResult = await _tryDirectApi(payload);
    return directResult;
  }

  static const _functionsBaseUrl =
      'https://celqfbybspfyecgmnhaz.supabase.co/functions/v1';

  static Future<Result<void>> _tryEdgeFunction(
    Map<String, dynamic> payload,
  ) async {
    // Use text/plain (simple request, no CORS preflight on web) instead of
    // application/json (which triggers preflight). The function parses JSON
    // from the body regardless of Content-Type.
    try {
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/send-receipt'),
        headers: {'Content-Type': 'text/plain'},
        body: jsonEncode(payload),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      }
      // Dev mode: Resend test mode, function logged the email
      if (response.body.contains('"devMode":true') ||
          response.body.contains('"devMode": true')) {
        debugPrint('[Email] Dev mode — email logged to Supabase logs');
        return const Success(null);
      }
      debugPrint('[Email] Edge returned ${response.statusCode}: ${response.body}');
      final msg = response.statusCode == 403 && response.body.contains('testing emails')
          ? 'Resend test mode: enter your own email (sengtri457@gmail.com) in the booking form, '
              'or verify a domain at resend.com/domains for production.'
          : 'Edge function error (${response.statusCode}): ${response.body}';
      return Failure(msg);
    } catch (e) {
      debugPrint('[Email] Edge function FAILED ($e)');
      return Failure('NETWORK_ERROR: $e');
    }
  }

  static Future<Result<void>> _tryDirectApi(
    Map<String, dynamic> payload,
  ) async {
    final apiKey = dotenv.env['RESEND_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      return const Failure(
        'Email not sent. Deploy `supabase functions deploy send-receipt` '
        'or set RESEND_API_KEY in .env',
      );
    }

    try {
      final response = await http.post(
        Uri.parse(_resendApiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': 'BusExpress <onboarding@resend.dev>',
          'to': [payload['to']],
          'subject': payload['subject'],
          'html': payload['html'],
          'attachments': payload['attachments'],
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Success(null);
      }
      return Failure(
        'Email send failed (${response.statusCode}): ${response.body}',
      );
    } catch (e) {
      final hint = kIsWeb
          ? 'Deploy `supabase functions deploy send-receipt` for web support.'
          : 'Check your network connection.';
      return Failure('Email not sent. $hint');
    }
  }
}

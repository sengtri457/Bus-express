import 'package:flutter/material.dart';
import '../../../l10n/tr_extension.dart';

class TripPunctuality {
  final String status; // 'on_time', 'delayed', 'early', 'unknown'
  final String label; // "On Time", "Delayed", "Early", "Running Late", etc.
  final String message; // E.g., "Departed 8m late", "Arrived 5m early"
  final Color color;
  final IconData icon;

  TripPunctuality({
    required this.status,
    required this.label,
    required this.message,
    required this.color,
    required this.icon,
  });

  /// Computes punctuality status dynamically based on trip & schedules data.
  static TripPunctuality calculate(Map<String, dynamic> trip, BuildContext context) {
    try {
      final tripStatus = trip['status'] as String? ?? 'scheduled';
      final tripDateStr = trip['trip_date'] as String?;
      final schedule = trip['schedules'] as Map<String, dynamic>?;

      if (tripDateStr == null || schedule == null) {
        return TripPunctuality(
          status: 'unknown',
          label: context.tr.tripPunctScheduled,
          message: context.tr.tripPunctTripStatus(tripStatus),
          color: const Color(0xFF1A73E8),
          icon: Icons.schedule_rounded,
        );
      }

      final departureTimeStr = schedule['departure_time'] as String?;
      final arrivalTimeStr = schedule['arrival_time'] as String?;

      if (departureTimeStr == null) {
        return TripPunctuality(
          status: 'unknown',
          label: context.tr.tripPunctScheduled,
          message: context.tr.tripPunctTripStatus(tripStatus),
          color: const Color(0xFF1A73E8),
          icon: Icons.schedule_rounded,
        );
      }

      // Parse planned departure DateTime
      final plannedDeparture = _parsePlannedDateTime(tripDateStr, departureTimeStr);

      // 1. TRIP IS SCHEDULED (Not departed yet)
      if (tripStatus == 'scheduled') {
        final now = DateTime.now();
        final diff = now.difference(plannedDeparture);

        // If current time is more than 5 minutes past scheduled departure and still not started:
        if (diff.inMinutes > 5) {
          return TripPunctuality(
            status: 'delayed',
            label: context.tr.tripPunctDelayedDeparture,
            message: context.tr.tripPunctOverdueMins(diff.inMinutes),
            color: const Color(0xFFEF4444), // Premium red
            icon: Icons.alarm_rounded,
          );
        } else {
          return TripPunctuality(
            status: 'on_time',
            label: context.tr.tripPunctOnTime,
            message: context.tr.tripPunctReadyDepart,
            color: const Color(0xFF16A34A), // Premium green
            icon: Icons.check_circle_rounded,
          );
        }
      }

      // 2. TRIP IS IN PROGRESS (Departed, but not arrived yet)
      if (tripStatus == 'in_progress') {
        final departedAtStr = trip['departed_at'] as String?;
        if (departedAtStr == null) {
          return TripPunctuality(
            status: 'on_time',
            label: context.tr.tripPunctOnTrack,
            message: context.tr.tripPunctInProgress,
            color: const Color(0xFF16A34A),
            icon: Icons.directions_bus_rounded,
          );
        }

        final actualDeparture = DateTime.parse(departedAtStr).toLocal();
        final depDiff = actualDeparture.difference(plannedDeparture).inMinutes;

        String depMessage;
        if (depDiff > 5) {
          depMessage = context.tr.tripPunctDepartedLate(depDiff);
        } else if (depDiff < -5) {
          depMessage = context.tr.tripPunctDepartedEarly(depDiff.abs());
        } else {
          depMessage = context.tr.tripPunctDepartedOnTime;
        }

        // Check if currently running past scheduled arrival
        if (arrivalTimeStr != null) {
          final plannedArrival = _parsePlannedDateTime(tripDateStr, arrivalTimeStr, departureTimeStr: departureTimeStr);
          final now = DateTime.now();
          if (now.isAfter(plannedArrival)) {
            final arrDiff = now.difference(plannedArrival).inMinutes;
            if (arrDiff > 5) {
              return TripPunctuality(
                status: 'delayed',
                label: context.tr.tripPunctRunningLate,
                message: '$depMessage • ${context.tr.tripPunctOverdueMins(arrDiff)}',
                color: const Color(0xFFF59E0B), // Premium Amber/Orange
                icon: Icons.warning_amber_rounded,
              );
            }
          }
        }

        return TripPunctuality(
          status: depDiff > 5 ? 'delayed' : (depDiff < -5 ? 'early' : 'on_time'),
          label: depDiff > 5 ? context.tr.tripPunctDelayed : context.tr.tripPunctOnTime,
          message: depMessage,
          color: depDiff > 5 ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
          icon: depDiff > 5 ? Icons.alarm_on_rounded : Icons.check_circle_rounded,
        );
      }

      // 3. TRIP IS COMPLETED
      if (tripStatus == 'completed') {
        final arrivedAtStr = trip['arrived_at'] as String?;
        if (arrivedAtStr == null) {
          return TripPunctuality(
            status: 'on_time',
            label: context.tr.tripPunctCompleted,
            message: context.tr.tripPunctTripFinished,
            color: const Color(0xFF6B7280),
            icon: Icons.check_circle_rounded,
          );
        }

        final actualArrival = DateTime.parse(arrivedAtStr).toLocal();
        if (arrivalTimeStr == null) {
          return TripPunctuality(
            status: 'on_time',
            label: context.tr.tripPunctCompleted,
            message: context.tr.tripPunctArrivedAt(_formatTimeOnly(actualArrival)),
            color: const Color(0xFF6B7280),
            icon: Icons.check_circle_rounded,
          );
        }

        final plannedArrival = _parsePlannedDateTime(tripDateStr, arrivalTimeStr, departureTimeStr: departureTimeStr);
        final arrDiff = actualArrival.difference(plannedArrival).inMinutes;

        String arrMessage;
        if (arrDiff > 5) {
          arrMessage = context.tr.tripPunctArrivedLate(arrDiff);
        } else if (arrDiff < -5) {
          arrMessage = context.tr.tripPunctArrivedEarly(arrDiff.abs());
        } else {
          arrMessage = context.tr.tripPunctArrivedOnTime;
        }

        return TripPunctuality(
          status: arrDiff > 5 ? 'delayed' : (arrDiff < -5 ? 'early' : 'on_time'),
          label: arrDiff > 5 ? context.tr.tripPunctDelayedArrival : context.tr.tripPunctOnTimeArrival,
          message: arrMessage,
          color: arrDiff > 5 ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
          icon: arrDiff > 5 ? Icons.error_outline_rounded : Icons.check_circle_rounded,
        );
      }

      // 4. TRIP IS CANCELLED
      if (tripStatus == 'cancelled') {
        return TripPunctuality(
          status: 'unknown',
          label: context.tr.tripPunctCancelled,
          message: context.tr.tripPunctMessageCancelled,
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
        );
      }

      // Fallback
      return TripPunctuality(
        status: 'unknown',
        label: context.tr.tripPunctScheduled,
        message: context.tr.tripPunctTripStatus(tripStatus),
        color: const Color(0xFF1A73E8),
        icon: Icons.schedule_rounded,
      );
    } catch (e) {
      debugPrint('[Punctuality Calculation] Error: $e');
      return TripPunctuality(
        status: 'unknown',
        label: context.tr.tripPunctErrorComputing,
        message: context.tr.tripPunctErrorComputing,
        color: Colors.grey,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  /// Parses schedule time string (like "14:30:00" or "14:30") and combines it with trip date.
  /// If [departureTimeStr] is provided, it handles midnight crossing by shifting the arrival date.
  static DateTime _parsePlannedDateTime(String dateStr, String timeStr, {String? departureTimeStr}) {
    try {
      final cleanTime = timeStr.trim().split(' ')[0]; // Split optional AM/PM if any
      final parts = cleanTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final date = DateTime.parse(dateStr);
      var dt = DateTime(date.year, date.month, date.day, hour, minute);

      if (departureTimeStr != null) {
        final cleanDepTime = departureTimeStr.trim().split(' ')[0];
        final depParts = cleanDepTime.split(':');
        final depHour = int.parse(depParts[0]);
        final depMinute = int.parse(depParts[1]);

        final depTotalMinutes = depHour * 60 + depMinute;
        final arrTotalMinutes = hour * 60 + minute;
        if (arrTotalMinutes < depTotalMinutes) {
          dt = dt.add(const Duration(days: 1));
        }
      }
      return dt;
    } catch (_) {
      return DateTime.parse(dateStr);
    }
  }

  static String _formatTimeOnly(DateTime dt) {
    final h = dt.hour;
    final period = h >= 12 ? 'PM' : 'AM';
    final dh = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$dh:${dt.minute.toString().padLeft(2, '0')} $period';
  }
}

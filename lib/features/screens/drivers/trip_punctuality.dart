import 'package:flutter/material.dart';

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
  static TripPunctuality calculate(Map<String, dynamic> trip) {
    try {
      final tripStatus = trip['status'] as String? ?? 'scheduled';
      final tripDateStr = trip['trip_date'] as String?;
      final schedule = trip['schedules'] as Map<String, dynamic>?;

      if (tripDateStr == null || schedule == null) {
        return TripPunctuality(
          status: 'unknown',
          label: 'Scheduled',
          message: 'Status: scheduled',
          color: const Color(0xFF1A73E8),
          icon: Icons.schedule_rounded,
        );
      }

      final departureTimeStr = schedule['departure_time'] as String?;
      final arrivalTimeStr = schedule['arrival_time'] as String?;

      if (departureTimeStr == null) {
        return TripPunctuality(
          status: 'unknown',
          label: 'Scheduled',
          message: 'Status: scheduled',
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
            label: 'Delayed Departure',
            message: 'Overdue by ${diff.inMinutes} mins',
            color: const Color(0xFFEF4444), // Premium red
            icon: Icons.alarm_rounded,
          );
        } else {
          return TripPunctuality(
            status: 'on_time',
            label: 'On Time',
            message: 'Ready to depart on time',
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
            label: 'On Track',
            message: 'Trip in progress',
            color: const Color(0xFF16A34A),
            icon: Icons.directions_bus_rounded,
          );
        }

        final actualDeparture = DateTime.parse(departedAtStr).toLocal();
        final depDiff = actualDeparture.difference(plannedDeparture).inMinutes;

        String depMessage;
        if (depDiff > 5) {
          depMessage = 'Departed $depDiff mins late';
        } else if (depDiff < -5) {
          depMessage = 'Departed ${depDiff.abs()} mins early';
        } else {
          depMessage = 'Departed on time';
        }

        // Check if currently running past scheduled arrival
        if (arrivalTimeStr != null) {
          final plannedArrival = _parsePlannedDateTime(tripDateStr, arrivalTimeStr);
          final now = DateTime.now();
          if (now.isAfter(plannedArrival)) {
            final arrDiff = now.difference(plannedArrival).inMinutes;
            if (arrDiff > 5) {
              return TripPunctuality(
                status: 'delayed',
                label: 'Running Late',
                message: '$depMessage • Overdue by $arrDiff mins',
                color: const Color(0xFFF59E0B), // Premium Amber/Orange
                icon: Icons.warning_amber_rounded,
              );
            }
          }
        }

        return TripPunctuality(
          status: depDiff > 5 ? 'delayed' : (depDiff < -5 ? 'early' : 'on_time'),
          label: depDiff > 5 ? 'Delayed' : 'On Time',
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
            label: 'Completed',
            message: 'Trip finished',
            color: const Color(0xFF6B7280),
            icon: Icons.check_circle_rounded,
          );
        }

        final actualArrival = DateTime.parse(arrivedAtStr).toLocal();
        if (arrivalTimeStr == null) {
          return TripPunctuality(
            status: 'on_time',
            label: 'Completed',
            message: 'Arrived at ${_formatTimeOnly(actualArrival)}',
            color: const Color(0xFF6B7280),
            icon: Icons.check_circle_rounded,
          );
        }

        final plannedArrival = _parsePlannedDateTime(tripDateStr, arrivalTimeStr);
        final arrDiff = actualArrival.difference(plannedArrival).inMinutes;

        String arrMessage;
        if (arrDiff > 5) {
          arrMessage = 'Arrived $arrDiff mins late';
        } else if (arrDiff < -5) {
          arrMessage = 'Arrived ${arrDiff.abs()} mins early';
        } else {
          arrMessage = 'Arrived on time';
        }

        return TripPunctuality(
          status: arrDiff > 5 ? 'delayed' : (arrDiff < -5 ? 'early' : 'on_time'),
          label: arrDiff > 5 ? 'Delayed Arrival' : 'On Time Arrival',
          message: arrMessage,
          color: arrDiff > 5 ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
          icon: arrDiff > 5 ? Icons.error_outline_rounded : Icons.check_circle_rounded,
        );
      }

      // 4. TRIP IS CANCELLED
      if (tripStatus == 'cancelled') {
        return TripPunctuality(
          status: 'unknown',
          label: 'Cancelled',
          message: 'Trip was cancelled',
          color: const Color(0xFFEF4444),
          icon: Icons.cancel_rounded,
        );
      }

      // Fallback
      return TripPunctuality(
        status: 'unknown',
        label: 'Scheduled',
        message: 'Trip status: $tripStatus',
        color: const Color(0xFF1A73E8),
        icon: Icons.schedule_rounded,
      );
    } catch (e) {
      debugPrint('[Punctuality Calculation] Error: $e');
      return TripPunctuality(
        status: 'unknown',
        label: 'Error',
        message: 'Error computing status',
        color: Colors.grey,
        icon: Icons.error_outline_rounded,
      );
    }
  }

  /// Parses schedule time string (like "14:30:00" or "14:30") and combines it with trip date.
  static DateTime _parsePlannedDateTime(String dateStr, String timeStr) {
    try {
      final cleanTime = timeStr.trim().split(' ')[0]; // Split optional AM/PM if any
      final parts = cleanTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final date = DateTime.parse(dateStr);
      return DateTime(date.year, date.month, date.day, hour, minute);
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

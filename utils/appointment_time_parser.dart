import 'package:intl/intl.dart';
import 'package:flutter_application_1/utils/time_parser.dart';

/// Parses appointment time range and returns start and end DateTimes
/// Input formats: 
/// - "10:00-11:00" (24-hour)
/// - "10:00 - 11:00" (24-hour with spaces)
/// - "10:00 AM - 11:00 AM" (12-hour with AM/PM)
/// 
/// Returns a map with 'start' and 'end' DateTime objects
/// ⚠️ CRITICAL: Handles minutes correctly!
Map<String, DateTime> parseAppointmentTimeRange(
  String timeRange, {
  required DateTime appointmentDate,
}) {
  try {
    print('[AppointmentTimeParser] Parsing range: "$timeRange"');
    
    // Try splitting on ' - ' first (with spaces, more reliable)
    List<String> parts;
    if (timeRange.contains(' - ')) {
      parts = timeRange.split(' - ');
    } else if (timeRange.contains('-')) {
      // Less reliable: could have multiple dashes, but try it
      final allParts = timeRange.split('-');
      if (allParts.length >= 2) {
        // Assume first is start, rest joined is end
        // This handles cases like "10:00-11:00" or "10:15-11:45"
        parts = [allParts[0], allParts.sublist(1).join('-')];
      } else {
        throw FormatException('Invalid range format: $timeRange');
      }
    } else {
      throw FormatException('No range separator found in: $timeRange');
    }

    if (parts.length != 2) {
      throw FormatException('Expected 2 parts in range, got ${parts.length}: $timeRange');
    }

    final startTimeStr = parts[0].trim();
    final endTimeStr = parts[1].trim();

    print('[AppointmentTimeParser]   Start: "$startTimeStr", End: "$endTimeStr"');

    // Parse using TimeParser which handles both 24-hour and 12-hour AM/PM formats
    final startRecord = TimeParser.parseTime(startTimeStr);
    final endRecord = TimeParser.parseTime(endTimeStr);
    
    final startHour = startRecord.hour;
    final startMinute = startRecord.minute;
    final endHour = endRecord.hour;
    final endMinute = endRecord.minute;

    if (startHour == null || endHour == null) {
      throw FormatException('Could not parse times from: "$timeRange"');
    }

    final startDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      startHour,
      startMinute ?? 0,
    );

    final endDateTime = DateTime(
      appointmentDate.year,
      appointmentDate.month,
      appointmentDate.day,
      endHour,
      endMinute ?? 0,
    );

    // Validate that end time is after start time
    if (endDateTime.isBefore(startDateTime)) {
      throw FormatException(
        'End time ($endTimeStr) cannot be before start time ($startTimeStr)',
      );
    }

    print('[AppointmentTimeParser] ✅ Parsed range:');
    print('[AppointmentTimeParser]   Start: ${startDateTime.toIso8601String()}');
    print('[AppointmentTimeParser]   End:   ${endDateTime.toIso8601String()}');

    return {
      'start': startDateTime,
      'end': endDateTime,
    };
  } catch (e) {
    print('[AppointmentTimeParser] ❌ Error parsing time range "$timeRange": $e');
    // Return current appointment date with default times on error
    return {
      'start': appointmentDate,
      'end': appointmentDate.add(const Duration(hours: 1)),
    };
  }
}

/// Get duration in minutes between start and end times
int getAppointmentDurationMinutes(
  String timeRange, {
  required DateTime appointmentDate,
}) {
  try {
    final times = parseAppointmentTimeRange(timeRange, appointmentDate: appointmentDate);
    final startTime = times['start']!;
    final endTime = times['end']!;
    
    final duration = endTime.difference(startTime);
    return duration.inMinutes;
  } catch (e) {
    print('[AppointmentTimeParser] Error calculating duration: $e');
    return 60; // Default to 1 hour
  }
}

/// Get remaining duration in seconds until appointment end time
int getRemainingSecondsUntilEnd(
  String timeRange, {
  required DateTime appointmentDate,
}) {
  try {
    final times = parseAppointmentTimeRange(timeRange, appointmentDate: appointmentDate);
    final endTime = times['end']!;
    
    final now = DateTime.now();
    if (now.isAfter(endTime)) {
      return 0; // Appointment has ended
    }
    
    final remaining = endTime.difference(now);
    return remaining.inSeconds;
  } catch (e) {
    print('[AppointmentTimeParser] Error calculating remaining time: $e');
    return 0;
  }
}

/// Check if current time is within the appointment slot
bool isWithinAppointmentSlot(
  String timeRange, {
  required DateTime appointmentDate,
}) {
  try {
    final times = parseAppointmentTimeRange(timeRange, appointmentDate: appointmentDate);
    final startTime = times['start']!;
    final endTime = times['end']!;
    
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  } catch (e) {
    print('[AppointmentTimeParser] Error checking slot: $e');
    return false;
  }
}

/// Check if current time is before the appointment start
bool isBeforeAppointmentStart(
  String timeRange, {
  required DateTime appointmentDate,
}) {
  try {
    final times = parseAppointmentTimeRange(timeRange, appointmentDate: appointmentDate);
    final startTime = times['start']!;
    
    final now = DateTime.now();
    return now.isBefore(startTime);
  } catch (e) {
    print('[AppointmentTimeParser] Error checking start: $e');
    return true;
  }
}

/// Check if appointment time has ended
bool hasAppointmentEnded(
  String timeRange, {
  required DateTime appointmentDate,
}) {
  try {
    final times = parseAppointmentTimeRange(timeRange, appointmentDate: appointmentDate);
    final endTime = times['end']!;
    
    final now = DateTime.now();
    return now.isAfter(endTime);
  } catch (e) {
    print('[AppointmentTimeParser] Error checking end: $e');
    return false;
  }
}

/// Get formatted countdown string
String getCountdownString(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}h';
  }
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}m';
}

/// ============================================
/// MANDATORY HELPER: Parse appointment date + time
/// ============================================
/// 
/// Parses appointment time range string and combines with date
/// Returns map with 'start' and 'end' DateTime objects
/// 
/// Usage:
/// final times = parseAppointmentDateTime("10:00-11:00", appointmentDate);
/// final startTime = times['start'];  // 2024-03-31 10:00:00
/// final endTime = times['end'];      // 2024-03-31 11:00:00
Map<String, DateTime> parseAppointmentDateTime(String timeRange, DateTime date) {
  try {
    final parts = timeRange.split('-');
    if (parts.length != 2) {
      throw FormatException('Invalid time range format: $timeRange. Expected: HH:mm-HH:mm');
    }

    final start = parts[0].trim().split(':');
    final end = parts[1].trim().split(':');

    if (start.length != 2 || end.length != 2) {
      throw FormatException('Invalid time format. Expected HH:mm');
    }

    final startHour = int.parse(start[0]);
    final startMinute = int.parse(start[1]);
    final endHour = int.parse(end[0]);
    final endMinute = int.parse(end[1]);

    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startHour,
      startMinute,
    );

    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endHour,
      endMinute,
    );

    // Validate that end time is after start time
    if (endDateTime.isBefore(startDateTime)) {
      throw FormatException(
        'End time ($endHour:$endMinute) cannot be before start time ($startHour:$startMinute)',
      );
    }

    return {
      'start': startDateTime,
      'end': endDateTime,
    };
  } catch (e) {
    print('[AppointmentTimeParser] ❌ Error parsing appointment datetime: $e');
    throw FormatException('Failed to parse appointment date/time: $e');
  }
}

/// Safe time parsing utility for appointment times stored in Firestore
/// Handles multiple time formats with proper AM/PM and minute preservation
/// All times are treated as Asia/Karachi timezone (UTC+5)
///
/// Supported formats:
/// - "12:15 PM" → 12:15
/// - "9:30 AM" → 09:30
/// - "14:30" (24-hour) → 14:30
/// - "12:15 PM - 2:00 PM" (range) → extracts start: 12:15
class TimeParser {
  /// Parse time string and return (hour, minute) tuple
  /// ⚠️ IMPORTANT: Minutes MUST be preserved correctly
  static ({int? hour, int? minute}) parseTime(String? timeString) {
    if (timeString == null || timeString.trim().isEmpty) {
      return (hour: null, minute: null);
    }

    timeString = timeString.trim();
    print('[TimeParser] 🔍 Parsing: "$timeString"');

    try {
      // Handle time range format: "12:15 PM - 2:00 PM" or "10:00-11:00"
      // Extract just the start time (before the dash/range separator)
      if (timeString.contains(' - ') || (timeString.contains('-') && timeString.split('-').length >= 2)) {
        // For ranges like "12:15 PM - 2:00 PM", split on ' - ' first
        final rangeParts = timeString.contains(' - ') 
            ? timeString.split(' - ')
            : timeString.split('-');
        
        if (rangeParts.isNotEmpty) {
          timeString = rangeParts[0].trim(); // Use only start time
          print('[TimeParser] 📍 Extracted start time from range: "$timeString"');
        }
      }

      // Handle AM/PM format: "2 PM", "2:30 PM", "2:15 AM"
      if (timeString.toUpperCase().contains('AM') || timeString.toUpperCase().contains('PM')) {
        return _parseAmPmFormat(timeString);
      }

      // Handle 24-hour standard formats: "10:30" or "10-30"
      if (timeString.contains(':') || timeString.contains('-')) {
        return _parseStandardFormat(timeString);
      }

      // Try parsing as single hour
      final hour = int.tryParse(timeString);
      if (hour != null && hour >= 0 && hour < 24) {
        return (hour: hour, minute: 0);
      }

      print('[TimeParser] ❌ Could not parse: "$timeString"');
      return (hour: null, minute: null);
    } catch (e) {
      print('[TimeParser] ❌ Exception parsing "$timeString": $e');
      return (hour: null, minute: null);
    }
  }

  /// Parse AM/PM format: "2:30 PM", "9:15 AM", "12 PM"
  /// ⚠️ CRITICAL: Must preserve minutes!
  static ({int? hour, int? minute}) _parseAmPmFormat(String timeString) {
    try {
      print('[TimeParser] 🕐 Parsing AM/PM: "$timeString"');
      
      final upperStr = timeString.toUpperCase();
      final isAfternoon = upperStr.contains('PM');
      final isMorning = upperStr.contains('AM');
      
      if (!isAfternoon && !isMorning) {
        print('[TimeParser] ❌ No AM/PM found in: "$timeString"');
        return (hour: null, minute: null);
      }

      // Remove AM/PM markers - CAREFULLY preserve everything else
      String cleanTime = timeString
          .replaceAll(RegExp(r'\s*[AP]M\s*', caseSensitive: false), '')
          .trim();

      print('[TimeParser]   After removing AM/PM: "$cleanTime"');

      // Parse hour and minute - try : first, then -
      int? hour;
      int? minute;

      if (cleanTime.contains(':')) {
        final parts = cleanTime.split(':');
        hour = int.tryParse(parts[0].trim());
        minute = parts.length > 1 ? int.tryParse(parts[1].trim()) : 0;
        print('[TimeParser]   Colon format: hour=$hour, minute=$minute');
      } else if (cleanTime.contains('-')) {
        final parts = cleanTime.split('-');
        hour = int.tryParse(parts[0].trim());
        minute = parts.length > 1 ? int.tryParse(parts[1].trim()) : 0;
        print('[TimeParser]   Dash format: hour=$hour, minute=$minute');
      } else {
        // Just hour, no minutes
        hour = int.tryParse(cleanTime);
        minute = 0;
        print('[TimeParser]   Hour only: hour=$hour, minute=0');
      }

      if (hour == null) {
        print('[TimeParser] ❌ Could not parse hour from: "$cleanTime"');
        return (hour: null, minute: null);
      }

      minute ??= 0;

      // Validate ranges
      if (hour < 0 || hour > 12 || minute < 0 || minute >= 60) {
        print('[TimeParser] ❌ Invalid ranges: hour=$hour (should be 1-12), minute=$minute (should be 0-59)');
        return (hour: null, minute: null);
      }

      // Convert to 24-hour format
      int hour24 = hour;
      if (isAfternoon && hour != 12) {
        hour24 = hour + 12;  // PM: 1-11 PM → 13-23
      } else if (isMorning && hour == 12) {
        hour24 = 0;  // 12 AM → 00:00
      }
      // else: 12 PM stays 12, 1-11 AM stay as is

      print('[TimeParser] ✅ Parsed: "$timeString" → $hour24:${minute.toString().padLeft(2, '0')}');
      return (hour: hour24, minute: minute);
    } catch (e) {
      print('[TimeParser] ❌ Error parsing AM/PM "$timeString": $e');
      return (hour: null, minute: null);
    }
  }

  /// Parse 24-hour format: "10:30" or "14-45"
  static ({int? hour, int? minute}) _parseStandardFormat(String timeString) {
    try {
      final parts = timeString.contains(':') ? timeString.split(':') : timeString.split('-');

      if (parts.length < 2) {
        print('[TimeParser] ❌ Standard format needs HH:MM or HH-MM, got: "$timeString"');
        return (hour: null, minute: null);
      }

      final hour = int.tryParse(parts[0].trim());
      final minute = int.tryParse(parts[1].trim());

      if (hour == null || minute == null) {
        print('[TimeParser] ❌ Could not parse hour/minute from: "$timeString"');
        return (hour: null, minute: null);
      }

      // Validate ranges
      if (hour < 0 || hour >= 24 || minute < 0 || minute >= 60) {
        print('[TimeParser] ❌ Invalid 24-hour time: $hour:${minute.toString().padLeft(2, '0')}');
        return (hour: null, minute: null);
      }

      print('[TimeParser] ✅ Parsed 24-hour: "$timeString" → $hour:${minute.toString().padLeft(2, '0')}');
      return (hour: hour, minute: minute);
    } catch (e) {
      print('[TimeParser] ❌ Error parsing standard format "$timeString": $e');
      return (hour: null, minute: null);
    }
  }

  /// Create DateTime from date and time string
  /// ⚠️ All times are in Asia/Karachi timezone (UTC+5)
  static DateTime? createDateTime(dynamic timestampOrDate, String timeString) {
    try {
      DateTime? baseDate;

      // Handle Firestore Timestamp or DateTime
      if (timestampOrDate is DateTime) {
        baseDate = timestampOrDate;
      } else if (timestampOrDate != null) {
        try {
          baseDate = (timestampOrDate as dynamic).toDate() as DateTime;
        } catch (e) {
          print('[TimeParser] ⚠️ Could not convert timestamp: $e');
          return null;
        }
      }

      if (baseDate == null) return null;

      final (:hour, :minute) = parseTime(timeString);

      if (hour == null || minute == null) {
        print('[TimeParser] ❌ Failed to parse time from: "$timeString"');
        return null;
      }

      // Create DateTime - NO timezone conversion, use as-is (local time)
      // Device is already in Pakistan timezone, don't add UTC conversion
      final result = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        hour,
        minute,
      );
      
      print('[TimeParser] ✅ RESULT: timeString="$timeString" → ${result.toIso8601String()} (local time, no UTC conversion)');
      
      return result;
    } catch (e) {
      print('[TimeParser] ❌ Error creating DateTime: $e');
      return null;
    }
  }

  /// Extract appointment start hour for comparison (used in queries)
  static int? getStartHour(String? timeString) {
    final (:hour, :minute) = parseTime(timeString);
    return hour;
  }
}

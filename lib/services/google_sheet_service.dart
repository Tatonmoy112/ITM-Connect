import 'package:gsheets/gsheets.dart';
import 'package:collection/collection.dart';
import '../models/routine.dart';
import '../secrets.dart';

class GoogleSheetService {
  late GSheets _gsheets;
  late Spreadsheet _spreadsheet;

  Future<void> init() async {
    _gsheets = GSheets(credentials);
    _spreadsheet = await _gsheets.spreadsheet(spreadsheetId);
  }

  Future<List<Routine>> fetchRoutines() async {
    final sheet = _spreadsheet.worksheetByIndex(0);
    if (sheet == null) {
      throw Exception('Worksheet not found');
    }

    final rows = await sheet.values.map.allRows();
    if (rows == null) return [];

    final Map<String, Routine> routineMap = {};
    String lastDay = '';
    String lastBatch = '';

    for (final row in rows) {
      // Normalization helper for keys
      String? findKey(List<String> variants) {
        for (final variant in variants) {
          final normalizedVariant = _normalize(variant);
          final match = row.keys.firstWhereOrNull((k) => _normalize(k) == normalizedVariant);
          if (match != null) return match;
        }
        return null;
      }

      String getValue(List<String> variants) {
        final key = findKey(variants);
        if (key != null && row[key] != null) {
          return row[key].toString().trim();
        }
        return '';
      }

      String day = getValue(['Day', 'Date', 'DAY']);
      String rawBatch = getValue(['Batch', 'BATCH', 'Batch Number']);
      
      // Carry over previous values if current ones are empty
      if (day.isEmpty) {
        day = lastDay;
      } else {
        lastDay = day;
      }
      
      if (rawBatch.isEmpty) {
        rawBatch = lastBatch;
      } else {
        lastBatch = rawBatch;
      }

      final batch = rawBatch.toUpperCase(); // Force uppercase for consistent document IDs
      
      final teacherName = getValue(['Teacher Name', 'Teacher', 'TEACHER', 'NAME', 'faculty']);
      String teacherInitial = getValue(['Teacher Initial', 'Initial', 'ID', 'Initial ', 'TeacherInitial', 'Initials']).toUpperCase();
      
      // Fallback for missing initials: try to generate from teacher name
      if (teacherInitial.isEmpty && teacherName.isNotEmpty) {
         teacherInitial = _getInitials(teacherName);
      }

      final courseName = getValue(['Course Name', 'Course', 'COURSE', 'Subject', 'CourseTitle']);
      final courseCode = getValue(['Course Code', 'Code', 'CourseID', 'Subject Code']);
      final room = getValue(['Room', 'ROOM', 'Room No', 'RoomNo']);
      
      // Time handling - try variants
      String startTime = getValue(['Time', 'StartTime', 'Start Time', 'Starts', 'From']);
      String endTime = getValue(['EndTime', 'End Time', 'Ends', 'To']);

      // Still need both after carry-over attempt
      if (batch.isEmpty || day.isEmpty) continue;

      // Handle case where Time column might contain a range "8:30 - 10:00"
      String finalTime = startTime;
      if (finalTime.contains('-')) {
        // Already a range, leave it
      } else if (endTime.isNotEmpty) {
        finalTime = '$startTime - $endTime';
      }

      final routineClass = RoutineClass(
        courseName: courseName,
        courseCode: courseCode,
        teacherName: teacherName,
        teacherInitial: teacherInitial,
        room: room,
        time: finalTime,
      );

      final routineId = '${batch}_${_shortDay(day)}';
      
      if (routineMap.containsKey(routineId)) {
        routineMap[routineId]!.classes.add(routineClass);
      } else {
        routineMap[routineId] = Routine(
          id: routineId,
          batch: batch,
          day: day,
          teacherInitial: teacherInitial,
          classes: [routineClass],
        );
      }
    }

    return routineMap.values.toList();
  }

  String _normalize(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '';
    final nameParts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (nameParts.isEmpty) return '';
    String initials = '';
    for (final part in nameParts) {
      if (part.isNotEmpty) {
        initials += part[0];
      }
    }
    return initials.toUpperCase();
  }

  // Helper to match the ManageRoutineScreen logic for document IDs
  String _shortDay(String day) {
    switch (day.trim().toLowerCase()) {
      case 'saturday': return 'Sat';
      case 'sunday': return 'Sun';
      case 'monday': return 'Mon';
      case 'tuesday': return 'Tue';
      case 'wednesday': return 'Wed';
      case 'thursday': return 'Thu';
      case 'friday': return 'Fri';
      default:
        if (day.length >= 3) {
          return day.substring(0, 1).toUpperCase() + day.substring(1, 3).toLowerCase();
        }
        return day;
    }
  }
}

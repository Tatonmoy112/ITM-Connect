import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itm_connect/models/routine.dart';
import 'package:itm_connect/services/google_sheet_service.dart';
import 'package:intl/intl.dart';

class RoutineService {
  static const List<String> classSlots = [
    "08:30 AM - 10:00 AM",
    "10:00 AM - 11:30 AM",
    "11:30 AM - 01:00 PM",
    "01:00 PM - 02:30 PM",
    "02:30 PM - 04:00 PM",
    "04:00 PM - 05:30 PM",
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'routines';

  // Create or overwrite routine document
  Future<void> setRoutine(Routine routine) async {
    try {
      await _firestore.collection(_collection).doc(routine.id).set(
            routine.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      rethrow;
    }
  }

  // Get a single routine document
  Future<Routine?> getRoutine(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return Routine.fromMap(doc.id, doc.data());
    } catch (e) {
      rethrow;
    }
  }

  // Stream a single routine doc (real-time)
  Stream<Routine?> streamRoutine(String id) {
    return _firestore.collection(_collection).doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Routine.fromMap(doc.id, doc.data());
    });
  }

  // Stream unique batch values that exist in the routines collection
  Stream<List<String>> streamAllBatches() {
    return _firestore.collection(_collection).snapshots().map((snap) {
      final batches = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        String? b = (data['batch'] as String?)?.trim();

        // Fallback: extract from document ID if the field is missing/empty
        if ((b == null || b.isEmpty) && doc.id.contains('_')) {
          b = doc.id.split('_')[0].trim();
        }

        if (b != null && b.isNotEmpty) {
          batches
              .add(b.toUpperCase()); // Normalize to uppercase for consistency
        }
      }
      final list = batches.toList()..sort();
      return list;
    });
  }

  // Create an empty routine document for a given id, with batch and day set
  Future<void> createEmptyRoutine(String id, String batch, String day) async {
    final docRef = _firestore.collection(_collection).doc(id);
    await docRef.set({
      'batch': batch,
      'day': day,
      'classes': [],
    });
  }

  // Delete all routine documents that belong to a batch
  Future<void> deleteBatch(String batch) async {
    final query = await _firestore
        .collection(_collection)
        .where('batch', isEqualTo: batch)
        .get();
    final batchWrite = _firestore.batch();
    for (final doc in query.docs) {
      batchWrite.delete(doc.reference);
    }
    await batchWrite.commit();
  }

  // Delete routine document
  Future<void> deleteRoutine(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Add a class to the routine (append)
  Future<void> addClass(String routineId, RoutineClass newClass) async {
    final docRef = _firestore.collection(_collection).doc(routineId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      List existing = [];
      Map<String, dynamic> base = {};
      if (snapshot.exists) {
        base = snapshot.data() as Map<String, dynamic>;
        existing = (base['classes'] as List<dynamic>?) ?? [];
      }
      existing.add(newClass.toMap());

      // Ensure batch and day are set if this is a new document or missing fields
      final updated = {
        ...base,
        'classes': existing,
      };

      // Extract batch and day from ID if not present
      if (!base.containsKey('batch') || (base['batch'] as String).isEmpty) {
        if (routineId.contains('_')) {
          final parts = routineId.split('_');
          updated['batch'] = parts[0];
          updated['day'] = parts.sublist(1).join('_');
        }
      }

      tx.set(docRef, updated, SetOptions(merge: true));
    });
  }

  // Update a class by index
  Future<void> updateClass(
      String routineId, int index, RoutineClass updatedClass) async {
    final docRef = _firestore.collection(_collection).doc(routineId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) throw Exception('Routine does not exist');
      final base = snapshot.data() as Map<String, dynamic>;
      final existing = List<Map<String, dynamic>>.from(
          (base['classes'] as List<dynamic>?) ?? []);
      if (index < 0 || index >= existing.length)
        throw Exception('Invalid index');
      existing[index] = updatedClass.toMap();
      final updated = {...base, 'classes': existing};
      tx.set(docRef, updated, SetOptions(merge: true));
    });
  }

  // Delete class by index
  Future<void> deleteClass(String routineId, int index) async {
    final docRef = _firestore.collection(_collection).doc(routineId);
    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) return;
      final base = snapshot.data() as Map<String, dynamic>;
      final existing = List<Map<String, dynamic>>.from(
          (base['classes'] as List<dynamic>?) ?? []);
      if (index < 0 || index >= existing.length) return;
      existing.removeAt(index);
      final updated = {...base, 'classes': existing};
      tx.set(docRef, updated, SetOptions(merge: true));
    });
  }

  // Stream all routines (real-time)
  Stream<List<Routine>> streamAllRoutines() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Routine.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // Sync routines from Google Sheets to Firestore
  Future<void> syncFromGoogleSheet() async {
    final gsService = GoogleSheetService();
    await gsService.init();
    final routines = await gsService.fetchRoutines();
    await bulkUploadRoutines(routines);
  }

  // Bulk upload routines using Firestore batches
  Future<void> bulkUploadRoutines(List<Routine> routines) async {
    final batch = _firestore.batch();

    for (final routine in routines) {
      if (routine.id.isEmpty) continue;
      final docRef = _firestore.collection(_collection).doc(routine.id);
      batch.set(docRef, routine.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  // --- Conflict Detection Logic ---

  /// Parse time string like "10:00 AM" and return minutes since midnight
  int? _parseTime(String timeStr) {
    try {
      final dateFormat = DateFormat('hh:mm a');
      final time = dateFormat.parse(timeStr.trim());
      return time.hour * 60 + time.minute;
    } catch (e) {
      return null;
    }
  }

  /// Parse time range like "10:00 AM - 11:30 AM" and return [startMinutes, endMinutes]
  List<int>? _parseTimeRange(String timeStr) {
    try {
      final parts = timeStr.split('-');
      if (parts.length != 2) return null;
      final start = _parseTime(parts[0]);
      final end = _parseTime(parts[1]);
      if (start == null || end == null) return null;
      return [start, end];
    } catch (e) {
      return null;
    }
  }

  /// Check if two time ranges overlap
  bool _timesOverlap(List<int> range1, List<int> range2) {
    return range1[0] < range2[1] && range2[0] < range1[1];
  }

  String _getFullDayName(String shortDay) {
    final Map<String, String> dayMap = {
      'Sat': 'Saturday',
      'Sun': 'Sunday',
      'Mon': 'Monday',
      'Tue': 'Tuesday',
      'Wed': 'Wednesday',
      'Thu': 'Thursday',
      'Fri': 'Friday',
    };
    return dayMap[shortDay] ?? shortDay;
  }

  /// Comprehensive check for teacher availability
  /// Checks against all academic routines and the teacher's consulting hours
  Future<String?> checkTeacherAvailability({
    required String teacherInitial,
    required String day,
    required String timeRange,
    String? excludeDocId,
    bool skipConsultingCheck = false,
  }) async {
    final newRange = _parseTimeRange(timeRange);
    if (newRange == null) return "Invalid time format";

    // Normalize day to short form (e.g. "Saturday" -> "Sat")
    final shortDay = day.length >= 3
        ? (day.substring(0, 1).toUpperCase() +
            day.substring(1, 3).toLowerCase())
        : day;

    // 1. Check all academic routines on the same day
    // Query for both short ("Sat") and long ("Saturday") formats to be safe
    final shortDayQuery = await _firestore
        .collection(_collection)
        .where('day', isEqualTo: shortDay)
        .get();
    final longDay = _getFullDayName(shortDay);
    final longDayQuery = await _firestore
        .collection(_collection)
        .where('day', isEqualTo: longDay)
        .get();

    // Combine results and deduplicate by doc ID
    final allDocs = {...shortDayQuery.docs, ...longDayQuery.docs}.toList();

    for (final doc in allDocs) {
      if (excludeDocId != null && doc.id == excludeDocId) continue;

      final routine = Routine.fromMap(doc.id, doc.data());
      for (final routineClass in routine.classes) {
        if (routineClass.teacherInitial.trim().toUpperCase() ==
            teacherInitial.trim().toUpperCase()) {
          final existingRange = _parseTimeRange(routineClass.time);
          if (existingRange != null && _timesOverlap(newRange, existingRange)) {
            return "Conflict: Teacher already has a class on $day at ${routineClass.time} (Batch: ${routine.batch})";
          }
        }
      }
    }

    // 2. Check teacher's consulting hours
    if (!skipConsultingCheck) {
      final teacherDoc =
          await _firestore.collection('teachers').doc(teacherInitial).get();
      if (teacherDoc.exists) {
        final data = teacherDoc.data()!;
        final rawConsulting = data['consultingHours'] ?? data['consultingHour'];
        List<String> consultingSlots = [];
        if (rawConsulting is List) {
          consultingSlots = List<String>.from(rawConsulting);
        } else if (rawConsulting is String && rawConsulting.isNotEmpty) {
          consultingSlots = [rawConsulting];
        }

        for (final slot in consultingSlots) {
          // Slot format expected: "Day TimeRange" e.g., "Sat 10:00 AM - 11:30 AM"
          if (slot.contains(day)) {
            final timePart = slot.replaceFirst(day, '').trim();
            final existingRange = _parseTimeRange(timePart);
            if (existingRange != null &&
                _timesOverlap(newRange, existingRange)) {
              return "Conflict: This time overlaps with the teacher's Consulting Hour on $day ($timePart)";
            }
          }
        }
      }
    }

    return null; // Available
  }
}

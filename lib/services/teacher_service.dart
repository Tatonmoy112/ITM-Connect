import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itm_connect/models/teacher.dart';

class TeacherService {
    // Stream all teachers from Firestore
    Stream<List<Teacher>> streamAllTeachers() {
        return teachersCollection.snapshots().map((snapshot) {
          return snapshot.docs.map<Teacher>((doc) {
            final data = doc.data() as Map<String, dynamic>;
            
            String teacherInitial = (data['teacherInitial'] ?? doc.id).toString().trim();
            
            List<String> consultingHours = [];
            final rawSchedule = data['consultingSchedule'];
            final rawConsulting = data['consultingHours'];
            
            // Robust parsing for Web compatibility (handle JsArray/LegacyJavaScriptObject)
            if (rawSchedule != null && rawSchedule is List && rawSchedule.isNotEmpty) {
               try {
                 final list = List.from(rawSchedule);
                 consultingHours = list.map((e) {
                   if (e != null && e is Map) {
                     final map = Map<String, dynamic>.from(e as Map);
                     return map['fullString']?.toString() ?? "${map['day']} ${map['time']}";
                   }
                   return "";
                 }).where((e) => e.isNotEmpty).toList();
               } catch (e) {
                 print("Error parsing consultingSchedule: $e");
                 consultingHours = []; // Fallback will trigger
               }
            }
            
            // Fallback checks
            if (consultingHours.isEmpty) {
              if (rawConsulting is List) {
                consultingHours = rawConsulting.map((e) => e.toString()).toList();
              } else {
                 final legacySingle = data['consultingHour'];
                 if (legacySingle is String && legacySingle.isNotEmpty) {
                   consultingHours = [legacySingle];
                 }
              }
            }
            
            return Teacher(
              id: doc.id,
              name: data['name'] ?? '',
              email: data['email'] ?? '',
              role: data['role'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
              teacherInitial: teacherInitial,
              consultingHours: consultingHours,
            );
          }).toList();
        });
    }

    // Delete a teacher by initial
    Future<void> deleteTeacher(String teacherInitial) async {
      await teachersCollection.doc(teacherInitial).delete();
    }

    // Get a single teacher by ID/Initial
    Future<Teacher?> getTeacher(String teacherInitial) async {
      try {
        final doc = await teachersCollection.doc(teacherInitial).get();
        if (!doc.exists) return null;
        
        final data = doc.data() as Map<String, dynamic>;
        
        // Handle consultingHours
        List<String> consultingHours = [];
        final rawSchedule = data['consultingSchedule'];
        final rawConsulting = data['consultingHours'];
        
        // Robust parsing for Web compatibility
        if (rawSchedule != null && rawSchedule is List && rawSchedule.isNotEmpty) {
           try {
             final list = List.from(rawSchedule);
             consultingHours = list.map((e) {
               if (e != null && e is Map) {
                 final map = Map<String, dynamic>.from(e as Map);
                 return map['fullString']?.toString() ?? "${map['day']} ${map['time']}";
               }
               return "";
             }).where((e) => e.isNotEmpty).toList();
           } catch (e) {
             print("Error parsing consultingSchedule: $e");
             consultingHours = [];
           }
        }
        
        // Fallback checks
        if (consultingHours.isEmpty) {
          if (rawConsulting is List) {
            consultingHours = rawConsulting.map((e) => e.toString()).toList();
          } else {
             final legacySingle = data['consultingHour'];
             if (legacySingle is String && legacySingle.isNotEmpty) {
               consultingHours = [legacySingle];
             }
          }
        }

        return Teacher(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          teacherInitial: (data['teacherInitial'] ?? doc.id).toString().trim(),
          consultingHours: consultingHours,
        );
      } catch (e) {
        print("Error getting teacher: $e");
        return null;
      }
    }

    // Get all teachers (Future version)
    Future<List<Teacher>> getAllTeachers() async {
      final snapshot = await teachersCollection.get();
      return snapshot.docs.map<Teacher>((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Get teacherInitial: prefer Firestore field, fallback to doc.id
        String teacherInitial = (data['teacherInitial'] ?? doc.id ?? '').toString().trim();
        
        
        // Handle consultingHours
        List<String> consultingHours = [];
        final rawSchedule = data['consultingSchedule'];
        final rawConsulting = data['consultingHours'];
        
        // Robust parsing for Web compatibility (handle JsArray/LegacyJavaScriptObject)
        if (rawSchedule != null && rawSchedule is List && rawSchedule.isNotEmpty) {
           try {
             final list = List.from(rawSchedule);
             consultingHours = list.map((e) {
               if (e != null && e is Map) {
                 final map = Map<String, dynamic>.from(e as Map);
                 return map['fullString']?.toString() ?? "${map['day']} ${map['time']}";
               }
               return "";
             }).where((e) => e.isNotEmpty).toList();
           } catch (e) {
             print("Error parsing consultingSchedule: $e");
             consultingHours = []; // Fallback will trigger
           }
        }
        
        // Fallback checks
        if (consultingHours.isEmpty) {
          if (rawConsulting is List) {
            consultingHours = rawConsulting.map((e) => e.toString()).toList();
          } else {
             final legacySingle = data['consultingHour'];
             if (legacySingle is String && legacySingle.isNotEmpty) {
               consultingHours = [legacySingle];
             }
          }
        }
        
        return Teacher(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          teacherInitial: teacherInitial,
          consultingHours: consultingHours,
        );
      }).toList();
    }
  final CollectionReference teachersCollection =
      FirebaseFirestore.instance.collection('teachers');

  Future<void> addOrUpdateTeacher({
    required String teacherInitial,
    required String name,
    required String email,
    required String role,
    required String imageUrl,
    required List<String> consultingHours,
  }) async {
    // Debug print to verify data before saving
    print('Saving teacher $teacherInitial with ${consultingHours.length} slots: $consultingHours');
    
    // Create structured data for better querying/integrity
    List<Map<String, String>> structuredSchedule = [];
    for (var slot in consultingHours) {
      // Expected format: "Day TimeRange" e.g., "Sat 08:30 AM - 10:00 AM"
      final parts = slot.trim().split(' ');
      if (parts.length > 2) {
        final day = parts[0];
        final time = slot.substring(day.length).trim();
        structuredSchedule.add({
          'day': day,
          'time': time,
          'fullString': slot,
        });
      }
    }

    await teachersCollection.doc(teacherInitial).set({
      'teacherInitial': teacherInitial,
      'name': name,
      'email': email,
      'role': role,
      'imageUrl': imageUrl,
      'consultingHours': consultingHours, // List<String>
      'consultingSchedule': structuredSchedule, // Structured List<Map>
      'consultingHour': consultingHours.isNotEmpty ? consultingHours.join(', ') : '', // Keep for compatibility
    }, SetOptions(merge: true));
  }
}

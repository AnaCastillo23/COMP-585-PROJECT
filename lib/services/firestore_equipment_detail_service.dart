// lib/services/firestore_equipment_detail_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/loan.dart';
import 'equipment_detail_service.dart';

class FirestoreEquipmentDetailService implements EquipmentDetailService {
  FirestoreEquipmentDetailService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ── Loans (from LoanService's `loans` collection) ──

  @override
  Future<Map<String, LoanInfo>> activeLoansByUnit(String equipmentId) async {
    final snap = await _db
        .collection('loans')
        .where('equipmentId', isEqualTo: equipmentId)
        .where('returnedAt', isNull: true)
        .get();

    final loans = <String, LoanInfo>{};
    for (final doc in snap.docs) {
      final loan = Loan.fromDoc(doc);
      loans[loan.unitId] = LoanInfo(
        studentName: loan.studentName,
        dueDate: loan.dueAt,
      );
    }
    return loans;
  }

  // ── Waitlist: one doc per (equipment, student) in `waitlist` ──

  String _waitDocId(String equipmentId, String studentRefId) =>
      '${equipmentId}_$studentRefId';

  @override
  Future<List<StudentRef>> getWaitlist(String equipmentId) async {
    final snap = await _db
        .collection('waitlist')
        .where('equipmentId', isEqualTo: equipmentId)
        .get();

    // Sorted here so no composite index is needed.
    final entries = snap.docs.map((doc) {
      final d = doc.data();
      final created =
          (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return (
        created,
        StudentRef(
          id: d['studentRefId'] as String,
          name: d['name'] as String,
          email: (d['email'] ?? '') as String,
        ),
      );
    }).toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));

    return [for (final e in entries) e.$2];
  }

  @override
  Future<void> addToWaitlist(
    String equipmentId,
    StudentRef student, {
    String equipmentName = '',
  }) {
    return _db
        .collection('waitlist')
        .doc(_waitDocId(equipmentId, student.id))
        .set({
      'equipmentId': equipmentId,
      'studentRefId': student.id,
      'equipmentName': equipmentName,
      'name': student.name,
      'email': student.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeFromWaitlist(String equipmentId, String studentId) {
    return _db
        .collection('waitlist')
        .doc(_waitDocId(equipmentId, studentId))
        .delete();
  }

  // ── Students (from the `users` collection) ──

  @override
  Future<List<StudentRef>> searchStudents(String query) async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .limit(300)
        .get();

    final q = query.trim().toLowerCase();
    final students = <StudentRef>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      final name =
          (d['name'] ?? d['displayName'] ?? d['email'] ?? 'Student') as String;
      final email = (d['email'] ?? '') as String;
      final csunId = (d['studentId'] ?? '') as String;

      final matches = q.isEmpty ||
          name.toLowerCase().contains(q) ||
          email.toLowerCase().contains(q) ||
          csunId.contains(q);
      if (matches) {
        students.add(
          StudentRef(
            id: doc.id,
            name: name,
            email: email.isNotEmpty ? email : csunId,
          ),
        );
      }
    }
    students.sort((a, b) => a.name.compareTo(b.name));
    return students;
  }

  // ── Care guide: `equipmentGuides/{equipmentId}` ──

  @override
  Future<EquipmentGuide> getGuide(String equipmentId) async {
    final doc = await _db.collection('equipmentGuides').doc(equipmentId).get();
    final d = doc.data();
    if (d == null) return const EquipmentGuide();
    return EquipmentGuide(
      careInstructions: (d['careInstructions'] ?? '') as String,
      gettingToKnow: (d['gettingToKnow'] ?? '') as String,
    );
  }

  @override
  Future<void> saveGuide(String equipmentId, EquipmentGuide guide) {
    return _db.collection('equipmentGuides').doc(equipmentId).set({
      'careInstructions': guide.careInstructions,
      'gettingToKnow': guide.gettingToKnow,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
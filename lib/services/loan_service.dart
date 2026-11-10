import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/equipment.dart';
import '../models/loan.dart';
import 'activity_service.dart';

/// Minimal student info needed to start a checkout.
class StudentInfo {
  const StudentInfo({
    required this.uid,
    required this.studentId,
    required this.name,
  });

  final String uid;
  final String studentId;
  final String name;
}

class LoanService {
  LoanService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Staff: find a student by their 9-digit CSUN ID.
  Future<StudentInfo?> findStudent(String csunId) async {
    final id = csunId.trim();
    final snap = await _db
        .collection('users')
        .where('studentId', isEqualTo: id)
        .where('role', isEqualTo: 'student')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    final d = doc.data();
    return StudentInfo(
      uid: doc.id,
      studentId: id,
      name: (d['name'] ?? d['displayName'] ?? d['email'] ?? 'Student')
          as String,
    );
  }

  Stream<List<Loan>> watchActiveLoans() => _db
      .collection('loans')
      .where('returnedAt', isNull: true)
      .snapshots()
      .map((s) => s.docs.map(Loan.fromDoc).toList());

  /// Needs a composite index (studentUid + checkedOutAt). Firestore logs a
  /// link to create it the first time this runs.
  Stream<List<Loan>> watchStudentLoans(String studentUid) => _db
      .collection('loans')
      .where('studentUid', isEqualTo: studentUid)
      .orderBy('checkedOutAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Loan.fromDoc).toList());

  /// Creates the loan and marks the unit unavailable in one transaction, so
  /// two staff members can't check out the same unit.
  Future<void> checkOut({
    required StudentInfo student,
    required Equipment item,
    required EquipmentUnit unit,
    required DateTime dueAt,
  }) {
    final unitRef = _db.collection('equipmentUnits').doc(unit.id);
    final loanRef = _db.collection('loans').doc();
    final reservationRef = _db.collection('reservations').doc(unit.id);

    return _db.runTransaction((tx) async {
      final snap = await tx.get(unitRef);
      if (snap.data()?['status'] != 'available') {
        throw StateError('${unit.id} is no longer available.');
      }

      // A live hold for someone else blocks the checkout; the student's own
      // hold is consumed by this pickup.
      final hold = await tx.get(reservationRef);
      if (hold.exists) {
        final d = hold.data()!;
        final created = (d['createdAt'] as Timestamp?)?.toDate();
        final live = created != null &&
            DateTime.now().isBefore(created.add(const Duration(hours: 24)));
        if (live && d['studentUid'] != student.uid) {
          throw StateError('${unit.id} is reserved for another student.');
        }
        tx.delete(reservationRef);
      }

      tx.update(unitRef, {'status': 'unavailable'});
      tx.set(loanRef, {
        'studentUid': student.uid,
        'studentId': student.studentId,
        'studentName': student.name,
        'equipmentId': item.id,
        'equipmentName': item.name,
        'unitId': unit.id,
        'checkedOutAt': FieldValue.serverTimestamp(),
        'dueAt': Timestamp.fromDate(dueAt),
        'returnedAt': null,
      });
      tx.set(
        _db.collection('activity').doc(),
        ActivityService.record(
          type: 'Checkout',
          title: '${item.name} ${unit.id} checked out',
          detail: '${ActivityService.maskedStudent(student.studentId)}'
              ' • due ${ActivityService.shortDate(dueAt)}',
          status: 'Checked out',
          unitId: unit.id,
        ),
      );
    });
  }

  /// Closes the loan and sets the unit's new status. Defaults to available;
  /// pass [EquipmentStatus.maintenance] when it comes back damaged.
  Future<void> returnUnit(
    Loan loan, {
    EquipmentStatus unitStatusAfter = EquipmentStatus.available,
  }) {
    final unitRef = _db.collection('equipmentUnits').doc(loan.unitId);
    final loanRef = _db.collection('loans').doc(loan.id);

    return _db.runTransaction((tx) async {
      tx.update(loanRef, {'returnedAt': FieldValue.serverTimestamp()});
      tx.update(unitRef, {'status': unitStatusAfter.name});

      final damaged = unitStatusAfter == EquipmentStatus.maintenance;
      final activity = _db.collection('activity');
 
      // The return is always logged as completed...
      tx.set(
        activity.doc('${loan.id}_1return'),
        ActivityService.record(
          type: 'Return',
          title: '${loan.equipmentName} ${loan.unitId} returned',
          detail: ActivityService.maskedStudent(loan.studentId),
          status: 'Completed',
          unitId: loan.unitId,
        ),
      );
 
      // ...and a damaged return adds its own Maintenance entry. Both get the
      // same server timestamp, so the doc IDs (_1 / _2) break the tie and
      // put the maintenance entry on top, since it happens after the return.
      if (damaged) {
        tx.set(
          activity.doc('${loan.id}_2maintenance'),
          ActivityService.record(
            type: 'Maintenance',
            title: '${loan.equipmentName} ${loan.unitId} sent to maintenance',
            detail: 'Reported damaged on return • '
                '${ActivityService.maskedStudent(loan.studentId)}',
            status: 'Damaged',
            unitId: loan.unitId,
        ),
      );
     }
    });
  }
}
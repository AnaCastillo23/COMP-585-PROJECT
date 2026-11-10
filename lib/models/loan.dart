import 'package:cloud_firestore/cloud_firestore.dart';

import 'rental.dart';

/// One checkout of one equipment unit by one student.
/// A loan is "active" until [returnedAt] is stamped.
class Loan {
  const Loan({
    required this.id,
    required this.studentUid,
    required this.studentId,
    required this.studentName,
    required this.equipmentId,
    required this.equipmentName,
    required this.unitId,
    required this.checkedOutAt,
    required this.dueAt,
    this.returnedAt,
  });

  final String id;
  final String studentUid; // Firebase Auth uid (used by security rules)
  final String studentId; // 9-digit CSUN ID (shown to staff)
  final String studentName;
  final String equipmentId;
  final String equipmentName;
  final String unitId; // e.g. EQ-0004
  final DateTime checkedOutAt;
  final DateTime dueAt;
  final DateTime? returnedAt;

  bool get isActive => returnedAt == null;
  bool get isOverdue => isActive && DateTime.now().isAfter(dueAt);

  factory Loan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Loan(
      id: doc.id,
      studentUid: d['studentUid'] as String,
      studentId: d['studentId'] as String,
      studentName: d['studentName'] as String,
      equipmentId: d['equipmentId'] as String,
      equipmentName: d['equipmentName'] as String,
      unitId: d['unitId'] as String,
      // serverTimestamp is briefly null on the local snapshot after a write.
      checkedOutAt:
          (d['checkedOutAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueAt: (d['dueAt'] as Timestamp).toDate(),
      returnedAt: (d['returnedAt'] as Timestamp?)?.toDate(),
    );
  }
}
// Extensions must be top-level, outside the class.
extension LoanToRental on Loan {
  Rental toRental() => Rental(
        id: id,
        equipmentName: equipmentName,
        assetTag: unitId,
        status: RentalStatus.checkedOut,
        dueDate: dueAt,
      );
}
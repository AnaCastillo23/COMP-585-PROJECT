import 'package:cloud_firestore/cloud_firestore.dart';

/// One line in the staff dashboard's Recent activity table.
/// type:   'Checkout' | 'Return' | 'Reservation' | 'Maintenance'
/// status: 'Checked out' | 'Completed' | 'Pickup pending' | 'Needs attention'
class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.status,
    required this.at,
  });

  final String id;
  final String type;
  final String title;
  final String detail;
  final String status;
  final DateTime at;

  factory ActivityEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ActivityEntry(
      id: doc.id,
      type: d['type'] as String,
      title: d['title'] as String,
      detail: (d['detail'] as String?) ?? '',
      status: d['status'] as String,
      // serverTimestamp is briefly null on the local snapshot after a write.
      at: (d['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
class WaitlistEntry {
  const WaitlistEntry({
    required this.id,
    required this.studentUid,
    required this.equipmentId,
    required this.equipmentName,
    required this.joinedAt,
    required this.position,
  });

  final String id;
  final String studentUid;
  final String equipmentId;
  final String equipmentName;
  final DateTime joinedAt;
  final int position;
}

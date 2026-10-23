enum ReservationStatus { pendingPickup, fulfilled, expired, cancelled }

class Reservation {
  const Reservation({
    required this.id,
    required this.studentUid,
    required this.equipmentId,
    required this.equipmentName,
    required this.reservedAt,
    required this.pickupDeadline,
    required this.status,
  });

  factory Reservation.create({
    required String id,
    required String studentUid,
    required String equipmentId,
    required String equipmentName,
    DateTime? reservedAt,
  }) {
    final createdAt = reservedAt ?? DateTime.now();

    return Reservation(
      id: id,
      studentUid: studentUid,
      equipmentId: equipmentId,
      equipmentName: equipmentName,
      reservedAt: createdAt,
      pickupDeadline: createdAt.add(const Duration(days: 1)),
      status: ReservationStatus.pendingPickup,
    );
  }

  final String id;
  final String studentUid;
  final String equipmentId;
  final String equipmentName;
  final DateTime reservedAt;
  final DateTime pickupDeadline;
  final ReservationStatus status;

  bool isExpiredAt(DateTime currentTime) {
    return status == ReservationStatus.pendingPickup &&
        !currentTime.isBefore(pickupDeadline);
  }

  Duration pickupTimeRemainingAt(DateTime currentTime) {
    if (status != ReservationStatus.pendingPickup ||
        !currentTime.isBefore(pickupDeadline)) {
      return Duration.zero;
    }

    return pickupDeadline.difference(currentTime);
  }
}

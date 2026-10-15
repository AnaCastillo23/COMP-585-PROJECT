enum RentalStatus { checkedOut, reserved }

class Rental {
  const Rental({
    required this.id,
    required this.equipmentName,
    required this.assetTag,
    required this.status,
    this.dueDate,
    this.pickupDeadline,
  });

  final String id;
  final String equipmentName;
  final String assetTag;
  final RentalStatus status;
  final DateTime? dueDate;
  final DateTime? pickupDeadline;

  int? get daysRemaining {
    if (dueDate == null) return null;
    final hours = dueDate!.difference(DateTime.now()).inHours;
    return (hours / 24).ceil();
  }
}

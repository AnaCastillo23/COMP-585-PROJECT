// lib/services/equipment_detail_service.dart
//
// Data needed by the equipment detail page. The in-memory version lets the UI
// run in tests; the real app uses FirestoreEquipmentDetailService.

class LoanInfo {
  const LoanInfo({required this.studentName, required this.dueDate});

  final String studentName;
  final DateTime dueDate;
}

class StudentRef {
  const StudentRef({
    required this.id,
    required this.name,
    required this.email,
  });

  final String id;
  final String name;
  final String email;
}

/// Staff-written content, shown to students when they check out the item.
class EquipmentGuide {
  const EquipmentGuide({
    this.careInstructions = '',
    this.gettingToKnow = '',
  });

  final String careInstructions;
  final String gettingToKnow;
}

abstract class EquipmentDetailService {
  /// Active loans for every unit of one item, keyed by unit ID.
  Future<Map<String, LoanInfo>> activeLoansByUnit(String equipmentId);

  Future<List<StudentRef>> getWaitlist(String equipmentId);
  Future<void> addToWaitlist(
    String equipmentId,
    StudentRef student, {
    String equipmentName = '',
  });
  Future<void> removeFromWaitlist(String equipmentId, String studentId);

  Future<List<StudentRef>> searchStudents(String query);

  Future<EquipmentGuide> getGuide(String equipmentId);
  Future<void> saveGuide(String equipmentId, EquipmentGuide guide);
}

class InMemoryEquipmentDetailService implements EquipmentDetailService {
  static final shared = InMemoryEquipmentDetailService();

  final _students = <StudentRef>[
    const StudentRef(id: 's1', name: 'Maria Lopez', email: 'maria.lopez@my.csun.edu'),
    const StudentRef(id: 's2', name: 'James Carter', email: 'james.carter@my.csun.edu'),
    const StudentRef(id: 's3', name: 'Aisha Khan', email: 'aisha.khan@my.csun.edu'),
  ];
  final _waitlists = <String, List<StudentRef>>{};
  final _guides = <String, EquipmentGuide>{};

  @override
  Future<Map<String, LoanInfo>> activeLoansByUnit(String equipmentId) async =>
      {};

  @override
  Future<List<StudentRef>> getWaitlist(String equipmentId) async =>
      List.of(_waitlists[equipmentId] ?? const []);

  @override
  Future<void> addToWaitlist(
    String equipmentId,
    StudentRef student, {
    String equipmentName = '',
  }) async {
    final list = _waitlists.putIfAbsent(equipmentId, () => []);
    if (list.any((s) => s.id == student.id)) return;
    list.add(student);
  }

  @override
  Future<void> removeFromWaitlist(String equipmentId, String studentId) async {
    _waitlists[equipmentId]?.removeWhere((s) => s.id == studentId);
  }

  @override
  Future<List<StudentRef>> searchStudents(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.of(_students);
    return _students
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<EquipmentGuide> getGuide(String equipmentId) async =>
      _guides[equipmentId] ?? const EquipmentGuide();

  @override
  Future<void> saveGuide(String equipmentId, EquipmentGuide guide) async {
    _guides[equipmentId] = guide;
  }
}
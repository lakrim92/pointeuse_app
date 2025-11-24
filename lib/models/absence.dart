// lib/models/absence.dart
class Absence {
  final int? id;
  final int employeeId;
  final String type; // ex: "congé", "maladie", "enfant malade"
  final String startDate;
  final String endDate;
  final String? comment;

  Absence({
    this.id,
    required this.employeeId,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.comment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'type': type,
      'start_date': startDate,
      'end_date': endDate,
      'comment': comment,
    };
  }

  factory Absence.fromMap(Map<String, dynamic> map) {
    return Absence(
      id: map['id'],
      employeeId: map['employee_id'],
      type: map['type'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      comment: map['comment'],
    );
  }
}

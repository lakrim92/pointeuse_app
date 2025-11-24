class Attendance {
  final int? id;
  final int employeeId;
  final String date;
  final String? arrival;
  final String? departure;

  Attendance({
    this.id,
    required this.employeeId,
    required this.date,
    this.arrival,
    this.departure,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'date': date,
      'arrival': arrival,
      'departure': departure,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      date: map['date'] as String,
      arrival: map['arrival'] as String?,
      departure: map['departure'] as String?,
    );
  }
}

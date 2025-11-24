import 'package:flutter/material.dart';

class Employee {
  final int? id;
  final String nom;
  final String prenom;

  Employee({this.id, required this.nom, required this.prenom});

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
        id: map['id'],
        nom: map['nom'],
        prenom: map['prenom'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'prenom': prenom,
      };
}

class EmployeeProvider extends ChangeNotifier {
  List<Employee> _employees = [];

  List<Employee> get employees => _employees;

  Future<void> load() async {
    // Appel vers DB plus tard
    notifyListeners();
  }
}

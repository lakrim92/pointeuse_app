// lib/screens/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../models/employee.dart';
import '../models/attendance.dart';
import '../widgets/custom_appbar.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Employee> _employees = [];
  String _selectedDate =
      DateFormat('dd-MM-yyyy', 'fr_FR').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await DBService.getAllEmployees();
    setState(() => _employees = e);
  }

  Future<void> _pointArrival(Employee emp) async {
    final now = DateFormat('HH:mm', 'fr_FR').format(DateTime.now());
    int result =
        await DBService.insertOrUpdateArrival(emp.id!, _selectedDate, now);

    if (result == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'arrivée a déjà été pointée.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bonjour ${emp.prenom}, arrivée pointée à $now.")),
      );
      setState(() {});
    }
  }

  Future<void> _pointDeparture(Employee emp) async {
    final now = DateFormat('HH:mm', 'fr_FR').format(DateTime.now());
    final att = await DBService.getAttendanceFor(emp.id!, _selectedDate);

    if (att == null || att.arrival == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Impossible de pointer le départ avant l'arrivée.")),
      );
      return;
    }

    int result =
        await DBService.insertOrUpdateDeparture(emp.id!, _selectedDate, now);

    if (result == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Le départ a déjà été pointé.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Au revoir ${emp.prenom}, départ pointé à $now.")),
      );
      setState(() {});
    }
  }

  Future<bool> _isAbsent(int id) =>
      DBService.isEmployeeAbsentOn(id, _selectedDate);

  Future<void> _chooseDate() async {
    final initial = DateFormat('dd-MM-yyyy', 'fr_FR').parse(_selectedDate);
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('fr', 'FR'),
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('dd-MM-yyyy', 'fr_FR').format(picked);
      });
    }
  }

  Color _statusColor(String? status, {bool arrival = true}) {
    if (status == null) return Colors.red.shade400;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Crèche Les Écureuils',
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _chooseDate,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text(_selectedDate)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sous-titre centré
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: Text(
                'Pointage',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          // Liste des employés
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _employees.length,
                itemBuilder: (context, i) {
                  final e = _employees[i];
                  return FutureBuilder<bool>(
                    future: _isAbsent(e.id!),
                    builder: (context, snapAbsent) {
                      final absent = snapAbsent.data ?? false;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                absent ? Colors.orange : Colors.blue,
                            child: Text(
                              '${e.prenom[0]}${e.nom[0]}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text('${e.prenom} ${e.nom}'),
                          subtitle: FutureBuilder<Attendance?>(
                            future: DBService.getAttendanceFor(
                                e.id!, _selectedDate),
                            builder: (context, snap) {
                              final att = snap.data;
                              final arr = att?.arrival;
                              final dep = att?.departure;

                              if (absent) {
                                return const Text(
                                  'Absent (déclaré)',
                                  style: TextStyle(color: Colors.orange),
                                );
                              }

                              if (att == null) {
                                return const Text(
                                  'Non pointé',
                                  style: TextStyle(color: Colors.red),
                                );
                              }

                              // Affichage compact des heures
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Arrivée: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Expanded(
                                        child: Text(
                                          arr ?? 'Non pointé',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: _statusColor(arr)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Text(
                                        'Départ: ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Expanded(
                                        child: Text(
                                          dep ?? 'Non pointé',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: _statusColor(dep,
                                                  arrival: false)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.login),
                                onPressed:
                                    absent ? null : () => _pointArrival(e),
                                tooltip: 'Pointer arrivée',
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout),
                                onPressed:
                                    absent ? null : () => _pointDeparture(e),
                                tooltip: 'Pointer départ',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

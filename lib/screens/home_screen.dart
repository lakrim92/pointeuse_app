import 'package:flutter/material.dart';
import 'employees_screen.dart';
import 'attendance_screen.dart';
import 'absence_screen.dart';
import 'export_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  final pages = [
    const AttendanceScreen(),
    const EmployeesScreen(),
    const AbsenceScreen(),
    const ExportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.indigo.shade50,
        indicatorColor: Colors.indigo.shade100,
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.access_time), label: 'Pointage'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Salariés'),
          NavigationDestination(icon: Icon(Icons.event_busy), label: 'Absences'),
          NavigationDestination(icon: Icon(Icons.download), label: 'Exports'),
        ],
      ),
    );
  }
}

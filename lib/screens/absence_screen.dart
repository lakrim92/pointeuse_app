// lib/screens/absence_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_service.dart';
import '../models/employee.dart';
import '../models/absence.dart';
import '../widgets/custom_appbar.dart';

class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key});
  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  List<Employee> _employees = [];
  int? _selectedId;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  String _type = 'Congé';
  final _commentCtrl = TextEditingController();

  final _types = [
    'Congé',
    'Arrêt maladie',
    'Enfant malade',
    'Congé exceptionnel',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await DBService.getAllEmployees();
    setState(() {
      _employees = e;
      if (_selectedId == null && e.isNotEmpty) _selectedId = e.first.id;
    });
  }

  Future<void> _pickStart() async {
    final p = await showDatePicker(
        context: context,
        initialDate: _start,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        locale: const Locale('fr', 'FR')); // <-- forcer le français
    if (p != null) setState(() => _start = p);
  }

  Future<void> _pickEnd() async {
    final p = await showDatePicker(
        context: context,
        initialDate: _end,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        locale: const Locale('fr', 'FR')); // <-- forcer le français
    if (p != null) setState(() => _end = p);
  }

  Future<void> _saveAbsence() async {
    if (_selectedId == null) return;

    final TextEditingController pwdCtrl = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Mot de passe administrateur'),
        content: TextField(
          controller: pwdCtrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Mot de passe'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(pwdCtrl.text),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) return;

    final valid = await AdminPasswordManager.verifyPassword(password);
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe incorrect')));
      return;
    }

    final employee = _employees.firstWhere((e) => e.id == _selectedId,
        orElse: () => _employees.first);

    final a = Absence(
      employeeId: employee.id!,
      startDate: DateFormat('dd-MM-yyyy', 'fr_FR').format(_start),
      endDate: DateFormat('dd-MM-yyyy', 'fr_FR').format(_end),
      type: _type,
      comment: _commentCtrl.text.trim(),
    );

    await DBService.insertAbsence(a);
    _commentCtrl.clear();
    await _load();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Absence enregistrée')));
  }

  Future<void> _showEmployeeAbsences(Employee e) async {
    final abs = await DBService.getAbsencesForEmployee(e.id!);
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(12),
        height: 400,
        child: Column(
          children: [
            Text('${e.prenom} ${e.nom}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: abs.length,
                itemBuilder: (_, i) {
                  final a = abs[i];
                  return ListTile(
                    title: Text('${a.type} (${a.startDate} → ${a.endDate})'),
                    subtitle: a.comment != null ? Text(a.comment!) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await DBService.deleteAbsence(a.id!);
                        Navigator.pop(context);
                        _showEmployeeAbsences(e);
                      },
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Crèche Les Écureuils',
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Sous-titre centré
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: Text(
                'Absences',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          // Formulaire d'ajout
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedId,
                    items: _employees
                        .map((e) => DropdownMenuItem(
                            value: e.id, child: Text('${e.prenom} ${e.nom}')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedId = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: Text(
                              'Début: ${DateFormat('dd-MM-yyyy', 'fr_FR').format(_start)}')),
                      TextButton(
                          onPressed: _pickStart,
                          child: const Text('Choisir')),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: Text(
                              'Fin: ${DateFormat('dd-MM-yyyy', 'fr_FR').format(_end)}')),
                      TextButton(
                          onPressed: _pickEnd,
                          child: const Text('Choisir')),
                    ],
                  ),
                  DropdownButton<String>(
                    value: _type,
                    isExpanded: true,
                    items: _types
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                  TextField(
                    controller: _commentCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Commentaire (optionnel)'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: _saveAbsence,
                      child: const Text('Enregistrer l\'absence')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Voir / gérer les absences par salarié:'),
          const SizedBox(height: 8),
          // Liste des salariés
          ..._employees.map((e) => ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text('${e.prenom} ${e.nom}'),
                trailing: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => _showEmployeeAbsences(e)),
              )),
        ],
      ),
    );
  }
}

// lib/screens/employees_screen.dart
import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/db_service.dart';
import '../widgets/custom_appbar.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await DBService.getAllEmployees();
    setState(() => _employees = e);
  }

  Future<void> _add() async {
    final nom = _nomCtrl.text.trim();
    final prenom = _prenomCtrl.text.trim();
    if (nom.isEmpty || prenom.isEmpty) return;

    await DBService.insertEmployee(Employee(nom: nom, prenom: prenom));
    _nomCtrl.clear();
    _prenomCtrl.clear();
    await _load();
  }

  Future<void> _delete(Employee e) async {
    final abs = await DBService.getAbsencesForEmployee(e.id!);
    final pointages = await DBService.getPointagesForEmployee(e.id!);

    final password = await showDialog<String>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Mot de passe administrateur'),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    if (password == null) return;

    final success = await DBService.deleteEmployeeWithPassword(e.id!, password);

    if (!success) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Erreur'),
            content: const Text('Mot de passe administrateur incorrect.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK')),
            ],
          ),
        );
      }
      return;
    }

    await _load();
  }

  Future<bool> _isAbsent(int id) =>
      DBService.isEmployeeAbsentOn(id, DateTime.now().toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Crèche Les Écureuils',
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Sous-titre centré
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Text(
                  'Salariés',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            // Zone d'ajout
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nomCtrl,
                        decoration: const InputDecoration(labelText: 'Nom'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _prenomCtrl,
                        decoration: const InputDecoration(labelText: 'Prénom'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: _add,
                      tooltip: 'Ajouter un salarié',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Liste des salariés avec couleurs pour absents/présents
            ..._employees.map((e) => FutureBuilder<bool>(
                  future: _isAbsent(e.id!),
                  builder: (context, snapAbsent) {
                    final absent = snapAbsent.data ?? false;
                    return Card(
                      color: absent ? Colors.orange.shade100 : Colors.blue.shade50,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: absent ? Colors.orange : Colors.blue,
                          child: Text(
                            '${e.prenom[0]}${e.nom[0]}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text('${e.prenom} ${e.nom}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.info_outline),
                              tooltip: 'Voir absences',
                              onPressed: () async {
                                final abs =
                                    await DBService.getAbsencesForEmployee(e.id!);
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) => Container(
                                    padding: const EdgeInsets.all(12),
                                    height: 300,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('${e.prenom} ${e.nom}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        const Text('Absences :'),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: abs.isEmpty
                                              ? const Center(
                                                  child: Text(
                                                      'Aucune absence enregistrée'),
                                                )
                                              : ListView.builder(
                                                  itemCount: abs.length,
                                                  itemBuilder: (_, j) {
                                                    final a = abs[j];
                                                    return ListTile(
                                                      title: Text(
                                                          '${a.type} (${a.startDate} → ${a.endDate})'),
                                                      subtitle:
                                                          a.comment != null
                                                              ? Text(a.comment!)
                                                              : null,
                                                    );
                                                  },
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              tooltip: 'Supprimer le salarié',
                              onPressed: () => _delete(e),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }
}

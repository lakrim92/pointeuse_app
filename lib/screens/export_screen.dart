// lib/screens/export_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';
import '../services/backup_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  bool _isProcessing = false;

  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  String _adminPassword = "MotDePasseDirectrice";

  @override
  void initState() {
    super.initState();
    _loadAdminPassword();
  }

  Future<void> _loadAdminPassword() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminPassword =
          prefs.getString('admin_password') ?? "MotDePasseDirectrice";
    });
  }

  Future<void> _updateAdminPassword() async {
    final oldPass = _oldPassCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (oldPass != _adminPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Ancien mot de passe incorrect")),
      );
      return;
    }
    if (newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠️ Les champs ne peuvent pas être vides")),
      );
      return;
    }
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text("⚠️ Les nouveaux mots de passe ne correspondent pas")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_password', newPass);
    setState(() {
      _adminPassword = newPass;
      _oldPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Mot de passe administrateur mis à jour")),
    );
  }

  Future<void> _pickFrom() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (p != null) setState(() => _from = p);
  }

  Future<void> _pickTo() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (p != null) setState(() => _to = p);
  }

  String _fmt(DateTime d) => DateFormat('dd-MM-yyyy').format(d);

  Future<void> _exportPDF() async {
    setState(() => _isProcessing = true);
    try {
      final from = _fmt(_from);
      final to = _fmt(_to);

      // Récupère tous les salariés avec pointages et absences
      final rows = await DBService.getAttendanceExportWithAbsences(from, to);

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Feuille de présence ($from → $to)',
                  style: pw.TextStyle(fontSize: 18),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: [
                  'Date',
                  'Nom',
                  'Prénom',
                  'Arrivée',
                  'Départ',
                  'Absences'
                ],
                data: rows
                    .map((r) => [
                          r['date'] ?? '',
                          r['nom'] ?? '',
                          r['prenom'] ?? '',
                          r['arrival'] ?? '',
                          r['departure'] ?? '',
                          r['absences'] ?? '',
                        ])
                    .toList(),
              ),
            ];
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pointage_${from}_to_${to}.pdf');
      await file.writeAsBytes(await doc.save());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF généré: ${file.path}')),
        );
      }
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'pointage_${from}_to_${to}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l’export PDF: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isProcessing = true);
    try {
      final from = _fmt(_from);
      final to = _fmt(_to);

      final rows = await DBService.getAttendanceExportWithAbsences(from, to);

      final excel = Excel.createExcel();
      final sheet = excel['Pointage'];
      sheet.appendRow(
          ['Date', 'Nom', 'Prénom', 'Arrivée', 'Départ', 'Absences']);
      for (final r in rows) {
        sheet.appendRow([
          r['date'] ?? '',
          r['nom'] ?? '',
          r['prenom'] ?? '',
          r['arrival'] ?? '',
          r['departure'] ?? '',
          r['absences'] ?? '',
        ]);
      }

      final dir = await getApplicationDocumentsDirectory();
      final bytes = excel.encode();
      final file = File('${dir.path}/pointage_${from}_to_${to}.xlsx');
      await file.writeAsBytes(bytes!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel généré: ${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l’export Excel: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _backupDatabase() async {
    setState(() => _isProcessing = true);
    try {
      final filePath = await BackupService.backupDatabase(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sauvegarde réussie: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de sauvegarde: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreDatabase() async {
    setState(() => _isProcessing = true);
    try {
      final result = await BackupService.restoreDatabaseFromPicker(context);
      if (mounted && result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restauration réussie.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de restauration: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exports & Sauvegarde'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child:
                        Text('De: ${DateFormat('dd-MM-yyyy').format(_from)}')),
                TextButton(onPressed: _pickFrom, child: const Text('Choisir')),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: Text('À: ${DateFormat('dd-MM-yyyy').format(_to)}')),
                TextButton(onPressed: _pickTo, child: const Text('Choisir')),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _exportPDF,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exporter PDF'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _exportExcel,
              icon: const Icon(Icons.grid_on),
              label: const Text('Exporter Excel'),
            ),
            const Divider(height: 30),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _backupDatabase,
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Sauvegarder la base'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _restoreDatabase,
              icon: const Icon(Icons.restore),
              label: const Text('Restaurer la base'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
            const Divider(height: 30),
            const Text(
              'Changer le mot de passe administrateur',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _oldPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Ancien mot de passe",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Nouveau mot de passe",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirmer le nouveau mot de passe",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _updateAdminPassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text('Mettre à jour le mot de passe'),
            ),
            const SizedBox(height: 20),
            if (_isProcessing) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

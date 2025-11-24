// lib/services/db_service.dart
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/employee.dart';
import '../models/attendance.dart';
import '../models/absence.dart';

// --- Mot de passe administrateur dynamique ---
class AdminPasswordManager {
  static const String _key = "admin_password";
  static const String _defaultPassword = "MotDePasseDirectrice";

  static Future<String> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? _defaultPassword;
  }

  static Future<void> setPassword(String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, newPassword);
  }

  static Future<bool> verifyPassword(String password) async {
    final current = await getPassword();
    return password == current;
  }
}

class DBService {
  static Database? _db;

  // ---------- INITIALISATION ----------
  static Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'pointeuse.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) async {
        await _migrateEnsureColumns(db);
      },
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE employees(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        actif INTEGER NOT NULL DEFAULT 1
      );
    ''');

    await db.execute('''
      CREATE TABLE attendances(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER,
        employee_name TEXT,
        date TEXT NOT NULL,
        arrival TEXT,
        departure TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE absences(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id INTEGER,
        type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        comment TEXT
      );
    ''');
  }

  static Future<void> _migrateEnsureColumns(Database db) async {
    try {
      final attendInfo = await db.rawQuery("PRAGMA table_info('attendances');");
      final hasEmployeeName =
          attendInfo.any((col) => (col['name'] as String?) == 'employee_name');
      if (!hasEmployeeName) {
        await db
            .execute("ALTER TABLE attendances ADD COLUMN employee_name TEXT;");
      }

      final empInfo = await db.rawQuery("PRAGMA table_info('employees');");
      final hasActif =
          empInfo.any((col) => (col['name'] as String?) == 'actif');
      if (!hasActif) {
        await db.execute(
            "ALTER TABLE employees ADD COLUMN actif INTEGER DEFAULT 1;");
        await db.execute("UPDATE employees SET actif = 1 WHERE actif IS NULL;");
      }
    } catch (e) {
      print('Migration check failed: $e');
    }
  }

  static Future<Database> get _database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  // ---------- EMPLOYEES ----------
  static Future<List<Employee>> getAllEmployees() async {
    final db = await _database;
    final res = await db.query('employees',
        where: 'actif = ?', whereArgs: [1], orderBy: 'nom');
    return res.map((e) => Employee.fromMap(e)).toList();
  }

  static Future<List<Employee>> getAllEmployeesAll() async {
    final db = await _database;
    final res = await db.query('employees', orderBy: 'nom');
    return res.map((e) => Employee.fromMap(e)).toList();
  }

  static Future<int> insertEmployee(Employee e) async {
    final db = await _database;
    return await db.insert('employees', e.toMap());
  }

  static Future<int> deleteEmployee(int id) async {
    final db = await _database;
    return await db.update('employees', {'actif': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  static Future<bool> deleteEmployeeWithPassword(
      int employeeId, String password) async {
    if (!await AdminPasswordManager.verifyPassword(password)) return false;
    final db = await _database;
    await db.update('employees', {'actif': 0},
        where: 'id = ?', whereArgs: [employeeId]);
    return true;
  }

  static Future<int> reactivateEmployee(int id) async {
    final db = await _database;
    return await db.update('employees', {'actif': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  // ---------- ATTENDANCE ----------
  static String _today() => DateFormat('dd-MM-yyyy').format(DateTime.now());

  static Future<Attendance?> getAttendanceFor(
      int employeeId, String date) async {
    final db = await _database;
    final res = await db.query(
      'attendances',
      where: 'employee_id = ? AND date = ?',
      whereArgs: [employeeId, date],
    );
    if (res.isEmpty) return null;
    return Attendance.fromMap(res.first);
  }

  static Future<List<Attendance>> getAttendanceByDate(String date) async {
    final db = await _database;
    final res =
        await db.query('attendances', where: 'date = ?', whereArgs: [date]);
    return res.map((m) => Attendance.fromMap(m)).toList();
  }

  static Future<String> _fetchEmployeeName(int? employeeId) async {
    if (employeeId == null) return 'Employé';
    final db = await _database;
    try {
      final rows = await db.query('employees',
          where: 'id = ?', whereArgs: [employeeId], limit: 1);
      if (rows.isNotEmpty) {
        final r = rows.first;
        final prenom = r['prenom'] as String? ?? '';
        final nom = r['nom'] as String? ?? '';
        final actif = r['actif'] as int? ?? 0;
        final full = (prenom + ' ' + nom).trim();
        return (full.isNotEmpty ? full : 'Employé') +
            (actif == 0 ? ' (supprimé)' : '');
      }
    } catch (_) {}
    return 'Employé supprimé';
  }

  /// Insert ou met à jour l'arrivée
  static Future<int> insertOrUpdateArrival(
      int employeeId, String date, String time) async {
    final db = await _database;
    final existing = await getAttendanceFor(employeeId, date);
    final empName = await _fetchEmployeeName(employeeId);

    if (existing == null) {
      return await db.insert('attendances', {
        'employee_id': employeeId,
        'employee_name': empName,
        'date': date,
        'arrival': time,
        'departure': null,
      });
    } else {
      if (existing.arrival != null) return 0;
      return await db.update(
        'attendances',
        {'arrival': time, 'employee_name': empName},
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
  }

  static Future<int> insertOrUpdateDeparture(
      int employeeId, String date, String time) async {
    final db = await _database;
    final existing = await getAttendanceFor(employeeId, date);
    final empName = await _fetchEmployeeName(employeeId);

    if (existing == null || existing.arrival == null) {
      return -1;
    } else if (existing.departure != null) {
      return 0;
    } else {
      return await db.update(
        'attendances',
        {'departure': time, 'employee_name': empName},
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
  }

  static Future<List<Attendance>> getPointagesForEmployee(
      int employeeId) async {
    final db = await _database;
    final res = await db.query('attendances',
        where: 'employee_id = ?',
        whereArgs: [employeeId],
        orderBy: 'date DESC');
    return res.map((m) => Attendance.fromMap(m)).toList();
  }

  // ---------- ABSENCES ----------
  static Future<int> insertAbsence(Absence a) async {
    final db = await _database;
    return await db.insert('absences', a.toMap());
  }

  static Future<int> updateAbsence(Absence a) async {
    final db = await _database;
    return await db
        .update('absences', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  static Future<int> deleteAbsence(int id) async {
    final db = await _database;
    return await db.delete('absences', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Absence>> getAbsencesForEmployee(int employeeId) async {
    final db = await _database;
    final res = await db.query('absences',
        where: 'employee_id = ?',
        whereArgs: [employeeId],
        orderBy: 'start_date DESC');
    return res.map((m) => Absence.fromMap(m)).toList();
  }

  static Future<List<Absence>> getAbsencesByDate(String date) async {
    final db = await _database;
    final res = await db.rawQuery(
        'SELECT * FROM absences WHERE ? BETWEEN start_date AND end_date',
        [date]);
    return res.map((m) => Absence.fromMap(m)).toList();
  }

  static Future<bool> isEmployeeAbsentOn(int employeeId, String date) async {
    final db = await _database;
    final res = await db.rawQuery(
        'SELECT * FROM absences WHERE employee_id = ? AND ? BETWEEN start_date AND end_date',
        [employeeId, date]);
    return res.isNotEmpty;
  }

  // ---------- EXPORT ----------
  /// Retourne tous les employés (actifs) avec pointages ou absences
  static Future<List<Map<String, dynamic>>> getAttendanceExportWithAbsences(
      String from, String to) async {
    final db = await _database;

    // Récupère tous les employés actifs
    final employees = await db.query('employees', where: 'actif = ?', whereArgs: [1]);

    List<Map<String, dynamic>> export = [];

    for (final emp in employees) {
      final employeeId = emp['id'] as int;
      final nom = emp['nom'] as String? ?? '';
      final prenom = emp['prenom'] as String? ?? '';

      // Parcours des jours du range
      DateTime start = DateFormat('dd-MM-yyyy').parse(from);
      DateTime end = DateFormat('dd-MM-yyyy').parse(to);

      for (DateTime d = start;
          !d.isAfter(end);
          d = d.add(const Duration(days: 1))) {
        final dateStr = DateFormat('dd-MM-yyyy').format(d);

        // Attendance
        final res = await db.query(
          'attendances',
          where: 'employee_id = ? AND date = ?',
          whereArgs: [employeeId, dateStr],
        );

        String arrival = '';
        String departure = '';
        if (res.isNotEmpty) {
          arrival = res.first['arrival'] as String? ?? '';
          departure = res.first['departure'] as String? ?? '';
        }

        // Absences
        final absences = await db.rawQuery(
          'SELECT type || (CASE WHEN comment IS NOT NULL THEN " (" || comment || ")" ELSE "" END) as abs_text '
          'FROM absences WHERE employee_id = ? AND ? BETWEEN start_date AND end_date',
          [employeeId, dateStr],
        );

        String absText;
        if (absences.isNotEmpty) {
          absText = absences.map((a) => a['abs_text']).join('; ');
        } else if (arrival.isEmpty && departure.isEmpty) {
          absText = 'Pas pointé';
        } else {
          absText = '';
        }

        export.add({
          'date': dateStr,
          'nom': nom,
          'prenom': prenom,
          'arrival': arrival,
          'departure': departure,
          'absences': absText,
        });
      }
    }

    // Trie par nom puis prénom puis date
    export.sort((a, b) {
      final cmpNom = (a['nom'] as String).compareTo(b['nom'] as String);
      if (cmpNom != 0) return cmpNom;
      final cmpPrenom = (a['prenom'] as String).compareTo(b['prenom'] as String);
      if (cmpPrenom != 0) return cmpPrenom;
      return (a['date'] as String).compareTo(b['date'] as String);
    });

    return export;
  }

  static Future<List<Employee>> getAllEmployeesSimple() => getAllEmployees();

  static Future<List<Attendance>> getAttendanceRange(
      String from, String to) async {
    final db = await _database;
    final res = await db.query('attendances',
        where: 'date BETWEEN ? AND ?', whereArgs: [from, to], orderBy: 'date');
    return res.map((m) => Attendance.fromMap(m)).toList();
  }
}

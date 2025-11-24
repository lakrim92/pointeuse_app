// lib/services/backup_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class BackupService {
  /// Retourne le chemin complet de la base de données active.
  static Future<String> getDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, 'pointeuse.db');
  }

  /// Sauvegarde la base de données actuelle dans le dossier Documents
  /// sous la forme : pointage_backup_TIMESTAMP.db
  static Future<String> backupDatabase(BuildContext context) async {
    try {
      final src = await getDbPath();
      final now = DateTime.now();
      final stamp = now.toIso8601String().replaceAll(':', '-');

      final dir = await getApplicationDocumentsDirectory();
      final dst = join(dir.path, 'pointage_backup_$stamp.db');
      await File(src).copy(dst);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Sauvegarde effectuée : ${basename(dst)}')),
      );

      return dst;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur lors de la sauvegarde : $e')),
      );
      rethrow;
    }
  }

  /// Restaure la base de données à partir d’un fichier sélectionné par l’utilisateur.
  static Future<bool> restoreDatabaseFromPicker(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun fichier sélectionné.')),
        );
        return false;
      }

      final pickedPath = result.files.single.path!;
      final pickedFile = File(pickedPath);

      if (!await pickedFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier invalide ou introuvable.')),
        );
        return false;
      }

      final dst = await getDbPath();

      // Remplace la base de données actuelle
      await pickedFile.copy(dst);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Base restaurée depuis ${basename(pickedPath)}')),
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur lors de la restauration : $e')),
      );
      return false;
    }
  }

  /// Restaure la base depuis un chemin local direct (utilisé en interne).
  static Future<bool> restoreFromPath(String path) async {
    final src = File(path);
    if (!await src.exists()) return false;

    final dst = await getDbPath();
    await src.copy(dst);
    return true;
  }
}

// lib/screens/admin_login_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  final VoidCallback onSuccess;
  const AdminLoginScreen({super.key, required this.onSuccess});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _ctrl = TextEditingController();
  bool _isSetting = false; // si aucun mot de passe défini -> mode création
  String _message = '';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final set = await AuthService.isPasswordSet();
    setState(() => _isSetting = !set);
  }

  Future<void> _submit() async {
    final val = _ctrl.text.trim();
    if (val.isEmpty) return;
    if (_isSetting) {
      await AuthService.setPassword(val);
      setState(() {
        _message = 'Mot de passe admin défini.';
        _isSetting = false;
      });
      widget.onSuccess();
    } else {
      final ok = await AuthService.verifyPassword(val);
      if (ok) {
        widget.onSuccess();
      } else {
        setState(() => _message = 'Mot de passe incorrect.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSetting ? 'Définir mot de passe admin' : 'Connexion Admin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(_isSetting
                ? 'Aucun mot de passe admin trouvé. Veuillez en définir un.'
                : 'Entrez le mot de passe administrateur.'),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe admin'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _submit, child: Text(_isSetting ? 'Définir' : 'Se connecter')),
            const SizedBox(height: 12),
            Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

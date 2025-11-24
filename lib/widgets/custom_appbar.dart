// lib/widgets/custom_appbar.dart
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title; // Titre principal (ex: "Crèche Les Écureuils")
  final String? subtitle; // Titre secondaire par page (ex: "Pointage")
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.indigo,
      centerTitle: true, // ✅ centre le contenu horizontalement
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min, // ✅ taille minimale pour centrer
            mainAxisAlignment:
                MainAxisAlignment.center, // ✅ centre le logo et le titre
            children: [
              Image.asset(
                'assets/images/logo_petits-ecureuils.png',
                height: 36,
                width: 36,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis, // ✅ coupe si trop long
                ),
              ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold, // en gras
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 28);
  // +28 pour laisser suffisamment de place au sous-titre centré
}

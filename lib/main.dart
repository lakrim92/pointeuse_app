import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // 🔹 Import nécessaire
import 'screens/home_screen.dart';
import 'services/db_service.dart';
import 'models/employee.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Initialise les données locales pour le français
  await initializeDateFormatting('fr_FR', null);

  // 🔹 Initialise la base de données
  await DBService.init();

  runApp(const PointeuseApp());
}

class PointeuseApp extends StatelessWidget {
  const PointeuseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Pointeuse Crèche',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        // 🔹 Localisation française
        locale: const Locale('fr', 'FR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
        ],
        home: const SplashScreen(),
      ),
    );
  }
}


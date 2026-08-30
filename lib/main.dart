import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:zapatito_v2/main-widgets/MAIN/home_page.dart';
import 'package:zapatito_v2/main-widgets/MAIN/login_page.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  // Inicializa el formato de fecha para español
  await initializeDateFormatting('es_ES', null);
  
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zapatito',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3a086c)),
        scaffoldBackgroundColor: Colors.white,
      ),

      // --- 2. CONFIGURACIÓN DE IDIOMAS (ESTO ARREGLA EL ERROR DEL CALENDARIO) ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés
      ],
      locale: const Locale('es', 'ES'), // Idioma predeterminado
      // -----------------------------------------------------------------------

      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      }
    );
  }
}
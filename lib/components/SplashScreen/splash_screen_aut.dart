// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget{
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? ruta = ModalRoute.of(context)?.settings.arguments as String?;
      
      // Si se proporciona una ruta válida, navega después de 2 segundos
      if (ruta != null && ruta.isNotEmpty) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, ruta);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Color de fondo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/assets/ic_launcher.png', height: 100), // Tu logo
            const SizedBox(height: 20), // Espacio entre el logo y el loader
            const CircularProgressIndicator( // Loader
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Color del loader
            ),
          ],
        ),
      ),
    );
  }
}
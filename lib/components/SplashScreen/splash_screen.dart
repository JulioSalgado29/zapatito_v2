import 'package:flutter/material.dart';

class SplashScreen02 extends StatelessWidget {
  const SplashScreen02({super.key});

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
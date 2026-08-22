import 'package:auth_buttons/auth_buttons.dart';
import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/main-widgets/MAIN/home_page.dart';
import 'package:zapatito_v2/services/API/sesion_google_log_service.dart';
import 'package:zapatito_v2/services/google_auth.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  // Función modificada para invocar tu LocalStorageService
  Future<void> _saveUserLog() async {
    await SesionGoogleLogService.registrarLogDesdeStorage();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      child: GoogleAuthButton(
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const SplashScreen02(),
          );

          // 1. Intento Silencioso
          final silentResult = await GoogleAuthService().trySilentSignIn();

          if (silentResult != null) {
            // Esperamos a que se guarde el log antes de navegar
            await _saveUserLog(); 
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
            return;
          }

          // 2. Intento Manual
          final result = await GoogleAuthService().signInWithGoogle();

          if (result != null) {
            await _saveUserLog(); 
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          } else {
            if (context.mounted) Navigator.of(context).pop();
            print('Error o usuario canceló');
          }
        },
        text: 'Iniciar sesión con Google',
        style: const AuthButtonStyle(
          borderRadius: 5.0,
          buttonColor: Colors.white,
        ),
      ),
    );
  }
}
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
      height: 52,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xff3a086c),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff3a086c).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
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
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false, // Elimina todas las rutas anteriores
                );
              }
              return;
            }

            // 2. Intento Manual
            final result = await GoogleAuthService().signInWithGoogle();

            if (result != null) {
              await _saveUserLog();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false, // Elimina todas las rutas anteriores
                );
              }
            } else {
              if (context.mounted) Navigator.of(context).pop();
              print('Error o usuario canceló');
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono de Google dentro de un círculo blanco limpio
                CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.white,
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xff3a086c),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Iniciar sesión con Google',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

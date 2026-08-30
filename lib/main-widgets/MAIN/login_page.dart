import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/Buttons/google_button.dart';
import 'package:zapatito_v2/main-widgets/MAIN/home_page.dart';
import 'package:zapatito_v2/services/API/sesion_google_log_service.dart';
import 'package:zapatito_v2/services/google_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _navigated = false; // 👈 Evita múltiples redirecciones

  Future<void> _saveUserLog() async {
    await SesionGoogleLogService.registrarLogDesdeStorage();
  }

  @override
  void initState() {
    super.initState();
    _checkIfSignedIn();
  }

  void _checkIfSignedIn() async {
    if (_navigated) return; // Evita que se ejecute más de una vez
    _navigated = true;

    final isSignedIn = await GoogleAuthService().isCurrentSignIn();
    if (!mounted) return;

    if (isSignedIn) {
      await _saveUserLog();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false, // Elimina todas las rutas anteriores
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;

    return Scaffold(
      body: Stack(
        children: [
          /// 1. Fondo principal con degradado morado
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2A0845), // Morado profundo superior
                  Color(0xFF150028), // Morado oscuro inferior
                ],
              ),
            ),
          ),

          /// 2. Contenido vertical centrado y compacto
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Espaciado dinámico superior para librar el BackButton
                      SizedBox(height: height * 0.04),

                      // Logo de la marca
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_run_rounded,
                              color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            "Bienvenido a\nZapatito",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      const SizedBox(height: 20),

                      // ILUSTRACIÓN CENTRAL
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          height: height * 0.28,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('lib/assets/logo_inicio.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 24), // Espacio controlado antes del botón

                      // BOTÓN DE GOOGLE
                      const GoogleButton(),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

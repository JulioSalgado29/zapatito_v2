import 'dart:ui';
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
  bool _navigated = false;

  Future<void> _saveUserLog() async {
    await SesionGoogleLogService.registrarLogDesdeStorage();
  }

  @override
  void initState() {
    super.initState();
    _checkIfSignedIn();
  }

  void _checkIfSignedIn() async {
    if (_navigated) return;
    _navigated = true;

    final isSignedIn = await GoogleAuthService().isCurrentSignIn();
    if (!mounted) return;

    if (isSignedIn) {
      await _saveUserLog();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF130025),
      body: Stack(
        children: [
          /// 1. Fondo base con degradado refinado
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2C0B4D),
                  Color(0xFF130025),
                  Color(0xFF090014),
                ],
              ),
            ),
          ),

          /// 2. Luces de fondo (Glow ambiental)
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8E2DE2).withOpacity(0.18),
              ),
            ),
          ),

          /// 3. Contenido Principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Encabezado estilizado con Badge y tipografía elegante
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "BIENVENIDO A",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              
                              Text(
                                "Zapatito",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                            ],
                          ),
                        const SizedBox(width: 14),
                        Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                            child: Image.asset(
                              'lib/assets/logo_login.png',
                              width: 30,
                              height: 30,
                              color: Colors.white,
                            ),
                          ),
                          
                        ],
                      ),

                      SizedBox(height: size.height * 0.04),

                      // Tarjeta principal con la ilustración y sombra sutil
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            height: size.height * 0.32,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('lib/assets/logo_inicio.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.04),

                      // Tarjeta con efecto Glassmorphism envolviendo el botón
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: const Column(
                              children: [
                                GoogleButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
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
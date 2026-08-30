import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/Buttons/login_button.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/MAIN/home_page.dart';
import 'package:zapatito_v2/services/google_auth.dart';
import 'package:zapatito_v2/services/local_storage.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  late Future<bool> _checkAuthFuture;
  bool _navigated = false; // 👈 Evita múltiples redirecciones

  @override
  void initState() {
    super.initState();
    _checkAuthFuture = LocalStorageService.isLoggedIn();
  }

  void _checkIfSignedIn() async {
    if (_navigated) return; // Evita que se ejecute más de una vez
    _navigated = true;

    final isSignedIn = await GoogleAuthService().isCurrentSignIn();
    if (!mounted) return;

    if (isSignedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _checkAuthFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error al inicializar Firebase"),
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            // 👇 Solo se ejecuta una vez, después de renderizar el frame
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfSignedIn());
          }

          // --- DISEÑO INMERSIVO ---
          return Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              // 👉 AQUÍ VA LA IMAGEN DE CALZADO DE ALTA CALIDAD (Placeholder)
              image: DecorationImage(
                image: NetworkImage('https://via.placeholder.com/800x1600.png?text=Zapatito+Imagen'), // Reemplazar con tu imagen real
                fit: BoxFit.cover, // Para que cubra todo el fondo
              ),
            ),
            child: Container(
              // 👉 DEGRADADO MORADO PARA INTEGRACIÓN Y LEGIBILIDAD
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xff3a086c).withOpacity(0.5), // Morado base arriba
                    Colors.black.withOpacity(0.8), // Más oscuro abajo para el botón
                  ],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribución superior/inferior
                children: [
                  // --- TÍTULO Y SUBTÍTULO (Superior) ---
                  Column(
                    children: [
                      Designwidgets().tittleCustom("Bienvenido a Zapatito"),
                      const SizedBox(height: 10),
                      const Text(
                        "Encuentra tu estilo paso a paso. La mejor selección de calzado.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),

                  // --- BOTÓN COMENZAR (Central/Inferior) ---
                  const LoginButton(
                    text: "Comenzar",
                    color: Color(0xff3a086c),
                    textColor: Colors.white,
                    routeName: '/login',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
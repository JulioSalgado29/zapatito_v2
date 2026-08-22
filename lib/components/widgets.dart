import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zapatito_v2/main-widgets/MAIN/welcome_page.dart';
import 'package:zapatito_v2/services/google_auth.dart';

class Designwidgets {
  AppBar appBarMain(String title) {
    return AppBar(
      backgroundColor: const Color(0xff5b16c2),
      foregroundColor: Colors.white,
      title: Text(
        title,
        style:
            const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Georgia'),
      ),
      /*actions: [
          Icon(isOnline ? Icons.wifi : Icons.wifi_off,
              color: isOnline ? Colors.green : Colors.red),
          const SizedBox(width: 16),
        ],*/
    );
  }

  LinearGradient linearGradientMain(BuildContext context) {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xff3a086c),
        Color(0xff5b16c2),
      ],
    );
  }

  LinearGradient linearGradientPurple(BuildContext context) {
  return const LinearGradient(
    colors: [
      Color(0xFF6A11CB), // Púrpura azulado (conecta con el azul)
      Color(0xFF8E24AA), // Violeta medio
      Color(0xFFD81B60), // Rosa/Rojo intenso (conecta con el fuego)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

  LinearGradient linearGradientFire(BuildContext context) {
    return const LinearGradient(
      colors: [
        Color(0xFFD84315), // rojo fuego - inicio
        Color(0xFFE67A22), // naranja claro - centro claro
        Color(0xFFFF7043), // naranja intenso - centro medio
        Color(0xFFF4511E), // rojo-anaranjado - centro profundo
        Color(0xFFD84315), // rojo fuego - final
      ],
      stops: [
        0.0,
        0.35, // zona clara
        0.5, // zona intermedia
        0.65, // zona transicion
        1.0,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  LinearGradient linearGradientBlue(BuildContext context) {
    return const LinearGradient(
      colors: [
        Color.fromARGB(255, 33, 47, 243), // Azul principal
        Color(0xFF3E54FF), // Azul suave más claro
        Color(0xFF1E2EB8), // Azul profundo casi morado
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  RichText tittleCustom(String text) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: text,
        style: GoogleFonts.mouseMemoirs(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: const Color(0xff3a086c),
        ), /*
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color:Color(0xff3a086c),
        ),*/
      ),
    );
  }

  Widget singupLabel() {
    return Container(
      margin: const EdgeInsets.only(top: 30, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            '¿No tienes una cuenta?',
            style: TextStyle(
              color: Color(0xff3a086c),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: () => print('Registrarse Presionado'),
            child: const Text(
              'Regístrate',
              style: TextStyle(
                color: Color(0xff3a086c),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget forgottenPassword() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20.0),
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => print('¿Has olvidado tu contraseña?'),
        child: const Text(
          '¿Has olvidado tu contraseña?',
          style: TextStyle(
            color: Color(0xff3a086c),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget divider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: const Row(
        children: <Widget>[
          SizedBox(
            width: 20,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Divider(
                thickness: 1,
              ),
            ),
          ),
          Text('O'),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Divider(
                thickness: 1,
              ),
            ),
          ),
          SizedBox(
            width: 20,
          ),
        ],
      ),
    );
  }

  Widget drawerHome(BuildContext context, String nombreUsuario) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xff5b16c2),
            ),
            child: Text(
              nombreUsuario,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () {
              GoogleAuthService().signOut();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const WelcomePage()));
            },
          ),
        ],
      ),
    );
  }
}

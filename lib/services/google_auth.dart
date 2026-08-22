// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zapatito_v2/services/local_storage.dart';

class GoogleAuthService {
  final auth = FirebaseAuth.instance;
  final googleSignIn = GoogleSignIn();

  // method to sign in using google
  Future<UserCredential?> trySilentSignIn() async {
  try {
    final googleUser = await googleSignIn.signInSilently();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await auth.signInWithCredential(credential);

    // 💡 GUARDAR EN LOCAL STORAGE
    // Guardamos los datos localmente cuando el inicio silencioso tiene éxito
    final user = userCredential.user;
    if (user != null) {
      await LocalStorageService.saveUserData(
        name: user.displayName ?? googleUser.displayName ?? '',
        email: user.email ?? googleUser.email,
        photoUrl: user.photoURL ?? googleUser.photoUrl ?? '',
      );
    }

    return userCredential;
  } catch (e) {
    print('Error en trySilentSignIn: $e');
    return null;
  }
}

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await googleSignIn.signIn();

      // Si el usuario cancela, googleUser será null
      print("Google User: $googleUser");
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      // Validar que al menos uno de los tokens no sea null
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);

      print("USER AFTER LOGIN: ${auth.currentUser}");

      // 🔹 Guardar datos del usuario localmente
      final user = userCredential.user;
      if (user != null) {
        await LocalStorageService.saveUserData(
          name: user.displayName ?? '',
          email: user.email ?? '',
          photoUrl: user.photoURL,
        );
      }

      return userCredential;
    } catch (e) {
      print('Error en signInWithGoogle: $e');
      return null;
    }
  }

  Future<bool> isCurrentSignIn() async {
    User? user = auth.currentUser;
    if (user != null) {
      print("User is signed in: ${user.email}");
      return true;
    }
    else {
      print("No user is signed in.");
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      // Cierra sesión de Firebase
      await auth.signOut();

      // Cierra sesión de Google si hay un usuario conectado
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      
      // 🔥 Elimina los datos guardados en local storage
      await LocalStorageService.clearUserData();


      print("Sesión cerrada correctamente.");
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }
}
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static Future<void> saveUserData({
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    if (photoUrl != null) {
      await prefs.setString('userPhoto', photoUrl);
    }
    await prefs.reload(); // 🔹 asegura escritura inmediata en iOS
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('userName'),
      'email': prefs.getString('userEmail'),
      'photo': prefs.getString('userPhoto'),
    };
  }

  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPhoto');
  }

  static Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  // Comprueba si existe el correo guardado previamente
  final email = prefs.getString('userEmail'); 
  return email != null && email.isNotEmpty;
}
}
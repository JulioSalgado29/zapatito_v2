import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/API/api_service.dart';
import 'package:zapatito_v2/services/local_storage.dart';

class SesionGoogleLogService {
  // Petición POST a la API /api/sesion_google_log
  static Future<bool> registrarLog({
    required String email,
    String? name,
    String? plataforma = 'Google',
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/sesion_google_log');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'name': name ?? 'Usuario sin nombre',
          'plataforma': plataforma,
        }),
      );

      if (response.statusCode == 201) {
        print('Log registrado exitosamente en la API');
        return true;
      } else {
        print('Error al guardar log. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al registrar log: $e');
      return false;
    }
  }

  // Método helper opcional: Obtiene los datos del almacenamiento local y registra el log
  static Future<bool> registrarLogDesdeStorage() async {
    final data = await LocalStorageService.getUserData();
    final email = data['email'];
    if (email != null && email.toString().isNotEmpty) {
      return await registrarLog(
        email: email,
        name: data['name'],
        plataforma: 'Google',
      );
    } else {
      print('No se guardó el log: email no encontrado en almacenamiento local');
      return false;
    }
  }
}
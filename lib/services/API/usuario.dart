import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/API/api_service.dart';

class UsuarioService {
  // Petición GET para obtener los datos del usuario por email como parámetro en la ruta (/api/usuario/:email)
  static Future<Map<String, dynamic>?> obtenerUsuarioPorEmail(String email) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/usuario/${Uri.encodeComponent(email)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        // Manejo flexible por si la API devuelve un List [...] o un Map {...}
        if (decodedData is List && decodedData.isNotEmpty) {
          print('Datos de usuario obtenidos exitosamente');
          return decodedData.first as Map<String, dynamic>;
        } else if (decodedData is Map<String, dynamic>) {
          print('Datos de usuario obtenidos exitosamente');
          return decodedData;
        } else {
          print('No se encontraron datos para el email: $email');
          return null;
        }
      } else {
        print('Error al consultar usuario. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de red al consultar usuario: $e');
      return null;
    }
  }
}
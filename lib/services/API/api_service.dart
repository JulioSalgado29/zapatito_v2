import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/local_storage.dart';

class ApiService {
  // Ajusta la IP/URL de tu API de Node.js
  // Usa 'http://10.0.2.2:3000' para Emulador Android o tu IP local/EC2
  static const String baseUrl = 'http://100.52.225.187:3000'; 

  static Future<bool> verificarConexionYSesion() async {
    try {
      // 1. Petición HTTP GET a tu servidor de Express con timeout de 5 segundos
      final response = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 5));

      // Si el servidor no responde 200 OK, retornamos false
      if (response.statusCode != 200) {
        return false;
      }

      // 2. Si la API responde correctamente, verificamos si hay sesión guardada en el celular
      final bool tieneSesion = await LocalStorageService.isLoggedIn();
      return tieneSesion;

    } catch (e) {
      print('Error al conectar con la API: $e');
      return false; // Si la API está apagada o no hay internet
    }
  }
}
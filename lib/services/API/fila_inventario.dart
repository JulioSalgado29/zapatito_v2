import 'dart:convert';
import 'package:http/http.dart' as http;

class FilaInventarioService {
  // IP y puerto de tu servidor Node.js
  static const String baseUrl = 'http://100.52.225.187:3000';

  // 1. Obtener filas por ID de inventario
  static Future<List<Map<String, dynamic>>> obtenerPorInventario(
      String inventarioId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/fila_inventario/inventario/$inventarioId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return List<Map<String, dynamic>>.from(body);
      }
      return [];
    } catch (e) {
      print('Error en obtenerPorInventario: $e');
      return [];
    }
  }

  // 2. Obtener subfilas por ID de fila_inventario
  static Future<List<Map<String, dynamic>>> obtenerSubfilas(
      String? filaId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/subfila_inventario/fila/$filaId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return List<Map<String, dynamic>>.from(body);
      }
      return [];
    } catch (e) {
      print('Error en obtenerSubfilas: $e');
      return [];
    }
  }

  // 3. Eliminar fila_inventario (y sus subfilas por CASCADE)
  static Future<bool> eliminar(String idFila) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/api/fila_inventario/$idFila'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error en eliminar fila: $e');
      return false;
    }
  }

  // 4. Obtener detalle de fila con datos de calzado por id_fila_inventario
  static Future<Map<String, dynamic>?> obtenerDetallePorId(
      String? idFila) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/fila_inventario/detalle/$idFila'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic body = json.decode(response.body);

        if (body is List && body.isNotEmpty) {
          return Map<String, dynamic>.from(body.first);
        } else if (body is Map<String, dynamic>) {
          return body;
        }
      }
      return null;
    } catch (e) {
      print('Error en obtenerDetallePorId: $e');
      return null;
    }
  }

  // 5. Guardar o hacer upsert de fila y subfilas (POST)
  static Future<bool> guardar(Map<String, dynamic> datos) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/fila_inventario/guardar'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(datos),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error en guardar fila: $e');
      return false;
    }
  }

  // 6. Actualizar fila y reemplazar subfilas por id_fila_inventario (PUT)
  static Future<bool> actualizar(
      String idFila, Map<String, dynamic> datos) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/fila_inventario/$idFila'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(datos),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error en actualizar fila: $e');
      return false;
    }
  }
}
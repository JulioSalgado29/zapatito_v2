import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/API/api_service.dart';

class GastoService {
  // 1. Listar gastos por ID de inventario
  // GET /api/gasto/inventario/:id_inventario
  static Future<List<Map<String, dynamic>>> obtenerPorInventario(
      String idInventario) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/gasto/inventario/${Uri.encodeComponent(idInventario)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error al listar gastos. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error de red al listar gastos: $e');
      return [];
    }
  }

  // 2. Buscar gasto por ID
  // GET /api/gasto/:id
  static Future<Map<String, dynamic>?> obtenerPorId(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/gasto/${Uri.encodeComponent(id)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is List && data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        } else {
          print('No se encontró gasto con ID: $id');
          return null;
        }
      } else {
        print('Error al obtener gasto. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de red al obtener gasto: $e');
      return null;
    }
  }

  // 3. Insertar nuevo gasto
  // POST /api/gasto
  static Future<bool> crear({
    required String emailUsuario,
    required dynamic idInventario,
    required dynamic idTienda, // 👈 Nuevo parámetro obligatorio
    required double monto,
    required String descripcion,
    required String usuarioCreacion,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/gasto');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email_usuario': emailUsuario,
          'id_inventario': idInventario,
          'id_tienda': idTienda, // 👈 Se envía al backend
          'monto': monto,
          'descripcion': descripcion.trim(),
          'usuario_creacion': usuarioCreacion,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error al crear gasto. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al crear gasto: $e');
      return false;
    }
  }

  // 4. Editar gasto
  // PUT /api/gasto/:id
  static Future<bool> actualizar({
    required String id,
    required String emailUsuario,
    required dynamic idTienda, // 👈 Nuevo parámetro obligatorio
    required double monto,
    required String descripcion,
    required String usuarioCreacion,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/gasto/${Uri.encodeComponent(id)}',
      );

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email_usuario': emailUsuario,
          'id_tienda': idTienda, // 👈 Se envía al backend
          'monto': monto,
          'descripcion': descripcion.trim(),
          'usuario_creacion': usuarioCreacion,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
            'Error al actualizar gasto. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al actualizar gasto: $e');
      return false;
    }
  }

  // 5. Eliminar gasto (Baja lógica)
  // DELETE /api/gasto/:id
  static Future<bool> eliminar(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/gasto/${Uri.encodeComponent(id)}',
      );

      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al eliminar gasto. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al eliminar gasto: $e');
      return false;
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/API/api_service.dart';

class ColoresService {
  // 1. Listar colores por ID de inventario
  // GET /api/color/inventario/:id_inventario
  static Future<List<Map<String, dynamic>>> obtenerPorInventario(String idInventario) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/color/inventario/${Uri.encodeComponent(idInventario)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error al listar colores. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error de red al listar colores: $e');
      return [];
    }
  }

  // 2. Buscar color por ID
  // GET /api/color/:id
  static Future<Map<String, dynamic>?> obtenerPorId(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/color/${Uri.encodeComponent(id)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          return data.first as Map<String, dynamic>;
        } else {
          print('No se encontró color con ID: $id');
          return null;
        }
      } else {
        print('Error al obtener color. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de red al obtener color: $e');
      return null;
    }
  }

  // 3. Insertar nuevo color
  // POST /api/color
  static Future<bool> crear({
    required String emailUsuario,
    required dynamic idInventario,
    required String nombre,
    required String usuarioCreacion,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/color');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email_usuario': emailUsuario,
          'id_inventario': idInventario,
          'nombre': nombre,
          'usuario_creacion': usuarioCreacion,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print('Error al crear color. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al crear color: $e');
      return false;
    }
  }

  // 4. Editar color
  // PUT /api/color/:id
  static Future<bool> actualizar({
    required String id,
    required String emailUsuario,
    required String nombre,
    required String usuarioCreacion,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/color/${Uri.encodeComponent(id)}',
      );

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email_usuario': emailUsuario,
          'nombre': nombre,
          'usuario_creacion': usuarioCreacion,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al actualizar color. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al actualizar color: $e');
      return false;
    }
  }

  // 5. Eliminar color (Baja lógica o física)
  // DELETE /api/color/:id
  static Future<bool> eliminar(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/color/${Uri.encodeComponent(id)}',
      );

      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al eliminar color. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al eliminar color: $e');
      return false;
    }
  }
}
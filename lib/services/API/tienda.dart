import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/API/api_service.dart';

class TiendaService {
  // 1. Listar tiendas por ID de inventario
  // GET /api/tienda/inventario/:id_inventario
  static Future<List<Map<String, dynamic>>> obtenerPorInventario(String idInventario) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/tienda/inventario/${Uri.encodeComponent(idInventario)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error al listar tiendas. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error de red al listar tiendas: $e');
      return [];
    }
  }

  // 2. Buscar tienda por ID
  // GET /api/tienda/:id
  static Future<Map<String, dynamic>?> obtenerPorId(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/tienda/${Uri.encodeComponent(id)}',
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
          print('No se encontró tienda con ID: $id');
          return null;
        }
      } else {
        print('Error al obtener tienda. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de red al obtener tienda: $e');
      return null;
    }
  }

  // 3. Insertar nueva tienda
  // POST /api/tienda
  static Future<bool> crear({
    required String emailUsuario,
    required dynamic idInventario,
    required String nombre,
    required String usuarioCreacion,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/tienda');

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
        print('Error al crear tienda. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al crear tienda: $e');
      return false;
    }
  }

  // 4. Editar tienda
  // PUT /api/tienda/:id
  static Future<bool> actualizar({
    required String id,
    required String emailUsuario,
    required String nombre,
    required String usuarioCreacion,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/tienda/${Uri.encodeComponent(id)}',
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
        print('Error al actualizar tienda. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al actualizar tienda: $e');
      return false;
    }
  }

  // 5. Eliminar tienda (Baja lógica)
  // DELETE /api/tienda/:id
  static Future<bool> eliminar(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/tienda/${Uri.encodeComponent(id)}',
      );

      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error al eliminar tienda. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al eliminar tienda: $e');
      return false;
    }
  }
}
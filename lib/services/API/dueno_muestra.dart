
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/API/api_service.dart';

class DuenoMuestraService {
  // 1. Listar dueños de muestra por ID de inventario
  // GET /api/dueno_muestra/inventario/:id_inventario
  static Future<List<Map<String, dynamic>>> obtenerPorInventario(String idInventario) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/dueno_muestra/inventario/${Uri.encodeComponent(idInventario)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Dueños de muestra obtenidos exitosamente: ${data.length} registros');
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error al listar dueños de muestra. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error de red al listar dueños de muestra: $e');
      return [];
    }
  }

  // 2. Buscar dueño de muestra por ID
  // GET /api/dueno_muestra/:id
  static Future<Map<String, dynamic>?> obtenerPorId(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/dueno_muestra/${Uri.encodeComponent(id)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          print('Dueño de muestra encontrado');
          return data.first as Map<String, dynamic>;
        } else {
          print('No se encontró dueño de muestra con ID: $id');
          return null;
        }
      } else {
        print('Error al obtener dueño de muestra. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de red al obtener dueño de muestra: $e');
      return null;
    }
  }

  // 3. Insertar nuevo dueño de muestra
  // POST /api/dueno_muestra
  static Future<bool> crear({
    required String emailUsuario,
    required dynamic idInventario,
    required String nombre,
    required String usuarioCreacion,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/dueno_muestra');

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
        print('Dueño de muestra registrado exitosamente');
        return true;
      } else {
        print('Error al crear dueño de muestra. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al crear dueño de muestra: $e');
      return false;
    }
  }

  // 4. Editar dueño de muestra
  // PUT /api/dueno_muestra/:id
  static Future<bool> actualizar({
    required String id,
    required String emailUsuario,
    required String nombre,
    required String usuarioCreacion,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/dueno_muestra/${Uri.encodeComponent(id)}',
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
        print('Dueño de muestra actualizado exitosamente');
        return true;
      } else {
        print('Error al actualizar dueño de muestra. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al actualizar dueño de muestra: $e');
      return false;
    }
  }

  // 5. Eliminar dueño de muestra (Baja lógica)
  // DELETE /api/dueno_muestra/:id
  static Future<bool> eliminar(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/dueno_muestra/${Uri.encodeComponent(id)}',
      );

      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('Dueño de muestra eliminado correctamente');
        return true;
      } else {
        print('Error al eliminar dueño de muestra. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al eliminar dueño de muestra: $e');
      return false;
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/API/api_service.dart';

class TipoCalzadoService {
  // 1. Obtener la lista de tipos de calzado activos por ID de inventario
  // GET /api/tipo_calzado/inventario/:id_inventario
  static Future<List<Map<String, dynamic>>> obtenerPorInventario(
    String idInventario,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/tipo_calzado/inventario/${Uri.encodeComponent(idInventario)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error al listar tipos de calzado. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error de red al listar tipos de calzado: $e');
      return [];
    }
  }

  // 2. Obtener un tipo de calzado por ID
  // GET /api/tipo_calzado/:id
  static Future<Map<String, dynamic>?> obtenerPorId(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/tipo_calzado/${Uri.encodeComponent(id)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error de red al obtener tipo de calzado por ID: $e');
      return null;
    }
  }

  // 3. Crear nuevo tipo de calzado
  // POST /api/tipo_calzado
  static Future<bool> crear({
    required String nombre,
    required String? icono,
    required String usuarioCreacion,
    required String emailUsuario,
    required bool taco,
    required bool plataforma,
    required bool colores,
    required String idInventario,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/tipo_calzado');

      final body = json.encode({
        'nombre': nombre,
        'icono': icono,
        'usuario_creacion': usuarioCreacion,
        'email_usuario': emailUsuario,
        'taco': taco,
        'plataforma': plataforma,
        'colores': colores,
        'id_inventario': idInventario,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error de red al crear tipo de calzado: $e');
      return false;
    }
  }

  // 4. Actualizar tipo de calzado existente por ID
  // PUT /api/tipo_calzado/:id
  static Future<bool> actualizar({
    required String id,
    required String nombre,
    required String? icono,
    required String usuarioCreacion,
    required String emailUsuario,
    required bool taco,
    required bool plataforma,
    required bool colores,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/tipo_calzado/${Uri.encodeComponent(id)}',
      );

      final body = json.encode({
        'nombre': nombre,
        'icono': icono,
        'usuario_creacion': usuarioCreacion,
        'email_usuario': emailUsuario,
        'taco': taco,
        'plataforma': plataforma,
        'colores': colores,
      });

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error de red al actualizar tipo de calzado: $e');
      return false;
    }
  }

  // 5. Eliminar tipo de calzado (Baja lógica: activo = false)
  // DELETE /api/tipo_calzado/:id
  static Future<bool> eliminar(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/tipo_calzado/${Uri.encodeComponent(id)}',
      );

      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error de red al eliminar tipo de calzado: $e');
      return false;
    }
  }
  // Obtener la lista completa de tipos de calzado por ID de inventario (activos e inactivos)
  // GET /api/tipo_calzado/inventario/:id_inventario/todos
  static Future<List<Map<String, dynamic>>> obtenerTodosPorInventario(
    String idInventario,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/tipo_calzado/inventario/${Uri.encodeComponent(idInventario)}/todos',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error al listar todos los tipos de calzado. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error de red al listar todos los tipos de calzado: $e');
      return [];
    }
  }
}
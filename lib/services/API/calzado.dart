import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/API/api_service.dart';

class CalzadoService {
  // 1. Obtener la lista de calzados activos por ID de inventario
  // GET /api/calzado/inventario/:id_inventario
  static Future<List<Map<String, dynamic>>> obtenerPorInventario(
  dynamic idInventario,
) async {
  try {
    if (idInventario == null) return [];
    
    // Lo convertimos siempre a String de forma segura
    final String idStr = idInventario.toString();
    
    final url = Uri.parse(
      '${ApiService.baseUrl}/api/calzado/inventario/${Uri.encodeComponent(idStr)}',
    );

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      print('Error al listar calzados. Status code: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error de red al listar calzados: $e');
    return [];
  }
}

  static Future<List<Map<String, dynamic>>> obtenerPorInventarioUpdate(
  dynamic idInventario,
) async {
  try {
    if (idInventario == null) return [];
    
    // Lo convertimos siempre a String de forma segura
    final String idStr = idInventario.toString();
    
    final url = Uri.parse(
      '${ApiService.baseUrl}/api/calzado/inventario/update/${Uri.encodeComponent(idStr)}',
    );

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      print('Error al listar calzados. Status code: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error de red al listar calzados: $e');
    return [];
  }
}

  // 1.b. Obtener la lista de calzados activos con colores = true por ID de inventario
  // GET /api/calzado/inventario/:id_inventario/colores
  static Future<List<Map<String, dynamic>>> obtenerPorInventarioConColores(
    String? idInventario,
  ) async {
    try {
      final idStr = idInventario.toString();
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/calzado/inventario/${Uri.encodeComponent(idStr)}/colores',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error al listar calzados con colores. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error de red al listar calzados con colores: $e');
      return [];
    }
  }

  // 2. Obtener un calzado por ID
  // GET /api/calzado/:id
  static Future<Map<String, dynamic>?> obtenerPorId(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/calzado/${Uri.encodeComponent(id)}',
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
      print('Error de red al obtener calzado por ID: $e');
      return null;
    }
  }

  // 3. Crear nuevo calzado
  // POST /api/calzado
  static Future<bool> crear({
    required String nombre,
    required String icono,
    required double precioReal,
    required bool taco,
    required bool plataforma,
    required bool colores,
    required dynamic idTipoCalzado,
    required String? usuarioCreacion,
    required String? emailUsuario,
    required dynamic idInventario,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/calzado');

      final body = json.encode({
        'nombre': nombre,
        'icono': icono,
        'precio_real': precioReal,
        'taco': taco,
        'plataforma': plataforma,
        'colores': colores,
        'id_tipo_calzado': idTipoCalzado,
        'usuario_creacion': usuarioCreacion,
        'email_usuario': emailUsuario,
        'id_inventario': idInventario,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error de red al crear calzado: $e');
      return false;
    }
  }

  // 4. Actualizar calzado existente por ID
  // PUT /api/calzado/:id
  static Future<bool> actualizar({
    required String id,
    required String nombre,
    required String icono,
    required double precioReal,
    required bool taco,
    required bool plataforma,
    required bool colores,
    required dynamic idTipoCalzado,
    required String? usuarioCreacion,
    required String? emailUsuario,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/calzado/${Uri.encodeComponent(id)}',
      );

      final body = json.encode({
        'nombre': nombre,
        'icono': icono,
        'precio_real': precioReal,
        'taco': taco,
        'plataforma': plataforma,
        'colores': colores,
        'id_tipo_calzado': idTipoCalzado,
        'usuario_creacion': usuarioCreacion,
        'email_usuario': emailUsuario,
      });

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error de red al actualizar calzado: $e');
      return false;
    }
  }

  // 5. Eliminar calzado (Baja lógica: activo = false)
  // DELETE /api/calzado/:id
  static Future<bool> eliminar(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/calzado/${Uri.encodeComponent(id)}',
      );

      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error de red al eliminar calzado: $e');
      return false;
    }
  }
}
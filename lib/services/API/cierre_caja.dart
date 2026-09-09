import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/API/api_service.dart';

class CierreCajaService {
  // 1. Ejecutar cierre de caja por Correo
  // POST /api/cierre_caja/correo
  static Future<Map<String, dynamic>?> cerrarPorCorreo({
    required String fecha,
    required String emailUser,
    required String usuario,
    required dynamic idInventario,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/cierre_caja/correo');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fecha': fecha,
          'email_user': emailUser,
          'usuario': usuario,
          'id_inventario': idInventario,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        print(
            'Error al realizar cierre por correo. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de red al realizar cierre por correo: $e');
      return null;
    }
  }

  // 2. Ejecutar cierre de caja por ID de Tienda
  // POST /api/cierre_caja/tienda
  static Future<Map<String, dynamic>?> cerrarPorTienda({
    required String fecha,
    required dynamic idTienda,
    required String usuario,
    required dynamic idInventario,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/cierre_caja/tienda');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fecha': fecha,
          'id_tienda': idTienda,
          'usuario': usuario,
          'id_inventario': idInventario,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        print(
            'Error al realizar cierre por tienda. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de red al realizar cierre por tienda: $e');
      return null;
    }
  }

  // 3. Obtener la lista general de todos los cierres de caja (Para la primera vista)
  // GET /api/cierre_caja/listar
  static Future<List<Map<String, dynamic>>> obtenerHistorialCierres(
      String inventarioId) async {
    try {
      final url = Uri.parse(
          '${ApiService.baseUrl}/api/cierre_caja/listar?id_inventario=$inventarioId');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print(
            'Error al listar el historial de cierres. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error de red al listar historial de cierres: $e');
      return [];
    }
  }

  // 4. Obtener correos asociados a un inventario específico
  // GET /api/cierre_caja/inventario/:id
  static Future<List<Map<String, dynamic>>> obtenerCorreosPorInventario(
      dynamic idInventario) async {
    try {
      final url = Uri.parse(
          '${ApiService.baseUrl}/api/cierre_caja/inventario/$idInventario');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print(
            'Error al obtener correos por inventario. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error de red al obtener correos por inventario: $e');
      return [];
    }
  }

  // 5. Obtener toda la información de un cierre de caja por su ID específico
  // GET /api/cierre_caja/detalle/:id
  static Future<Map<String, dynamic>?> obtenerCierrePorId(
      dynamic idCierreCaja) async {
    try {
      final url = Uri.parse(
          '${ApiService.baseUrl}/api/cierre_caja/detalle/$idCierreCaja');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        print(
            'Error al obtener el cierre de caja por ID. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de red al obtener el cierre de caja por ID: $e');
      return null;
    }
  }
}

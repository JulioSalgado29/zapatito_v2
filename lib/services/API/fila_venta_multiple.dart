import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/API/api_service.dart';

class FilaVentaMultipleService {
  // 1. Obtener catálogo de calzados por ID de inventario
  // GET /api/fila_venta_multiple/calzados/:id_inventario
  static Future<List<Map<String, dynamic>>> obtenerCalzados(
    dynamic idInventario,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/fila_venta_multiple/calzados/${Uri.encodeComponent(idInventario.toString())}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error al obtener calzados. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error de red al obtener calzados: $e');
      return [];
    }
  }

  // 2. Consultar stock y opciones disponibles en cascada
  // GET /api/fila_venta_multiple/stock-cascada/:id_calzado/:id_inventario?talla=...&colores=...&taco=...
  static Future<Map<String, dynamic>?> consultarStockCascada({
    required dynamic idInventario,
    dynamic idCalzado,
    int? talla,
    String? colores,
    int? taco,
    String? plataforma, // <--- Nuevo parámetro agregado
  }) async {
    try {
      final intIdInventario = int.tryParse(idInventario?.toString() ?? '');

      if (intIdInventario == null) {
        print('Error en Flutter: idInventario ($idInventario) no es válido.');
        return null;
      }

      final queryParams = <String, String>{};

      // Si ya hay un calzado seleccionado, lo agregamos como queryParam
      if (idCalzado != null && idCalzado.toString() != 'null') {
        queryParams['id_calzado'] = idCalzado.toString();
      }
      if (talla != null) queryParams['talla'] = talla.toString();
      if (colores != null && colores.trim().isNotEmpty) queryParams['colores'] = colores.trim();
      if (taco != null) queryParams['taco'] = taco.toString();
      if (plataforma != null && plataforma.trim().isNotEmpty) queryParams['plataforma'] = plataforma.trim();

      final uri = Uri.parse(
        '${ApiService.baseUrl}/api/fila_venta_multiple/stock-cascada/$intIdInventario',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);


      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        print('Error al consultar stock en cascada. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error de red al consultar stock en cascada: $e');
      return null;
    }
  }
  // 3. Registrar Venta Múltiple en lote (Batch)
  // POST /api/fila_venta_multiple/batch
  static Future<bool> registrarVentaMultiple({
    required dynamic idInventario,
    required String usuarioCreacion,
    required String emailUser,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/fila_venta_multiple/batch',
      );

      final payload = {
        'id_inventario': idInventario,
        'usuario_creacion': usuarioCreacion,
        'email_user': emailUser,
        'items': items,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Venta múltiple registrada exitosamente en backend.');
        return true;
      } else {
        print('Error al registrar venta múltiple. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al registrar venta múltiple: $e');
      return false;
    }
  }
}
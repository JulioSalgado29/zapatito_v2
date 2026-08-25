import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:zapatito_v2/services/API/api_service.dart';

class FilaVentaService {
  // 1. Listar filas de venta por ID de inventario y fecha opcional
  // GET /api/fila_venta/inventario/:id_inventario?fecha=YYYY-MM-DD
  static Future<List<Map<String, dynamic>>> obtenerPorInventario(
    String idInventario, {
    DateTime? fechaFiltro,
  }) async {
    try {
      String queryParams = '';

      if (fechaFiltro != null) {
        // Aseguramos que la fecha enviada sea la fecha local
        String fechaFormateada =
            DateFormat('yyyy-MM-dd').format(fechaFiltro.toLocal());
        queryParams = '?fecha=$fechaFormateada';
      }
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/fila_venta/inventario/${Uri.encodeComponent(idInventario)}$queryParams',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print(
            'Filas de venta obtenidas exitosamente: ${data.length} registros');
        return List<Map<String, dynamic>>.from(data);
      } else {
        print(
            'Error al listar filas de venta. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error de red al listar filas de venta: $e');
      return [];
    }
  }

  // 2. Eliminar fila de venta o muestra con reversa de stock
  // DELETE /api/fila_venta/:id_fila_venta
  static Future<bool> eliminarConReversa({
    required dynamic idFilaVenta,
    required bool esMuestra,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/fila_venta/${Uri.encodeComponent(idFilaVenta.toString())}',
      );

      final response = await http.delete(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'esMuestra': esMuestra,
          'data': data,
        }),
      );

      if (response.statusCode == 200) {
        print('Eliminación y reversa procesadas con éxito');
        return true;
      } else {
        print(
            'Error al eliminar fila de venta. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al eliminar fila de venta: $e');
      return false;
    }
  }

  // 3. Crear venta / muestra
  // POST /api/fila_venta
  static Future<bool> crearVenta(Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/fila_venta');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Venta/muestra registrada exitosamente');
        return true;
      } else {
        print('Error al crear venta. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al crear venta: $e');
      return false;
    }
  }

  // 4. Editar venta / muestra existente
  // PUT /api/fila_venta/:id_fila_venta
  static Future<bool> editarVenta({
    required dynamic idFilaVenta,
    required Map<String, dynamic> data,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/fila_venta/${Uri.encodeComponent(idFilaVenta.toString())}',
      );

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        print('Venta/muestra actualizada exitosamente');
        return true;
      } else {
        print('Error al editar venta. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al editar venta: $e');
      return false;
    }
  }
}

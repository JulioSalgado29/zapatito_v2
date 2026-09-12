import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/services/API/api_service.dart';

class StockService {
  // 1. Filtrar Inventario (Cabecera y Detalle)
  // POST /api/inventario/filtrar
  static Future<Map<String, dynamic>> filtrarInventario({
    
    List<int> idsCalzado = const [],
    List<int> idsColor = const [],
    List<int> tallas = const [],
    String plataforma = '0',
    List<int> tacos = const [],
    required int idInventario,
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/stock/filtrar');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'p_ids_calzado': idsCalzado,
          'p_ids_color': idsColor,
          'p_tallas': tallas,
          'p_plataforma': plataforma,
          'p_tacos': tacos,
          'p_inventario_id': idInventario,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'cabecera': List<Map<String, dynamic>>.from(data['cabecera'] ?? []),
          'detalle': List<Map<String, dynamic>>.from(data['detalle'] ?? []),
        };
      } else {
        print('Error al filtrar inventario. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return {'cabecera': [], 'detalle': []};
      }
    } catch (e) {
      print('Error de red al filtrar inventario: $e');
      return {'cabecera': [], 'detalle': []};
    }
  }

  // 2. Filtrar Calzado con Imágenes y Colores
  // POST /api/inventario/imagenes-filtradas
  static Future<List<Map<String, dynamic>>> obtenerCalzadoImagenesFiltradas({
    required int idInventario,
    List<int> idsColor = const [],
    List<int> idsCalzado = const [],
  }) async {
    try {
      final url = Uri.parse('${ApiService.baseUrl}/api/stock/imagenes-filtradas');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'p_inventario_id': idInventario,
          'p_ids_color': idsColor,
          'p_ids_calzado': idsCalzado,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        print('Error al obtener imágenes filtradas. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error de red al obtener imágenes filtradas: $e');
      return [];
    }
  }
}
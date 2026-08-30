import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zapatito_v2/main-widgets/MAIN/home_page.dart';
import 'package:zapatito_v2/services/API/api_service.dart';

class InventarioService {
  // Petición GET para verificar si existe un inventario por su ID
  static Future<bool> verificarInventarioExiste(String id) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/api/inventario/${Uri.encodeComponent(id)}',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        if (data is bool) {
          print('Verificación de inventario exitosa: $data');
          return data;
        } else {
          print('Formato de respuesta inesperado: $data');
          return false;
        }
      } else {
        print('Error al verificar inventario. Status code: ${response.statusCode}');
        print('Respuesta del servidor: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error de red al verificar inventario: $e');
      return false;
    }
  }

  // 🔹 MÉTODO REUTILIZABLE: Verifica la existencia y redirige si no existe
  static Future<void> validarYRedirigir(BuildContext context, String? id) async {
    try {
      final bool existe = await verificarInventarioExiste(id ?? '');

      if (!existe && context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false, // Elimina todas las rutas anteriores
                );
      }
    } catch (e) {
      print("Error al verificar el ID del inventario: $e");
    }
  }
}
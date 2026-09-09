import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/widgets.dart';

// ==========================================
// VISTA: cierre_caja_form (Widget independiente para cursores)
// ==========================================
class CierreCajaForm extends StatelessWidget {
  final dynamic datosRespuesta;

  const CierreCajaForm({super.key, required this.datosRespuesta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain('Detalle de Cierre (Cursores)'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: datosRespuesta == null
            ? const Center(child: Text('No hay datos disponibles.'))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de la respuesta del servidor:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: SelectableText(
                        const JsonEncoder.withIndent('  ').convert(datosRespuesta),
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Volver a Cierre de Caja'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

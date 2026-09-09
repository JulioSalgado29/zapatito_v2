import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/widgets.dart';

// ==========================================
// VISTA: cierre_caja_form (Diseño Minimalista & Elegante en Tonos Claros)
// ==========================================
class CierreCajaForm extends StatelessWidget {
  final dynamic datosRespuesta;

  const CierreCajaForm({super.key, required this.datosRespuesta});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = {};
    if (datosRespuesta is Map) {
      data = Map<String, dynamic>.from(datosRespuesta);
    } else if (datosRespuesta is String) {
      try {
        data = jsonDecode(datosRespuesta);
      } catch (_) {}
    }

    final resumenFinanciero = (data['resumen_financiero'] is List &&
            (data['resumen_financiero'] as List).isNotEmpty)
        ? data['resumen_financiero'][0]
        : (data['resumen_financiero'] ?? data);

    final List calzadosCantidad = data['calzado_cantidad'] ?? [];
    final List metodosPago = data['metodo_pago'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: Designwidgets().appBarMain('Panel de Cierre'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF1F5F9),
              Color(0xFFF8FAFC),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: datosRespuesta == null
            ? const Center(
                child: Text(
                  'No hay telemetría de cierre disponible.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(resumenFinanciero),
                    const SizedBox(height: 24),
                    _buildMetricsGrid(resumenFinanciero),
                    const SizedBox(height: 24),
                    if (metodosPago.isNotEmpty) ...[
                      _buildSectionTitle('Flujo por Método de Pago',
                          Icons.account_balance_wallet_rounded),
                      const SizedBox(height: 12),
                      _buildPaymentMethodsList(metodosPago),
                      const SizedBox(height: 24),
                    ],
                    if (calzadosCantidad.isNotEmpty) ...[
                      _buildSectionTitle(
                          'Demanda de Calzado', Icons.local_mall_rounded),
                      const SizedBox(height: 12),
                      _buildShoesList(calzadosCantidad),
                      const SizedBox(height: 24),
                    ],
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0EA5E9).withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0EA5E9),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text(
                            'REGRESAR AL SISTEMA',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeroHeader(dynamic res) {
    final nombreCierre = res['nombre'] ?? 'Cierre General';
    final usuario = res['usuario_creacion'] ?? 'Sistema';

    // Función nativa para obtener la fecha y hora actual del sistema en formato limpio (YYYY-MM-DD HH:mm:ss)
    final now = DateTime.now();
    final fechaHoraActual = "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        fechaHoraActual,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            nombreCierre.toString().toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.verified_user_rounded,
                  size: 14, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Text(
                'Operador: $usuario',
                style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(dynamic res) {
    final ingresos = res['ingresos_totales'] ?? 0;
    final gastos = res['total_gastos'] ?? 0;
    final utilidad = res['utilidad_total_dia'] ?? 0;
    final pares = res['total_calzados_vendidos'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.45,
      children: [
        _buildMetricCard(
            'Ingresos Totales',
            'S/. $ingresos',
            Icons.trending_up_rounded,
            const Color(0xFF10B981),
            const Color(0xFFECFDF5)),
        _buildMetricCard('Utilidad Neta', 'S/. $utilidad', Icons.bolt_rounded,
            const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
        _buildMetricCard(
            'Gastos Operativos',
            'S/. $gastos',
            Icons.trending_down_rounded,
            const Color(0xFFEF4444),
            const Color(0xFFFEF2F2)),
        _buildMetricCard(
            'Pares Vendidos',
            '$pares Unid.',
            Icons.shopping_bag_rounded,
            const Color(0xFF8B5CF6),
            const Color(0xFFF5F3FF)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon,
      Color accentColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0284C7), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodsList(List methods) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: methods.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Color(0xFFF1F5F9), height: 1),
        itemBuilder: (context, index) {
          final item = methods[index];
          final metodo = item['metodo_pago'] ?? 'Desconocido';
          final cantidad = item['cantidad'] ?? 0;
          final total = item['total_recaudado'] ?? 0;

          return ListTile(
            dense: true,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE0F2FE),
              child: Icon(Icons.payment_rounded,
                  color: Color(0xFF0284C7), size: 16),
            ),
            title: Text(
              metodo.toString().toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            subtitle: Text(
              '$cantidad transacciones',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
            trailing: Text(
              'S/. $total',
              style: const TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w800,
                  fontSize: 14),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShoesList(List shoes) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: shoes.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Color(0xFFF1F5F9), height: 1),
        itemBuilder: (context, index) {
          final item = shoes[index];
          final nombre = item['calzado_nombre'] ?? 'Modelo desconocido';
          final cantidad = item['cantidad_vendida'] ?? 0;

          return ListTile(
            dense: true,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_bag_outlined,
                  color: Color(0xFF9333EA), size: 16),
            ),
            title: Text(
              nombre,
              style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$cantidad un.',
                style: const TextStyle(
                    color: Color(0xFF9333EA),
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}

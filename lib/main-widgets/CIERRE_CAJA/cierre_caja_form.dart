import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/widgets.dart';

// ==========================================
// VISTA: cierre_caja_form (Diseño Minimalista & Elegante con todos los cursores)
// ==========================================
class CierreCajaForm extends StatefulWidget {
  final dynamic datosRespuesta;

  const CierreCajaForm({super.key, required this.datosRespuesta});

  @override
  State<CierreCajaForm> createState() => _CierreCajaFormState();
}

class _CierreCajaFormState extends State<CierreCajaForm>
    with SingleTickerProviderStateMixin {
  bool _mostrarUtilidad = false; // Estado para ocultar/mostrar la utilidad neta

  late AnimationController _goldController;
  late Animation<Color?> _goldColorAnimation;

  @override
  void initState() {
    super.initState();
    _goldController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _goldColorAnimation = ColorTween(
      begin: Colors.white,
      end: const Color.fromARGB(255, 229, 191, 4),
    ).animate(CurvedAnimation(
      parent: _goldController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _goldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = {};
    if (widget.datosRespuesta is Map) {
      data = Map<String, dynamic>.from(widget.datosRespuesta);
    } else if (widget.datosRespuesta is String) {
      try {
        data = jsonDecode(widget.datosRespuesta);
      } catch (_) {}
    }

    // Extracción segura del resumen financiero
    final dynamic rawResumen = data['resumen_financiero'];
    final Map<String, dynamic> resumenFinanciero = (rawResumen is List)
        ? (rawResumen.isNotEmpty && rawResumen[0] is Map
            ? Map<String, dynamic>.from(rawResumen[0])
            : {})
        : (rawResumen is Map
            ? Map<String, dynamic>.from(rawResumen)
            : (data.isNotEmpty ? data : {}));

    // Listas adicionales correspondientes a los cursores del SP
    final List calzadosCantidad = data['calzado_cantidad'] ?? [];
    final List detalleCaracteristicas = data['detalle_caracteristicas'] ?? [];
    final List tipoCalzado = data['tipo_calzado'] ?? [];
    final List metodosPago = data['metodo_pago'] ?? [];

    // Validar si realmente no hay información o movimiento registrado en ningún cursor
    final bool sinMovimientos = resumenFinanciero.isEmpty ||
        ((resumenFinanciero['ingresos_totales'] ?? 0) == 0 &&
            (resumenFinanciero['total_gastos'] ?? 0) == 0 &&
            (resumenFinanciero['total_calzados_vendidos'] ?? 0) == 0 &&
            calzadosCantidad.isEmpty &&
            detalleCaracteristicas.isEmpty &&
            tipoCalzado.isEmpty &&
            metodosPago.isEmpty);

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
        child: widget.datosRespuesta == null
            ? const Center(
                child: Text(
                  'No hay telemetría de cierre disponible.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                ),
              )
            : sinMovimientos
                ? _buildEmptyStateView(context)
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
                        if (tipoCalzado.isNotEmpty) ...[
                          _buildSectionTitle('Ventas por Tipo de Calzado',
                              Icons.category_rounded),
                          const SizedBox(height: 12),
                          _buildTipoCalzadoList(tipoCalzado),
                          const SizedBox(height: 24),
                        ],
                        if (calzadosCantidad.isNotEmpty) ...[
                          _buildSectionTitle(
                              'Demanda de Calzado', Icons.local_mall_rounded),
                          const SizedBox(height: 12),
                          _buildShoesList(calzadosCantidad),
                          const SizedBox(height: 24),
                        ],
                        if (detalleCaracteristicas.isNotEmpty) ...[
                          _buildSectionTitle('Detalle de Características',
                              Icons.rule_folder_rounded),
                          const SizedBox(height: 12),
                          _buildDetalleCaracteristicasList(
                              detalleCaracteristicas),
                          const SizedBox(height: 24),
                        ],
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF0EA5E9).withOpacity(0.2),
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

  Widget _buildEmptyStateView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE0F2FE),
                    Color(0xFFBAE6FD),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'SIN MOVIMIENTOS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 300,
              child: Text(
                'No se registraron movimientos operativos ni comerciales en este cierre de caja.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: 260,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF0EA5E9).withOpacity(0.4),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: const Text(
                  'REGRESAR',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(Map<String, dynamic> res) {
    final nombreCierre = res['nombre'] ?? 'Cierre General';
    final usuario = res['usuario_creacion'] ?? 'Sistema';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0284C7),
            Color(0xFF0369A1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'CIERRE DE CAJA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _goldColorAnimation,
            builder: (context, child) {
              return Text(
                nombreCierre.toString().toUpperCase(),
                style: TextStyle(
                  color: _goldColorAnimation.value,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.account_circle_rounded,
                size: 16,
                color: Color(0xFFBAE6FD),
              ),
              const SizedBox(width: 6),
              Text(
                'Operador: $usuario',
                style: const TextStyle(
                  color: Color(0xFFBAE6FD),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> res) {
    final ingresos = res['ingresos_totales'] ?? 0;
    final gastos = res['total_gastos'] ?? 0;
    final utilidad = res['utilidad_total_dia'] ?? 0;
    final pares = res['total_calzados_vendidos'] ?? 0;

    final String valorUtilidad =
        _mostrarUtilidad ? 'S/. $utilidad' : 'S/. ****';

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
        _buildMetricCardWithToggle(
            'Utilidad Neta',
            valorUtilidad,
            Icons.bolt_rounded,
            const Color(0xFF0284C7),
            const Color(0xFFE0F2FE),
            _mostrarUtilidad, () {
          setState(() {
            _mostrarUtilidad = !_mostrarUtilidad;
          });
        }),
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

  // Tarjeta de Utilidad Neta con rayito arriba y ojito abajo
  Widget _buildMetricCardWithToggle(String title, String value, IconData icon,
      Color accentColor, Color bgColor, bool isVisible, VoidCallback onToggle) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    isVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: const Color(0xFF64748B),
                    size: 18,
                  ),
                ),
              ),
            ],
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

  Widget _buildTipoCalzadoList(List tipos) {
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
        itemCount: tipos.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Color(0xFFF1F5F9), height: 1),
        itemBuilder: (context, index) {
          final item = tipos[index];
          final tipo = item['tipo_calzado'] ?? 'Desconocido';
          final cantidad = item['cantidad_vendida'] ?? 0;

          return ListTile(
            dense: true,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFEF3C7),
              child: Icon(Icons.category_rounded,
                  color: Color(0xFFD97706), size: 16),
            ),
            title: Text(
              tipo.toString().toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$cantidad un.',
                style: const TextStyle(
                    color: Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
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

  Widget _buildDetalleCaracteristicasList(List detalles) {
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
        itemCount: detalles.length,
        separatorBuilder: (_, __) =>
            const Divider(color: Color(0xFFF1F5F9), height: 1),
        itemBuilder: (context, index) {
          final item = detalles[index];
          final nombre = item['nombre_calzado'] ?? 'Calzado';
          final talla = item['talla'] ?? '-';
          final taco = item['taco'] ?? '-';
          final plataforma = item['plataforma'] ?? '-';
          final colores = item['colores'] ?? '-';
          final cantidad = item['cantidad'] ?? 0;

          return ListTile(
            dense: true,
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFCCFBF1),
              child:
                  Icon(Icons.style_rounded, color: Color(0xFF0F766E), size: 16),
            ),
            title: Text(
              nombre,
              style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            subtitle: Text(
              'Talla: $talla | Taco: $taco | Plat.: $plataforma | Color: $colores',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$cantidad un.',
                style: const TextStyle(
                    color: Color(0xFF0F766E),
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

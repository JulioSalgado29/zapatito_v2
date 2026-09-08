import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/VENTA/venta_form_page.dart';
import 'package:zapatito_v2/main-widgets/VENTA/venta_form_page_muestra.dart';
import 'package:zapatito_v2/main-widgets/VENTA/venta_form_page_multiple.dart';
import 'package:zapatito_v2/services/API/fila_venta.dart';
import 'package:zapatito_v2/services/API/inventario.dart';

class VentaPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  const VentaPage(
      {super.key, this.firstName, this.emailUser, this.inventarioId});

  @override
  State<VentaPage> createState() => _VentaPageState();
}

class _VentaPageState extends State<VentaPage> {
  DateTime _fechaFiltro = DateTime.now();

  // 🔹 Estado de Carga / Data local
  bool _isLoading = true;
  bool _isFetchingVentas = false;
  List<Map<String, dynamic>> _ventas = [];

  // 🔹 Controladores y variables para el Buscador y Filtros Ocultos
  bool _mostrarFiltros = false; // Estado del panel colapsable
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _vendedorController = TextEditingController();
  final TextEditingController _tiendaController = TextEditingController();

  String _searchQuery = '';
  String _filtroVendedor = '';
  String _filtroTienda = '';

  @override
  void initState() {
    super.initState();
    _escucharControladores();
    _inicializarPagina();
  }

  void _escucharControladores() {
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _vendedorController.addListener(() {
      setState(() => _filtroVendedor = _vendedorController.text);
    });
    _tiendaController.addListener(() {
      setState(() => _filtroTienda = _tiendaController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _vendedorController.dispose();
    _tiendaController.dispose();
    super.dispose();
  }

  void _limpiarFiltros() {
    setState(() {
      _vendedorController.clear();
      _tiendaController.clear();
      _filtroVendedor = '';
      _filtroTienda = '';
    });
  }

  bool _tieneFiltrosActivos() {
    return _filtroVendedor.isNotEmpty || _filtroTienda.isNotEmpty;
  }

  Future<void> _inicializarPagina() async {
    // Redirección si no hay inventario
    InventarioService.validarYRedirigir(context, widget.inventarioId);

    // Carga inicial de datos una sola vez al entrar a la vista
    if (widget.inventarioId != null) {
      await _cargarVentas();
    }

    // Mantenemos el SplashScreen visible un breve momento para suavizar la transición
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔹 Carga manual de datos al renderizar o tras eventos de cambio
  Future<void> _cargarVentas() async {
    if (widget.inventarioId == null) return;
    if (mounted) setState(() => _isFetchingVentas = true);

    try {
      final data = await FilaVentaService.obtenerPorInventario(
        widget.inventarioId!,
        fechaFiltro: _fechaFiltro,
      );
      if (mounted) {
        setState(() {
          _ventas = data;
          _isFetchingVentas = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ventas = [];
          _isFetchingVentas = false;
        });
      }
    }
  }

  // --- LÓGICA DE ELIMINACIÓN Y REVERSA ---
  Future<void> _eliminarVentaConReversa(
      String filaVentaId, Map<String, dynamic> data) async {
    final bool esMuestra = data['id_dueno_muestra'] != null;

    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            elevation: 20,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [Color.fromARGB(255, 33, 47, 243), Color(0xFF4A5AF7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    esMuestra ? '¿Eliminar muestra?' : '¿Eliminar venta?',
                    style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    esMuestra
                        ? 'Esta acción eliminará el registro de la muestra.'
                        : 'Se devolverá la cantidad vendida al stock del inventario.',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        label: const Text('Cancelar',
                            style: TextStyle(color: Colors.white)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        icon: const Icon(Icons.delete_forever,
                            color: Colors.white),
                        label: const Text('Eliminar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;

    if (!confirm) return;

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const SplashScreen02());

    try {
      final bool exito = await FilaVentaService.eliminarConReversa(
        idFilaVenta: filaVentaId,
        esMuestra: esMuestra,
        data: {
          'id_calzado': data['id_calzado'],
          'id_inventario': widget.inventarioId,
          'cantidad': data['cantidad'],
          'talla': data['talla'],
          'colores': data['colores'] ?? '',
          'taco': data['taco'] ?? 0,
          'plataforma': data['plataforma'] ?? '',
          'email_user': widget.emailUser,
          'usuario_creacion': widget.firstName,
          'id_venta': data['id_venta'],
        },
      );

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (exito) {
        await _cargarVentas(); // Refrescar lista tras eliminar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(esMuestra
                  ? 'Muestra eliminada.'
                  : 'Venta eliminada y stock restaurado.')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Error al procesar la eliminación.')));
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
      }
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFiltro,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _fechaFiltro) {
      setState(() => _fechaFiltro = picked);
      await _cargarVentas();
    }
  }

  String _formatFechaLarga(dynamic timestamp) {
    if (timestamp == null) return 'Sin fecha';
    try {
      final DateTime dt = timestamp is DateTime
          ? timestamp
          : DateTime.parse(timestamp.toString());
      String dia = DateFormat('EEEE', 'es_ES').format(dt);
      String resto = DateFormat("d 'de' MMMM - yyyy", "es_ES").format(dt);
      String hora = DateFormat('hh:mm a').format(dt);
      return "${dia[0].toUpperCase()}${dia.substring(1)} - $resto ($hora)";
    } catch (e) {
      return 'Fecha no válida';
    }
  }

  Widget _buildInputFiltro({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 16, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildContenidoVentas(bool esHoy) {
    if (_isFetchingVentas) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ventas.isEmpty) {
      return Center(
          child: Text(esHoy
              ? 'Aún no hay ventas registradas hoy.'
              : 'No hay ventas para esta fecha.'));
    }

    // 🔹 Lógica de Filtro por Buscador y Filtros Secundarios
    final filas = _ventas.where((fila) {
      // 1. Filtro por nombre de calzado
      final nombreCalzado =
          (fila['calzado_nombre'] ?? '').toString().toLowerCase();
      if (!nombreCalzado.contains(_searchQuery.trim().toLowerCase())) {
        return false;
      }

      // Si no hay filtros secundarios activos, se aprueba
      if (!_tieneFiltrosActivos()) return true;

      // 2. Filtro por Vendedor
      final vendedor =
          (fila['usuario_creacion'] ?? '').toString().toLowerCase();
      final bool coincideVendedor = _filtroVendedor.trim().isEmpty ||
          vendedor.contains(_filtroVendedor.trim().toLowerCase());

      // 3. Filtro por Tienda
      final tienda = (fila['tienda_nombre'] ?? '').toString().toLowerCase();
      final bool coincideTienda = _filtroTienda.trim().isEmpty ||
          tienda.contains(_filtroTienda.trim().toLowerCase());

      return coincideVendedor && coincideTienda;
    }).toList();

    if (filas.isEmpty) {
      return const Center(child: Text('No se encontraron coincidencias.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 150),
      itemCount: filas.length,
      itemBuilder: (context, index) => _buildVentaCard(filas[index]),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Muestra el SplashScreen02 mientras evalúa o carga
    if (_isLoading || widget.inventarioId == null) {
      return const SplashScreen02();
    }

    bool esHoy = DateFormat('dd/MM/yyyy').format(_fechaFiltro) ==
        DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff5b16c2),
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Ventas',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Georgia')),
        actions: [
          IconButton(
              icon: const Icon(Icons.today),
              onPressed: () async {
                setState(() => _fechaFiltro = DateTime.now());
                await _cargarVentas();
              }),
          IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => _seleccionarFecha(context)),
        ],
      ),
      drawer:
          Designwidgets().drawerHome(context, widget.firstName ?? "Invitado"),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: esHoy ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  esHoy
                      ? 'Ventas de Hoy: ${DateFormat('dd/MM/yyyy').format(_fechaFiltro)}'
                      : 'Filtrado: ${DateFormat('dd/MM/yyyy').format(_fechaFiltro)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color:
                          esHoy ? Colors.green.shade900 : Colors.blue.shade900,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              // Barra superior: Buscador + Botón Alternar Filtros Ocultos
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar calzado...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.blueAccent),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.blueAccent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: _tieneFiltrosActivos()
                          ? Colors.blueAccent
                          : Colors.grey.shade200,
                      foregroundColor: _tieneFiltrosActivos()
                          ? Colors.white
                          : Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: Icon(_mostrarFiltros
                        ? Icons.filter_alt_off
                        : Icons.filter_alt),
                    onPressed: () {
                      setState(() {
                        _mostrarFiltros = !_mostrarFiltros;
                      });
                    },
                  ),
                ],
              ),

              // Panel Colapsable de Filtros Secundarios Ocultos
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                height: _mostrarFiltros ? null : 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _mostrarFiltros ? 1.0 : 0.0,
                  child: SingleChildScrollView(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputFiltro(
                                  controller: _vendedorController,
                                  label: 'Vendedor',
                                  icon: Icons.person_outline,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInputFiltro(
                                  controller: _tiendaController,
                                  label: 'Tienda',
                                  icon: Icons.store_outlined,
                                ),
                              ),
                            ],
                          ),
                          if (_tieneFiltrosActivos()) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _limpiarFiltros,
                                icon: const Icon(
                                  Icons.cleaning_services_rounded,
                                  size: 16,
                                  color: Colors.redAccent,
                                ),
                                label: const Text(
                                  'Limpiar Filtros',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _buildContenidoVentas(esHoy),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _buildFab(Designwidgets().linearGradientPurple(context), "btn3",
              _navegarFormularioMuestra, "Muestra"),
          const SizedBox(height: 12),
          _buildFab(Designwidgets().linearGradientFire(context), "btn2",
              _navegarFormularioMultiple, "Catálogo"),
        ],
      ),
    );
  }

  Widget _miniChip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(texto,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildVentaCard(Map<String, dynamic> filaData) {
    final String filaId = filaData['id_fila_venta'].toString();

    final bool esMuestra = filaData['id_dueno_muestra'] != null;
    final String duenoMuestraNombre =
        filaData['dueno_muestra_nombre'] ?? 'Desconocido';
    final DateTime fechaVenta = (filaData['fecha_venta'] != null
            ? (filaData['fecha_venta'] is DateTime
                ? filaData['fecha_venta'] as DateTime
                : DateTime.parse(filaData['fecha_venta'].toString()))
            : DateTime.now())
        .subtract(const Duration(hours: 5));
    final bool esVentaDeHoy = DateFormat('dd/MM/yyyy').format(fechaVenta) ==
        DateFormat('dd/MM/yyyy').format(DateTime.now());

    final double precioTotal =
        double.tryParse(filaData['precio_venta_total'].toString()) ?? 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          if (esMuestra)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Text(
                'MUESTRA DE ${duenoMuestraNombre.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ExpansionTile(
            shape: const Border(),
            leading: _buildIcon(filaData['calzado_icono']),
            title: Text(
                (filaData['descripcion_muestra'] != null &&
                        filaData['descripcion_muestra']
                            .toString()
                            .trim()
                            .isNotEmpty)
                    ? filaData['descripcion_muestra']
                    : (filaData['calzado_nombre'] ?? 'Sin nombre'),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Cant: ${filaData['cantidad']} • Talla: ${filaData['talla']}',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54)),
                    Text('S/ ${precioTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 15)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (filaData['colores'] != null &&
                          filaData['colores'] != '' &&
                          filaData['colores'] != false &&
                          filaData['colores'] != '0')
                        _miniChip('Color: ${filaData['color_nombre']}',
                            Colors.purple),
                      if (filaData['taco'] != null &&
                          filaData['taco'] != 0 &&
                          filaData['taco'] != '0')
                        _miniChip('Taco: ${filaData['taco']}', Colors.orange),
                      if (filaData['plataforma'] != null &&
                          filaData['plataforma'] != '' &&
                          filaData['plataforma'] != false &&
                          filaData['plataforma'] != '0')
                        _miniChip(
                            'Plat: ${filaData['plataforma']}', Colors.blue),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Vendedor: ${filaData['usuario_creacion'] ?? 'Desconocido'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 12, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(_formatFechaLarga(fechaVenta),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              const Divider(),
              _buildDetalleRow(Icons.payments, 'Método de Pago',
                  filaData['metodo_pago'] ?? 'N/A'),
              _buildDetalleRow(Icons.storefront, 'Lugar de Venta',
                  filaData['lugar_venta'] ?? 'N/A'),
              if ((filaData['lugar_venta'] ?? '').toString().toLowerCase() ==
                      'tienda' &&
                  filaData['tienda_nombre'] != null &&
                  filaData['tienda_nombre'].toString().isNotEmpty)
                _buildDetalleRow(Icons.store, 'Tienda',
                    filaData['tienda_nombre'].toString()),
              if (esVentaDeHoy)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          final res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => VentaFormPage(
                                      firstName: widget.firstName,
                                      emailUser: widget.emailUser,
                                      inventarioId: widget.inventarioId,
                                      ventaId: filaId,
                                      datosEdicion: filaData)));
                          if (res == true) await _cargarVentas();
                        },
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        label: const Text('Editar'),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            _eliminarVentaConReversa(filaId, filaData),
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Eliminar',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetalleRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Text('$label: ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildIcon(String? icono) {
    if (icono == null || icono.isEmpty) {
      return const Icon(Icons.image_not_supported,
          size: 35, color: Colors.grey);
    }
    return Image.asset(icono,
        width: 40,
        height: 40,
        errorBuilder: (_, __, ___) => const Icon(Icons.receipt));
  }

  void _navegarFormularioMultiple() async {
    final res = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => VentaFormPageMultiple(
                firstName: widget.firstName,
                emailUser: widget.emailUser,
                inventarioId: widget.inventarioId)));
    if (res == true) await _cargarVentas();
  }

  void _navegarFormularioMuestra() async {
    final res = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => VentaFormPageMuestra(
                firstName: widget.firstName,
                emailUser: widget.emailUser,
                inventarioId: widget.inventarioId)));
    if (res == true) await _cargarVentas();
  }

  Widget _buildFab(
      Gradient gradient, String tag, VoidCallback onPressed, String label) {
    return SizedBox(
      width: 170,
      child: Container(
        decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2))
            ]),
        child: FloatingActionButton.extended(
          heroTag: tag,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: onPressed,
          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

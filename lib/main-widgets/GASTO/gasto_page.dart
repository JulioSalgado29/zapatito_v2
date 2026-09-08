import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/GASTO/gasto_form.dart';
import 'package:zapatito_v2/services/API/gasto.dart';
import 'package:zapatito_v2/services/API/inventario.dart';
import 'package:zapatito_v2/services/API/tienda.dart';

class GastoPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;
  final String? tiendaId;

  const GastoPage({
    super.key,
    this.firstName,
    this.emailUser,
    this.inventarioId,
    this.tiendaId,
  });

  @override
  State<GastoPage> createState() => _GastoPageState();
}

class _GastoPageState extends State<GastoPage> {
  DateTime _fechaFiltro = DateTime.now();

  // 🔹 Estado de Carga / Data local
  bool _isLoading = true;
  bool _isFetchingGastos = false;
  List<Map<String, dynamic>> _gastos = [];
  Map<String, String> _mapaTiendas = {}; // 🔹 Mapa para almacenar id_tienda -> nombre

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

    // Carga inicial de datos y nombres de tiendas una sola vez al entrar
    if (widget.inventarioId != null) {
      await Future.wait([
        _cargarGastos(),
        _cargarNombresTiendas(),
      ]);
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
  Future<void> _cargarGastos() async {
    if (widget.inventarioId == null) return;
    if (mounted) setState(() => _isFetchingGastos = true);

    try {
      final data = await GastoService.obtenerPorInventario(
        widget.inventarioId!,
        fechaFiltro: _fechaFiltro,
      );
      if (mounted) {
        setState(() {
          _gastos = data;
          _isFetchingGastos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gastos = [];
          _isFetchingGastos = false;
        });
      }
    }
  }

  // 🔹 Carga el listado de tiendas para mapear los IDs con sus nombres
  Future<void> _cargarNombresTiendas() async {
    if (widget.inventarioId == null) return;
    try {
      final listaTiendas = await TiendaService.obtenerPorInventario(widget.inventarioId!);
      final Map<String, String> mapaTemp = {};
      for (var tienda in listaTiendas) {
        final id = tienda['id_tienda']?.toString();
        final nombre = tienda['nombre']?.toString();
        if (id != null && nombre != null) {
          mapaTemp[id] = nombre;
        }
      }
      if (mounted) {
        setState(() {
          _mapaTiendas = mapaTemp;
        });
      }
    } catch (_) {
      // Manejo silencioso en caso de error al traer las tiendas
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
      await _cargarGastos();
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

  void _confirmarEliminacion(String id, String montoFormateado) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 20,
        backgroundColor: Colors.black.withOpacity(0.85),
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
              const Text(
                '¿Eliminar Gasto?',
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '¿Seguro que deseas eliminar el gasto por S/ $montoFormateado? Esta acción no se puede deshacer.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón Eliminar
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx); // Cierra el diálogo de confirmación
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const SplashScreen02(),
                      );

                      try {
                        final bool exito = await GastoService.eliminar(id);

                        if (mounted && Navigator.canPop(context)) {
                          Navigator.pop(context); // Cierra el SplashScreen02
                        }

                        if (mounted) {
                          if (exito) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Gasto quitado de la lista correctamente 🗑️'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                            await _cargarGastos(); // Recarga la lista local
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo eliminar el gasto'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al procesar: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Eliminar',
                        style: TextStyle(color: Colors.white)),
                  ),
                  // Botón Cancelar
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Cancelar',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContenidoGastos(bool esHoy) {
    if (_isFetchingGastos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_gastos.isEmpty) {
      return Center(
          child: Text(esHoy
              ? 'No hay gastos registrados hoy.'
              : 'No hay gastos para esta fecha.'));
    }

    // 🔹 Lógica de Filtro por Buscador y Filtros Secundarios
    final filas = _gastos.where((data) {
      final String descripcion = (data['descripcion'] ?? '').toString().toLowerCase();
      if (!descripcion.contains(_searchQuery.trim().toLowerCase())) {
        return false;
      }

      if (!_tieneFiltrosActivos()) return true;

      final String vendedor = (data['usuario_creacion'] ?? '').toString().toLowerCase();
      final bool coincideVendedor = _filtroVendedor.trim().isEmpty ||
          vendedor.contains(_filtroVendedor.trim().toLowerCase());

      final dynamic idTiendaRegistro = data['id_tienda'];
      final String tiendaIdStr = idTiendaRegistro?.toString() ?? '';
      final String nombreTienda = (_mapaTiendas[tiendaIdStr] ?? 'Tienda principal').toLowerCase();
      
      final bool coincideTienda = _filtroTienda.trim().isEmpty ||
          nombreTienda.contains(_filtroTienda.trim().toLowerCase());

      return coincideVendedor && coincideTienda;
    }).toList();

    if (filas.isEmpty) {
      return const Center(child: Text('No se encontraron coincidencias.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 10, bottom: 120, left: 12, right: 12),
      itemCount: filas.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final data = filas[index];

        final String id = data['id_gasto']?.toString() ?? '';
        final double monto =
            double.tryParse(data['monto']?.toString() ?? '0') ?? 0.0;
        final String descripcion = data['descripcion'] ?? '';
        final String usuarioCreacion =
            data['usuario_creacion'] ?? 'Anónimo';
        final String montoFormateado = monto.toStringAsFixed(2);
        
        final dynamic idTiendaRegistro = data['id_tienda'];
        final String tiendaIdStr = idTiendaRegistro?.toString() ?? '';
        final String nombreTienda = _mapaTiendas[tiendaIdStr] ?? 'Tienda principal';

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.black12,
            child: Text(
              'S/',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          title: Text(
            'S/ $montoFormateado',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (descripcion.isNotEmpty)
                Text(
                  descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.store,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      nombreTienda,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      usuarioCreacion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Color.fromARGB(255, 33, 47, 243),
                ),
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GastoForm(
                        firstName: widget.firstName,
                        emailUser: widget.emailUser,
                        inventarioId: widget.inventarioId,
                        tiendaId: idTiendaRegistro?.toString() ?? widget.tiendaId,
                        gastoId: id,
                        montoInicial: monto,
                        descripcionInicial: descripcion,
                      ),
                    ),
                  );

                  if (res == true) {
                    await _cargarGastos();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () =>
                    _confirmarEliminacion(id, montoFormateado),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Gastos',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontFamily: 'Georgia')),
        actions: [
          IconButton(
              icon: const Icon(Icons.today),
              onPressed: () async {
                setState(() => _fechaFiltro = DateTime.now());
                await _cargarGastos();
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
                      ? 'Gastos de Hoy: ${DateFormat('dd/MM/yyyy').format(_fechaFiltro)}'
                      : 'Filtrado: ${DateFormat('dd/MM/yyyy').format(_fechaFiltro)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: esHoy ? Colors.green.shade900 : Colors.blue.shade900,
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
                        hintText: 'Buscar descripción...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.blueAccent),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                      foregroundColor:
                          _tieneFiltrosActivos() ? Colors.white : Colors.black87,
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
                child: _buildContenidoGastos(esHoy),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 33, 47, 243),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GastoForm(
                firstName: widget.firstName,
                emailUser: widget.emailUser,
                inventarioId: widget.inventarioId,
                tiendaId: widget.tiendaId,
              ),
            ),
          );

          if (res == true) {
            await _cargarGastos();
          }
        },
      ),
    );
  }
}
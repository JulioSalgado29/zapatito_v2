import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/calzado.dart';
import 'package:zapatito_v2/services/API/fila_venta.dart';
import 'package:zapatito_v2/services/API/tienda.dart'; // 👈 Asegúrate de importar tu servicio

class VentaFormPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;
  final String? ventaId;
  final Map<String, dynamic>? datosEdicion;

  const VentaFormPage({
    super.key,
    required this.firstName,
    this.emailUser,
    this.inventarioId,
    this.ventaId,
    this.datosEdicion,
  });

  @override
  State<VentaFormPage> createState() => _VentaFormPageState();
}

class _VentaFormPageState extends State<VentaFormPage> {
  bool _cargandoInicial = true;
  bool _cargandoTiendas = true;

  List<Map<String, dynamic>> _calzados = [];
  List<Map<String, dynamic>> _listaTiendas = [];

  bool esMuestra = false;
  String? idDuenoMuestra;
  String? nombreDuenoMuestra;

  dynamic _tiendaSeleccionadaId; // 👈 Guarda el ID de la tienda editable

  String? _calzadoId;
  int? _tallaSeleccionada;
  String? _idColorSeleccionado;
  String? _colorSeleccionado;
  int? _tacoSeleccionado;
  String? _plataformaSeleccionada;

  bool _tipoTieneTaco = false;
  bool _tipoTienePlataforma = false;
  bool _tipoTieneColores = true;

  int _cantidadVenta = 0;
  double _precioVentaTotal = 0.0;

  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  String? _metodoPagoSeleccionado;
  String? _lugarVentaSeleccionado;

  final List<String> _metodosPago = [
    'Efectivo',
    'Yape',
    'Plin',
    'Transferencia',
    'POS',
    'Efectivo y Yape',
    'Efectivo y Plin',
    'Efectivo y Transferencia',
    'Efectivo y POS'
  ];
  final List<String> _lugaresVenta = ['Tienda', 'Live'];

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    await Future.wait([
      _cargarDatosEdicion(),
      _cargarTiendas(),
    ]);
  }

  // 🔹 Carga de lista de tiendas asociadas al inventario
  Future<void> _cargarTiendas() async {
    if (widget.inventarioId == null) {
      if (mounted) setState(() => _cargandoTiendas = false);
      return;
    }
    try {
      final data =
          await TiendaService.obtenerPorInventario(widget.inventarioId!);
      if (mounted) {
        setState(() {
          _listaTiendas = List<Map<String, dynamic>>.from(data);

          // Valida si la tienda cargada de datosEdicion existe en la lista obtenida
          final bool idExiste = _listaTiendas.any((t) =>
              t['id_tienda']?.toString() ==
              _tiendaSeleccionadaId?.toString());

          if (!idExiste && _listaTiendas.isNotEmpty) {
            // Si el id pre-cargado no coincide o es inválido, puede resetearse o mantenerse
            _tiendaSeleccionadaId = null;
          }

          _cargandoTiendas = false;
        });
      }
    } catch (e) {
      print('Error cargando tiendas: $e');
      if (mounted) setState(() => _cargandoTiendas = false);
    }
  }

  Future<void> _cargarDatosEdicion() async {
    if (widget.datosEdicion == null) {
      if (mounted) setState(() => _cargandoInicial = false);
      return;
    }

    final d = widget.datosEdicion!;
    final String cId = d['id_calzado'].toString();

    try {
      final calzadosFuture =
          CalzadoService.obtenerPorInventarioUpdate(widget.inventarioId);
      final detalleCalzadoFuture = CalzadoService.obtenerPorId(cId);

      final resultados =
          await Future.wait([calzadosFuture, detalleCalzadoFuture]);

      final listaCalzados = resultados[0] as List<Map<String, dynamic>>;
      final data = resultados[1] as Map<String, dynamic>?;

      if (d['id_dueno_muestra'] != null) {
        nombreDuenoMuestra = d['dueno_muestra_nombre'];
      }

      if (mounted) {
        setState(() {
          _calzados = listaCalzados;

          if (data != null) {
            _tipoTieneTaco = data['taco'] ?? false;
            _tipoTienePlataforma = data['plataforma'] ?? false;
            _tipoTieneColores = data['colores'] ?? false;
          }

          _calzadoId = cId;
          _tallaSeleccionada = d['talla'];
          _idColorSeleccionado = (d['colores'] == '' || d['colores'] == null)
              ? null
              : d['colores'].toString();
          _colorSeleccionado =
              (d['color_nombre'] == '' || d['color_nombre'] == null)
                  ? null
                  : d['color_nombre'].toString();
          _tacoSeleccionado = (d['taco'] == 0 || d['taco'] == null)
              ? null
              : (d['taco'] as num).toInt();
          _plataformaSeleccionada =
              (d['plataforma'] == '' || d['plataforma'] == null)
                  ? null
                  : d['plataforma'].toString();
          _cantidadVenta = d['cantidad'] ?? 0;
          _precioVentaTotal =
              double.tryParse(d['precio_venta_total'].toString()) ?? 0.0;
          _metodoPagoSeleccionado = d['metodo_pago'];
          _lugarVentaSeleccionado = d['lugar_venta'];
          
          // 👈 Precarga del ID de la tienda proveniente de la edición
          _tiendaSeleccionadaId = d['id_tienda'] ?? d['tienda_id'];

          esMuestra = d['id_dueno_muestra'] != null;
          idDuenoMuestra = d['id_dueno_muestra']?.toString();

          _cantidadController.text = _cantidadVenta.toString();
          _precioController.text = _precioVentaTotal.toString();
          _cargandoInicial = false;
        });
      }
    } catch (e) {
      print('Error cargando datos de edición: $e');
      if (mounted) {
        setState(() => _cargandoInicial = false);
      }
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  bool get _puedeVender {
    if (_calzadoId == null || _tallaSeleccionada == null) return false;
    if (_tipoTieneColores && _colorSeleccionado == null) return false;
    if (_tipoTieneTaco && _tacoSeleccionado == null) return false;
    if (_tipoTienePlataforma && _plataformaSeleccionada == null) return false;
    if (_metodoPagoSeleccionado == null) return false;
    if (_lugarVentaSeleccionado == null) return false;

    // 👈 Si es 'Tienda', debe haber seleccionado obligatoriamente una tienda
    if (_lugarVentaSeleccionado == 'Tienda' && _tiendaSeleccionadaId == null) {
      return false;
    }

    if (_cantidadVenta <= 0 || _precioVentaTotal <= 0) return false;

    return true;
  }

  Future<void> _realizarVenta() async {
    if (!_puedeVender) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SplashScreen02(),
    );
    final exito = await FilaVentaService.editarVenta(
      idFilaVenta: widget.ventaId,
      data: {
        'id_inventario': widget.inventarioId,
        'id_calzado': _calzadoId,
        'talla': _tallaSeleccionada,
        'colores': _tipoTieneColores ? (_idColorSeleccionado ?? "0") : "0",
        'taco': _tipoTieneTaco ? (_tacoSeleccionado ?? 0) : 0,
        'plataforma':
            _tipoTienePlataforma ? (_plataformaSeleccionada ?? "0") : "0",
        'cantidad': _cantidadVenta,
        'precio_venta_total': _precioVentaTotal,
        'metodo_pago': _metodoPagoSeleccionado,
        'lugar_venta': _lugarVentaSeleccionado,
        // 👈 Envía id_tienda solo si el lugar de venta es 'Tienda', o null/0 en otro caso
        'id_tienda':
            _lugarVentaSeleccionado == 'Tienda' ? _tiendaSeleccionadaId : null,
        'usuario_creacion': widget.firstName ?? 'anon',
        'email_user': widget.emailUser ?? 'anon',
      },
    );

    if (mounted) Navigator.of(context, rootNavigator: true).pop();

    if (exito) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar la venta')),
        );
      }
    }
  }

  // -------------------------------------------------------
  // UI COMPONENTS
  // -------------------------------------------------------

  // 👈 Dropdown dinámico que se dibuja condicionalmente cuando lugarVenta es 'Tienda'
  Widget _buildDropdownTienda() {
    if (_lugarVentaSeleccionado != 'Tienda') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: _cargandoTiendas
          ? const LinearProgressIndicator()
          : DropdownButtonFormField<dynamic>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Seleccionar Tienda',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              value: _tiendaSeleccionadaId,
              hint: const Text('Seleccione Tienda'),
              items: _listaTiendas
                  .map((t) => DropdownMenuItem<dynamic>(
                        value: t['id_tienda'],
                        child: Text(
                          t['nombre']?.toString() ?? 'Sin nombre',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _tiendaSeleccionadaId = v),
            ),
    );
  }

  Widget _buildDropdownCalzado() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Seleccionar código',
        border: OutlineInputBorder(),
      ),
      value: _calzadoId?.toString(),
      items: _calzados.map((data) {
        final String calzadoId =
            (data['id_calzado'] ?? data['calzado_id'] ?? '').toString();
        final String? rutaIcono = data['icono'] ?? data['calzado_icono'];

        return DropdownMenuItem<String>(
          value: calzadoId,
          child: Row(
            children: [
              if (rutaIcono != null && rutaIcono.isNotEmpty)
                Image.asset(
                  rutaIcono,
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.category, size: 32),
                )
              else
                const Icon(Icons.category, size: 32),
              const SizedBox(width: 8),
              Text(data['nombre'] ?? ''),
            ],
          ),
        );
      }).toList(),
      onChanged: null,
    );
  }

  Widget _buildDropdownTalla() {
    if (_calzadoId == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
            labelText: 'Seleccionar talla', border: OutlineInputBorder()),
        value: _tallaSeleccionada,
        items: [
          DropdownMenuItem(
              value: _tallaSeleccionada,
              child: Text(_tallaSeleccionada?.toString() ?? ''))
        ],
        onChanged: null,
      ),
    );
  }

  Widget _buildDropdownDueno() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Dueño de Muestra',
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xFFF5F5F5),
        ),
        value: idDuenoMuestra,
        items: [
          DropdownMenuItem(
            value: idDuenoMuestra,
            child: Text(nombreDuenoMuestra ?? 'Cargando...'),
          )
        ],
        onChanged: null,
      ),
    );
  }

  Widget _buildDropdownColor() {
    if (!_tipoTieneColores) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
            labelText: 'Seleccionar color',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.palette)),
        value: _colorSeleccionado,
        items: [
          DropdownMenuItem(
              value: _colorSeleccionado, child: Text(_colorSeleccionado ?? ''))
        ],
        onChanged: null,
      ),
    );
  }

  Widget _buildDropdownTaco() {
    if (!_tipoTieneTaco) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
            labelText: 'Seleccionar taco (cm)', border: OutlineInputBorder()),
        value: _tacoSeleccionado,
        items: [
          DropdownMenuItem(
              value: _tacoSeleccionado, child: Text('$_tacoSeleccionado cm'))
        ],
        onChanged: null,
      ),
    );
  }

  Widget _buildDropdownPlataforma() {
    if (!_tipoTienePlataforma) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
            labelText: 'Seleccionar plataforma',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.layers_outlined)),
        value: _plataformaSeleccionada,
        items: [
          DropdownMenuItem(
              value: _plataformaSeleccionada,
              child: Text(_plataformaSeleccionada ?? ''))
        ],
        onChanged: null,
      ),
    );
  }

  Widget _buildMetodoYLugar() {
    return Column(children: [
      const SizedBox(height: 12),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Método de Pago',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payments_outlined, size: 20)),
            value: _metodoPagoSeleccionado,
            items: _metodosPago
                .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (v) => setState(() => _metodoPagoSeleccionado = v),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Lugar de Venta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined, size: 20)),
            value: _lugarVentaSeleccionado,
            items: _lugaresVenta
                .map((l) => DropdownMenuItem(
                    value: l,
                    child: Text(l,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (v) {
              setState(() {
                _lugarVentaSeleccionado = v;
                // Si cambia a algo distinto de Tienda, limpia la selección de tienda
                if (v != 'Tienda') {
                  _tiendaSeleccionadaId = null;
                }
              });
            },
          ),
        ),
      ]),
      _buildDropdownTienda(), // 👈 Se muestra solo si _lugarVentaSeleccionado == 'Tienda'
    ]);
  }

  Widget _buildCantidadYPrecio() {
    final bool camposListos = _tallaSeleccionada != null &&
        (!_tipoTieneColores || _colorSeleccionado != null) &&
        (!_tipoTieneTaco || _tacoSeleccionado != null) &&
        (!_tipoTienePlataforma || _plataformaSeleccionada != null);

    if (!camposListos) return const SizedBox();

    return Column(children: [
      _buildMetodoYLugar(),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextFormField(
            controller: _cantidadController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Cantidad',
              border: const OutlineInputBorder(),
              fillColor: Colors.grey.shade200,
              filled: true,
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: _precioController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
            ],
            decoration: const InputDecoration(
                labelText: 'Precio Total',
                border: OutlineInputBorder(),
                prefixText: 'S/ '),
            onChanged: (v) =>
                setState(() => _precioVentaTotal = double.tryParse(v) ?? 0.0),
          ),
        ),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoInicial) {
      return Scaffold(
        appBar: Designwidgets().appBarMain('Editar Venta'),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: Designwidgets().appBarMain('Editar Venta'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (esMuestra) _buildDropdownDueno(),
              const SizedBox(height: 16),
              _buildDropdownCalzado(),
              _buildDropdownTalla(),
              _buildDropdownColor(),
              _buildDropdownTaco(),
              _buildDropdownPlataforma(),
              _buildCantidadYPrecio(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _puedeVender ? Colors.green.shade600 : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('Actualizar venta'),
                  onPressed: _puedeVender ? _realizarVenta : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
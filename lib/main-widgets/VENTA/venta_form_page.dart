import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/calzado.dart';

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
  bool esMuestra = false;
  String? idDuenoMuestra;
  String? nombreDuenoMuestra;

  String? _calzadoId;
  int? _tallaSeleccionada;
  String? _colorSeleccionado;
  int? _tacoSeleccionado;
  String? _plataformaSeleccionada;

  bool _tipoTieneTaco = false;
  bool _tipoTienePlataforma = false;
  bool _tipoTieneColores = false;

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
    _cargarDatosEdicion();
  }

  Future<void> _cargarDatosEdicion() async {
    final d = widget.datosEdicion!;
    final String cId = d['id_calzado'].toString();

    // 1. Obtenemos directamente el Map desde la API
    final data = await CalzadoService.obtenerPorId(cId);

    // 2. Verificamos que la respuesta no sea nula
    if (data != null) {
      // Si la venta es una muestra, el nombre ya viene desde tu query SQL (dueno_muestra_nombre)
      if (d['id_dueno_muestra'] != null) {
        nombreDuenoMuestra = d['dueno_muestra_nombre'];
      }

      setState(() {
        _tipoTieneTaco = data['taco'] ?? false;
        _tipoTienePlataforma = data['plataforma'] ?? false;
        _tipoTieneColores = data['colores'] ?? false;

        _calzadoId = cId;
        _tallaSeleccionada = d['talla'];
        _colorSeleccionado = (d['colores'] == '' || d['colores'] == null)
            ? null
            : d['colores'].toString();
        _tacoSeleccionado = (d['taco'] == 0 || d['taco'] == null)
            ? null
            : (d['taco'] as num).toInt();
        _plataformaSeleccionada =
            (d['plataforma'] == '' || d['plataforma'] == null)
                ? null
                : d['plataforma'].toString();
        _cantidadVenta = d['cantidad'];
        _precioVentaTotal =
            double.tryParse(d['precio_venta_total'].toString()) ?? 0.0;
        _metodoPagoSeleccionado = d['metodo_pago'];
        _lugarVentaSeleccionado = d['lugar_venta'];

        // Campos para el Dueño
        esMuestra = d['id_dueno_muestra'] != null;
        idDuenoMuestra = d['id_dueno_muestra']?.toString();

        _cantidadController.text = _cantidadVenta.toString();
        _precioController.text = _precioVentaTotal.toString();
      });
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------
  // ACCIONES Y LOGICA DE VENTA
  // -------------------------------------------------------
  bool get _puedeVender {
    if (_calzadoId == null || _tallaSeleccionada == null) return false;
    if (_tipoTieneColores && _colorSeleccionado == null) return false;
    if (_tipoTieneTaco && _tacoSeleccionado == null) return false;
    if (_tipoTienePlataforma && _plataformaSeleccionada == null) return false;
    if (_metodoPagoSeleccionado == null) return false;
    if (_lugarVentaSeleccionado == null) return false;
    if (_cantidadVenta <= 0 || _precioVentaTotal <= 0) return false;

    return true;
  }

  Future<void> _realizarVenta() async {
    if (!_puedeVender) return;
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const SplashScreen02());

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final dAntiguo = widget.datosEdicion!;
      final subfilasAntiguas = await db
          .collection('subfila_inventario')
          .where('talla', isEqualTo: dAntiguo['talla'])
          .where('colores', isEqualTo: dAntiguo['colores'] ?? '')
          .where('taco', isEqualTo: dAntiguo['taco'] ?? 0)
          .where('plataforma', isEqualTo: dAntiguo['plataforma'] ?? '')
          .get();

      for (var subDoc in subfilasAntiguas.docs) {
        final filaRef = await db
            .collection('fila_inventario')
            .doc(subDoc['fila_inventario_id'])
            .get();
        if (filaRef.exists &&
            filaRef['calzado_id'] == dAntiguo['calzado_id'] &&
            filaRef['id_inventario'] == widget.inventarioId) {
          batch.update(subDoc.reference,
              {'cantidad': FieldValue.increment(dAntiguo['cantidad'])});
          batch.update(filaRef.reference,
              {'cantidad': FieldValue.increment(dAntiguo['cantidad'])});
          break;
        }
      }

      final ventaMap = {
        'calzado_id': _calzadoId,
        'talla': _tallaSeleccionada,
        'colores': _tipoTieneColores ? _colorSeleccionado ?? '' : '',
        'taco': _tipoTieneTaco ? _tacoSeleccionado ?? 0 : 0,
        'plataforma': _tipoTienePlataforma ? _plataformaSeleccionada ?? '' : '',
        'cantidad': _cantidadVenta,
        'precio_venta_total': _precioVentaTotal,
        'metodo_pago': _metodoPagoSeleccionado,
        'lugar_venta': _lugarVentaSeleccionado,
        'usuario_creacion': widget.firstName ?? 'anon',
        'fecha_venta': widget.datosEdicion!['fecha_venta'],
      };

      DocumentReference vRef =
          db.collection('venta').doc(widget.datosEdicion!['venta_id']);
      batch.update(vRef, ventaMap);
      batch.update(db.collection('fila_venta').doc(widget.ventaId), {
        ...ventaMap,
        'id_inventario': widget.inventarioId,
        'email_user': widget.emailUser ?? 'anon',
      });

      int cantidadPorDescontar = _cantidadVenta;
      final filasSnap = await db
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .where('inventario_id', isEqualTo: widget.inventarioId)
          .limit(1)
          .get();

      if (filasSnap.docs.isNotEmpty) {
        final filaDoc = filasSnap.docs.first;
        int stockActualFila = filaDoc['cantidad'] ?? 0;

        Query subQuery = db
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: filaDoc.id)
            .where('talla', isEqualTo: _tallaSeleccionada);
        if (_tipoTieneColores) {
          subQuery =
              subQuery.where('colores', isEqualTo: _colorSeleccionado ?? '');
        }
        if (_tipoTieneTaco) {
          subQuery = subQuery.where('taco', isEqualTo: _tacoSeleccionado ?? 0);
        }
        if (_tipoTienePlataforma) {
          subQuery = subQuery.where('plataforma',
              isEqualTo: _plataformaSeleccionada ?? '');
        }

        final subSnap = await subQuery.get();

        if (subSnap.docs.isNotEmpty) {
          final subDoc = subSnap.docs.first;
          int stockActualSub = subDoc['cantidad'];

          if (stockActualSub <= cantidadPorDescontar) {
            batch.delete(subDoc.reference);
          } else {
            batch.update(subDoc.reference,
                {'cantidad': FieldValue.increment(-cantidadPorDescontar)});
          }

          if (stockActualFila <= cantidadPorDescontar) {
            batch.delete(filaDoc.reference);
          } else {
            batch.update(filaDoc.reference,
                {'cantidad': FieldValue.increment(-cantidadPorDescontar)});
          }
        }
      }

      await batch.commit();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // -------------------------------------------------------
  // UI COMPONENTS
  // -------------------------------------------------------

  Widget _buildDropdownCalzado(List<Map<String, dynamic>> calzados) {
  print('Calzados disponibles: ${calzados.length}');
  
  return DropdownButtonFormField<String>(
    decoration: const InputDecoration(
      labelText: 'Seleccionar código',
      border: OutlineInputBorder(),
    ),
    // Forzamos que _calzadoId sea String
    value: _calzadoId?.toString(),
    items: calzados.map((data) {
      // .toString() evita que falle si id_calzado viene como int desde PostgreSQL
      final String calzadoId = (data['id_calzado'] ?? data['calzado_id'] ?? '').toString();
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
              child: Text(_tallaSeleccionada.toString()))
        ],
        onChanged: null, // Bloqueado por edición
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
        onChanged: null, // Bloqueado por edición
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
        onChanged: null, // Bloqueado por edición
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
        onChanged: null, // Bloqueado por edición
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
            onChanged: (v) => setState(() => _lugarVentaSeleccionado = v),
          ),
        ),
      ]),
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
              FutureBuilder<List<Map<String, dynamic>>>(
                future:
                    CalzadoService.obtenerPorInventario(widget.inventarioId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return const Text('No se encontraron calzados');
                  }

                  return _buildDropdownCalzado(snapshot.data!);
                },
              ),
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

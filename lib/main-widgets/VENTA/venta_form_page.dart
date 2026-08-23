import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';

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
  bool get _esEdicion => widget.ventaId != null;

  String? _calzadoId;
  int? _tallaSeleccionada;
  String? _colorSeleccionado;
  int? _tacoSeleccionado;
  String? _plataformaSeleccionada;

  bool _tipoTieneTaco = false;
  bool _tipoTienePlataforma = false;
  bool _tipoTieneColores = false;

  int _stockDisponible = 0;
  int _cantidadVenta = 0;
  double _precioVentaTotal = 0.0;
  bool _cargandoStock = false;

  List<int> _tallasDisponibles = [];
  List<String> _coloresDisponibles = [];
  List<int> _tacosDisponibles = [];
  List<String> _plataformasDisponibles = [];

  bool _errorTalla = false;
  bool _errorColor = false;
  bool _errorPlataforma = false;

  final Map<String, String?> _iconCache = {};
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
    if (_esEdicion) {
      _cargarDatosEdicion();
    } else {
      _calcularStockTotal();
    }
  }

  // 🔹 MODIFICACIÓN: Ahora registra los criterios del calzado al cargar edición
  Future<void> _cargarDatosEdicion() async {
  final d = widget.datosEdicion!;
  final String cId = d['calzado_id'];

  // 1. Obtenemos datos del calzado (configuración de la UI)
  final doc = await FirebaseFirestore.instance.collection('calzado').doc(cId).get();

  if (doc.exists) {
    final data = doc.data()!;
    
    // 2. Si la venta es una muestra, buscamos el nombre del dueño
    if (d['muestra'] == true && d['dueno_muestra_id'] != null) {
      final docDueno = await FirebaseFirestore.instance
          .collection('dueno_muestra')
          .doc(d['dueno_muestra_id'])
          .get();
      
      if (docDueno.exists) {
        nombreDuenoMuestra = docDueno['nombre'];
      }
    }

    setState(() {
      _tipoTieneTaco = data['taco'] ?? false;
      _tipoTienePlataforma = data['plataforma'] ?? false;
      _tipoTieneColores = data['colores'] ?? false;

      _calzadoId = cId;
      _tallaSeleccionada = d['talla'];
      _colorSeleccionado = d['colores'] == '' ? null : d['colores'];
      _tacoSeleccionado = d['taco'] == 0 ? null : d['taco'];
      _plataformaSeleccionada = d['plataforma'] == '' ? null : d['plataforma'];
      _cantidadVenta = d['cantidad'];
      _precioVentaTotal = (d['precio_venta_total'] ?? 0.0).toDouble();
      _metodoPagoSeleccionado = d['metodo_pago'];
      _lugarVentaSeleccionado = d['lugar_venta'];

      // 🔹 Nuevos campos para el Dueño
      esMuestra = d['muestra'] ?? false;
      idDuenoMuestra = d['dueno_muestra_id'];

      _cantidadController.text = _cantidadVenta.toString();
      _precioController.text = _precioVentaTotal.toString();

      _stockDisponible = 999;
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
  // -------------------------------------------------------

  Future<void> _calcularStockTotal() async {
    setState(() => _cargandoStock = true);
    try {
      final calzadosSnap = await FirebaseFirestore.instance
          .collection('calzado')
          .where('id_inventario', isEqualTo: widget.inventarioId)
          .get();

      if (calzadosSnap.docs.isEmpty) {
        setState(() {
          _stockDisponible = 0;
          _cargandoStock = false;
        });
        return;
      }

      final calzadoIds = calzadosSnap.docs.map((d) => d.id).toList();
      int total = 0;
      for (final calzadoId in calzadoIds) {
        final filasSnap = await FirebaseFirestore.instance
            .collection('fila_inventario')
            .where('calzado_id', isEqualTo: calzadoId)
            .get();
        for (final fila in filasSnap.docs) {
          total += (fila['cantidad'] ?? 0) as int;
        }
      }
      setState(() {
        _stockDisponible = total;
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorCalzado(String calzadoId) async {
    setState(() => _cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: calzadoId)
          .get();

      int total = 0;
      final Set<int> tallasSet = {};
      for (final fila in filasSnap.docs) {
        total += (fila['cantidad'] ?? 0) as int;
        final subfilasSnap = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .get();
        for (final sub in subfilasSnap.docs) {
          final talla = sub['talla'] ?? 0;
          if (talla > 0) tallasSet.add(talla as int);
        }
      }
      setState(() {
        _stockDisponible = total;
        _tallasDisponibles = tallasSet.toList()..sort();
        _tallaSeleccionada = null;
        _colorSeleccionado = null;
        _tacoSeleccionado = null;
        _plataformaSeleccionada = null;
        _coloresDisponibles = [];
        _tacosDisponibles = [];
        _plataformasDisponibles = [];
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorTalla(int talla) async {
    if (_tallasDisponibles.contains(talla)) {
      _errorTalla = false;
    } else {
      setState(() {
        _errorTalla = true;
        _tallaSeleccionada = null;
      });
      _mostrarSnack('Talla no disponible, seleccione otra.');
      return;
    }

    if (_calzadoId == null) return;
    setState(() => _cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      int total = 0;
      final Set<String> coloresSet = {};
      for (final fila in filasSnap.docs) {
        final subfilasSnap = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: talla)
            .get();
        for (final sub in subfilasSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
          if (_tipoTieneColores) {
            final color = sub['colores']?.toString() ?? '';
            if (color.isNotEmpty) coloresSet.add(color);
          }
        }
      }
      setState(() {
        _stockDisponible = total;
        _coloresDisponibles = coloresSet.toList()..sort();
        _colorSeleccionado = null;
        _tacoSeleccionado = null;
        _plataformaSeleccionada = null;
        _cargandoStock = false;
      });
      if (!_tipoTieneColores) {
        _cargarSiguientePaso(talla: talla);
      }
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorColor(String color) async {
    if (_coloresDisponibles.contains(color)) {
      _errorColor = false;
    } else {
      setState(() {
        _errorColor = true;
        _colorSeleccionado = null;
      });
      _mostrarSnack('Color no disponible.');
      return;
    }

    if (_calzadoId == null || _tallaSeleccionada == null) return;
    setState(() => _cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      int total = 0;
      final Set<int> tacosSet = {};
      for (final fila in filasSnap.docs) {
        final subfilasSnap = await FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada)
            .where('colores', isEqualTo: color)
            .get();
        for (final sub in subfilasSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
          final taco = sub['taco'] ?? 0;
          if (_tipoTieneTaco && taco > 0) tacosSet.add(taco as int);
        }
      }
      setState(() {
        _stockDisponible = total;
        _tacosDisponibles = tacosSet.toList()..sort();
        _tacoSeleccionado = null;
        _plataformaSeleccionada = null;
        _cargandoStock = false;
      });
      if (!_tipoTieneTaco) {
        _cargarSiguientePaso(talla: _tallaSeleccionada, color: color);
      }
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorTaco(int taco) async {
    setState(() => _cargandoStock = true);
    try {
      int total = 0;
      final Set<String> platSet = {};
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      for (final fila in filasSnap.docs) {
        Query q = FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada)
            .where('taco', isEqualTo: taco);
        if (_tipoTieneColores) {
          q = q.where('colores', isEqualTo: _colorSeleccionado);
        }
        final subSnap = await q.get();
        for (final sub in subSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
          if (_tipoTienePlataforma) {
            final p = sub['plataforma']?.toString() ?? '';
            if (p.isNotEmpty) platSet.add(p);
          }
        }
      }
      setState(() {
        _stockDisponible = total;
        _plataformasDisponibles = platSet.toList()..sort();
        _tacoSeleccionado = taco;
        _plataformaSeleccionada = null;
        _cargandoStock = false;
      });
      if (!_tipoTienePlataforma) {
        _cantidadVenta = 0;
        _cantidadController.clear();
      }
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  Future<void> _cargarSiguientePaso(
      {int? talla, String? color, int? taco}) async {
    final Set<String> platSet = {};
    final filasSnap = await FirebaseFirestore.instance
        .collection('fila_inventario')
        .where('calzado_id', isEqualTo: _calzadoId)
        .get();

    for (final fila in filasSnap.docs) {
      Query q = FirebaseFirestore.instance
          .collection('subfila_inventario')
          .where('fila_inventario_id', isEqualTo: fila.id)
          .where('talla', isEqualTo: talla ?? _tallaSeleccionada);
      if (_tipoTieneColores) {
        q = q.where('colores', isEqualTo: color ?? _colorSeleccionado);
      }
      if (_tipoTieneTaco) {
        q = q.where('taco', isEqualTo: taco ?? _tacoSeleccionado ?? 0);
      }
      final subSnap = await q.get();
      for (final sub in subSnap.docs) {
        if (_tipoTienePlataforma) {
          final p = sub['plataforma']?.toString() ?? '';
          if (p.isNotEmpty) platSet.add(p);
        }
      }
    }
    setState(() => _plataformasDisponibles = platSet.toList()..sort());
  }

  Future<void> _calcularStockFinal(String plataforma) async {
    if (_plataformasDisponibles.contains(plataforma)) {
      _errorPlataforma = false;
    } else {
      setState(() {
        _errorPlataforma = true;
        _plataformaSeleccionada = null;
      });
      _mostrarSnack('Plataforma no disponible, seleccione otra.');
      return;
    }

    if (_calzadoId == null || _tallaSeleccionada == null) return;
    setState(() => _cargandoStock = true);
    try {
      int total = 0;
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: _calzadoId)
          .get();

      for (final fila in filasSnap.docs) {
        Query q = FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: _tallaSeleccionada)
            .where('plataforma', isEqualTo: plataforma);
        if (_tipoTieneColores) {
          q = q.where('colores', isEqualTo: _colorSeleccionado);
        }
        if (_tipoTieneTaco) {
          q = q.where('taco', isEqualTo: _tacoSeleccionado ?? 0);
        }
        final subSnap = await q.get();
        for (final sub in subSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
        }
      }
      setState(() {
        _stockDisponible = total;
        _cargandoStock = false;
      });
    } catch (e) {
      setState(() => _cargandoStock = false);
    }
  }

  // -------------------------------------------------------
  // ACCIONES Y LOGICA DE VENTA
  // -------------------------------------------------------
  void _mostrarSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool get _puedeVender {
    if (_calzadoId == null || _tallaSeleccionada == null) return false;
    if (_tipoTieneColores && _colorSeleccionado == null) return false;
    if (_tipoTieneTaco && _tacoSeleccionado == null) return false;
    if (_tipoTienePlataforma && _plataformaSeleccionada == null) return false;
    if (_metodoPagoSeleccionado == null) return false;
    if (_lugarVentaSeleccionado == null) return false;
    if (_cantidadVenta <= 0 || _precioVentaTotal <= 0) return false;

    // 🔹 MODIFICACIÓN: En edición el stock ya fue restado, ignoramos el check de stock disponible
    if (!_esEdicion &&
        (_stockDisponible <= 0 || _cantidadVenta > _stockDisponible)) {
      return false;
    }

    return true;
  }

  String? get _mensajeBloqueo {
    if (_calzadoId == null || _tallaSeleccionada == null) return null;
    if (!_esEdicion && _stockDisponible == 0) return 'Sin stock disponible';
    if (!_esEdicion &&
        _cantidadVenta > 0 &&
        _cantidadVenta > _stockDisponible) {
      return 'No hay suficiente stock (disponible: $_stockDisponible)';
    }
    return null;
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

      if (_esEdicion) {
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
        'fecha_venta':
            _esEdicion ? widget.datosEdicion!['fecha_venta'] : Timestamp.now(),
      };

      DocumentReference vRef;
      if (_esEdicion) {
        vRef = db.collection('venta').doc(widget.datosEdicion!['venta_id']);
        batch.update(vRef, ventaMap);
        batch.update(db.collection('fila_venta').doc(widget.ventaId), {
          ...ventaMap,
          'id_inventario': widget.inventarioId,
          'email_user': widget.emailUser ?? 'anon',
        });
      } else {
        vRef = db.collection('venta').doc();
        batch.set(vRef, ventaMap);
        batch.set(db.collection('fila_venta').doc(), {
          ...ventaMap,
          'id_inventario': widget.inventarioId,
          'venta_id': vRef.id,
          'fecha_creacion': Timestamp.now(),
          'email_user': widget.emailUser ?? 'anon',
        });
      }

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

          // 🔹 NUEVA LÓGICA: Si la fila principal queda en 0 o menos, se elimina
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

  Future<String?> _obtenerIconoTipo(String id) async {
    if (_iconCache.containsKey(id)) return _iconCache[id];
    final snap = await FirebaseFirestore.instance
        .collection('tipo_calzado')
        .doc(id)
        .get();
    _iconCache[id] = snap.data()?['icono'];
    return _iconCache[id];
  }

  Widget _buildDropdownCalzado(List<QueryDocumentSnapshot> calzados) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
          labelText: 'Seleccionar código', border: OutlineInputBorder()),
      value: _calzadoId,
      items: calzados.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DropdownMenuItem<String>(
          value: doc.id,
          child: FutureBuilder<String?>(
            future: _obtenerIconoTipo(data['tipo_calzado_id'] ?? ''),
            builder: (context, iconSnapshot) {
              final icono = iconSnapshot.data;
              return Row(children: [
                if (icono != null) Image.asset(icono, width: 32, height: 32),
                const SizedBox(width: 8),
                Text(data['nombre'] ?? ''),
              ]);
            },
          ),
        );
      }).toList(),
      onChanged: _esEdicion
          ? null
          : (v) async {
              // 🔹 MODIFICACIÓN: Bloqueo
              if (v == null) return;
              final doc = await FirebaseFirestore.instance
                  .collection('calzado')
                  .doc(v)
                  .get();
              if (doc.exists) {
                final data = doc.data()!;
                setState(() {
                  _tipoTieneTaco = data['taco'] ?? false;
                  _tipoTienePlataforma = data['plataforma'] ?? false;
                  _tipoTieneColores = data['colores'] ?? false;
                  _calzadoId = v;
                });
              }
              await _calcularStockPorCalzado(v);
            },
    );
  }

  Widget _buildDropdownTalla() {
    if (_calzadoId == null ||
        (_tallasDisponibles.isEmpty && !_esEdicion) ||
        _errorTalla) {
      _errorTalla = false;
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
            labelText: 'Seleccionar talla', border: OutlineInputBorder()),
        value: _tallaSeleccionada,
        items: _esEdicion
            ? [
                DropdownMenuItem(
                    value: _tallaSeleccionada,
                    child: Text(_tallaSeleccionada.toString()))
              ]
            : _tallasDisponibles
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.toString())))
                .toList(),
        onChanged: _esEdicion
            ? null
            : (v) {
                // 🔹 MODIFICACIÓN: Bloqueo
                if (v == null) return;
                setState(() {
                  _tallaSeleccionada = v;
                  _cantidadVenta = 0;
                });
                _calcularStockPorTalla(v);
              },
      ),
    );
  }

  Widget _buildDropdownDueno() {
  // Retornamos el widget estático directamente si es edición
  if (_esEdicion) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Dueño de Muestra',
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Color(0xFFF5F5F5), // Color gris para indicar bloqueo
        ),
        value: idDuenoMuestra,
        items: [
          DropdownMenuItem(
            value: idDuenoMuestra,
            child: Text(nombreDuenoMuestra ?? 'Cargando...'),
          )
        ],
        onChanged: null, // Bloquea el Dropdown
      ),
    );
  }

  // Si no es edición, aquí iría tu lógica normal o un SizedBox
  return const SizedBox(); 
}
  Widget _buildDropdownColor() {
    if (!_tipoTieneColores ||
        (_coloresDisponibles.isEmpty && !_esEdicion) ||
        _errorColor) {
      _errorColor = false;
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
            labelText: 'Seleccionar color',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.palette)),
        value: _colorSeleccionado,
        items: _esEdicion
            ? [
                DropdownMenuItem(
                    value: _colorSeleccionado,
                    child: Text(_colorSeleccionado ?? ''))
              ]
            : _coloresDisponibles
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
        onChanged: _esEdicion
            ? null
            : (v) {
                // 🔹 MODIFICACIÓN: Bloqueo
                if (v == null) return;
                setState(() {
                  _colorSeleccionado = v;
                  _cantidadVenta = 0;
                });
                _calcularStockPorColor(v);
              },
      ),
    );
  }

  Widget _buildDropdownTaco() {
    if (!_tipoTieneTaco || (_tacosDisponibles.isEmpty && !_esEdicion)) {
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
            labelText: 'Seleccionar taco (cm)', border: OutlineInputBorder()),
        value: _tacoSeleccionado,
        items: _esEdicion
            ? [
                DropdownMenuItem(
                    value: _tacoSeleccionado,
                    child: Text('$_tacoSeleccionado cm'))
              ]
            : _tacosDisponibles
                .map((t) => DropdownMenuItem(value: t, child: Text('$t cm')))
                .toList(),
        onChanged: _esEdicion
            ? null
            : (v) => _calcularStockPorTaco(v!), // 🔹 MODIFICACIÓN: Bloqueo
      ),
    );
  }

  Widget _buildDropdownPlataforma() {
    if (!_tipoTienePlataforma ||
        (_plataformasDisponibles.isEmpty && !_esEdicion) ||
        _errorPlataforma) {
      _errorPlataforma = false;
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
            labelText: 'Seleccionar plataforma',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.layers_outlined)),
        value: _plataformaSeleccionada,
        items: _esEdicion
            ? [
                DropdownMenuItem(
                    value: _plataformaSeleccionada,
                    child: Text(_plataformaSeleccionada ?? ''))
              ]
            : _plataformasDisponibles
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
        onChanged: _esEdicion
            ? null
            : (v) {
                // 🔹 MODIFICACIÓN: Bloqueo
                if (v == null) return;
                setState(() {
                  _plataformaSeleccionada = v;
                  _cantidadVenta = 0;
                });
                _calcularStockFinal(v);
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets()
          .appBarMain(_esEdicion ? 'Editar Venta' : 'Nueva Venta Código'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_esEdicion && esMuestra)_buildDropdownDueno(),  
              if (!_esEdicion)
                _buildStockLabel(), // 🔹 MODIFICACIÓN: Ocultar stock en edición
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('calzado')
                    .where('id_inventario', isEqualTo: widget.inventarioId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return _buildDropdownCalzado(snapshot.data!.docs);
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
                  label:
                      Text(_esEdicion ? 'Actualizar venta' : 'Registrar venta'),
                  onPressed: _puedeVender ? _realizarVenta : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _stockDisponible > 0 ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
            color: _stockDisponible > 0
                ? Colors.green.shade300
                : Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Stock disponible:'),
          _cargandoStock
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('$_stockDisponible unidades',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
        ],
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
            // 🔹 BLOQUEO: Si es edición, el campo es solo lectura
            readOnly: _esEdicion,
            decoration: InputDecoration(
              labelText: 'Cantidad',
              border: const OutlineInputBorder(),
              // 🔹 OPCIONAL: Un color de fondo gris para indicar visualmente que está bloqueado
              fillColor: _esEdicion ? Colors.grey.shade200 : null,
              filled: _esEdicion,
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              // 🔹 SEGURIDAD: Solo actualizamos el estado si NO es edición
              if (!_esEdicion) {
                setState(() {
                  _cantidadVenta = int.tryParse(v) ?? 0;
                  if (_cantidadVenta <= 0) {
                    _precioController.clear();
                  }
                });
              }
            },
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
      if (_mensajeBloqueo != null)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_mensajeBloqueo!,
                style: const TextStyle(color: Colors.orange))),
    ]);
  }
}

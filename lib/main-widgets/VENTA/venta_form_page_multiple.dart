import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';

// Modelo para manejar cada fila de venta independiente
class VentaItem {
  String? calzadoId;
  int? tallaSeleccionada;
  int? tacoSeleccionado;
  String? colorSeleccionado;
  String? plataformaSeleccionada; // 🔹 Cambiado a String
  int stockDisponible = 0;
  int cantidadVenta = 0;
  double precioVentaTotal = 0.0;
  bool cargandoStock = false;
  List<int> tallasDisponibles = [];
  List<int> tacosDisponibles = [];
  List<String> coloresDisponibles = [];
  List<String> plataformasDisponibles = []; // 🔹 Nueva lista para cascada
  bool errorTalla = false;
  bool errorColor = false;
  bool errorTaco = false;
  bool tipoTieneTaco = false;
  bool tipoTienePlataforma = false;
  bool tipoTieneColores = false;
  String? metodoPagoSeleccionado;
  String? lugarVentaSeleccionado;

  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController precioController = TextEditingController();

  void dispose() {
    cantidadController.dispose();
    precioController.dispose();
  }
}

class VentaFormPageMultiple extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  const VentaFormPageMultiple(
      {super.key, required this.firstName, this.emailUser, this.inventarioId});

  @override
  State<VentaFormPageMultiple> createState() => _VentaFormPageMultipleState();
}

class _VentaFormPageMultipleState extends State<VentaFormPageMultiple> {
  final List<VentaItem> _itemsVenta = [];
  final Map<String, String?> _iconCache = {};

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
    _agregarNuevoItem();
  }

  @override
  void dispose() {
    for (var item in _itemsVenta) {
      item.dispose();
    }
    super.dispose();
  }

  void _agregarNuevoItem() {
    setState(() {
      _itemsVenta.add(VentaItem());
    });
  }

  void _eliminarItem(int index) {
    if (_itemsVenta.length > 1) {
      setState(() {
        _itemsVenta[index].dispose();
        _itemsVenta.removeAt(index);
      });
    }
  }

  bool _esCombinacionDuplicada(int indexActual) {
    var actual = _itemsVenta[indexActual];
    if (actual.calzadoId == null || actual.tallaSeleccionada == null) {
      return false;
    }

    for (int i = 0; i < _itemsVenta.length; i++) {
      if (i == indexActual) continue;
      var item = _itemsVenta[i];
      if (item.calzadoId == actual.calzadoId &&
          item.tallaSeleccionada == actual.tallaSeleccionada &&
          item.tacoSeleccionado == actual.tacoSeleccionado &&
          item.colorSeleccionado == actual.colorSeleccionado &&
          item.plataformaSeleccionada == actual.plataformaSeleccionada) {
        return true;
      }
    }
    return false;
  }

  Future<void> _calcularStockPorCalzado(int index, String calzadoId) async {
    setState(() => _itemsVenta[index].cargandoStock = true);
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
        var item = _itemsVenta[index];
        item.stockDisponible = total;
        item.tallasDisponibles = tallasSet.toList()..sort();
        item.tallaSeleccionada = null;
        item.tacoSeleccionado = null;
        item.colorSeleccionado = null;
        item.plataformaSeleccionada = null;
        item.tacosDisponibles = [];
        item.coloresDisponibles = [];
        item.plataformasDisponibles = [];
        item.cargandoStock = false;
      });
    } catch (e) {
      setState(() => _itemsVenta[index].cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorTalla(int index, int talla) async {
    var item = _itemsVenta[index];
    if (!item.tallasDisponibles.contains(talla)) {
      setState(() {
        item.errorTalla = true;
        item.tallaSeleccionada = null;
      });
      return;
    }
    if (item.calzadoId == null) return;

    setState(() => item.cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: item.calzadoId)
          .get();

      int total = 0;
      final Set<String> coloresSet = {};

      for (final fila in filasSnap.docs) {
        Query q = FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: talla);

        final subfilasSnap = await q.get();
        for (final sub in subfilasSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
          final color = sub['colores']?.toString() ?? '';
          if (item.tipoTieneColores && color.isNotEmpty) coloresSet.add(color);
        }
      }

      setState(() {
        item.stockDisponible = total;
        item.coloresDisponibles = coloresSet.toList()..sort();
        item.colorSeleccionado = null;
        item.tacoSeleccionado = null;
        item.plataformaSeleccionada = null;
        item.tacosDisponibles = [];
        item.plataformasDisponibles = [];
        item.cargandoStock = false;
      });

      if (!item.tipoTieneColores) _cargarSiguientePaso(index);
    } catch (e) {
      setState(() => item.cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorColor(int index, String color) async {
    var item = _itemsVenta[index];
    if (!item.coloresDisponibles.contains(color)) {
      setState(() {
        item.errorColor = true;
        item.colorSeleccionado = null;
      });
      return;
    }
    setState(() => item.cargandoStock = true);
    try {
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: item.calzadoId)
          .get();

      int total = 0;
      final Set<int> tacosSet = {};

      for (final fila in filasSnap.docs) {
        Query q = FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: item.tallaSeleccionada)
            .where('colores', isEqualTo: color);

        final subfilasSnap = await q.get();
        for (final sub in subfilasSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
          final taco = sub['taco'] ?? 0;
          if (item.tipoTieneTaco && taco > 0) tacosSet.add(taco as int);
        }
      }

      setState(() {
        item.stockDisponible = total;
        item.tacosDisponibles = tacosSet.toList()..sort();
        item.tacoSeleccionado = null;
        item.plataformaSeleccionada = null;
        item.cargandoStock = false;
      });

      if (!item.tipoTieneTaco) _cargarSiguientePaso(index);
    } catch (e) {
      setState(() => item.cargandoStock = false);
    }
  }

  Future<void> _calcularStockPorTaco(int index, int taco) async {
    var item = _itemsVenta[index];
    setState(() => item.cargandoStock = true);
    try {
      int total = 0;
      final Set<String> platSet = {};
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: item.calzadoId)
          .get();

      for (final fila in filasSnap.docs) {
        Query q = FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: item.tallaSeleccionada)
            .where('taco', isEqualTo: taco);

        if (item.tipoTieneColores) {
          q = q.where('colores', isEqualTo: item.colorSeleccionado);
        }

        final subSnap = await q.get();
        for (final sub in subSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
          if (item.tipoTienePlataforma) {
            final p = sub['plataforma']?.toString() ?? '';
            if (p.isNotEmpty) platSet.add(p);
          }
        }
      }

      setState(() {
        item.stockDisponible = total;
        item.plataformasDisponibles = platSet.toList()..sort();
        item.tacoSeleccionado = taco;
        item.plataformaSeleccionada = null;
        item.cargandoStock = false;
      });
    } catch (e) {
      setState(() => item.cargandoStock = false);
    }
  }

  Future<void> _cargarSiguientePaso(int index) async {
    var item = _itemsVenta[index];
    final Set<String> platSet = {};
    final filasSnap = await FirebaseFirestore.instance
        .collection('fila_inventario')
        .where('calzado_id', isEqualTo: item.calzadoId)
        .get();

    for (final fila in filasSnap.docs) {
      Query q = FirebaseFirestore.instance
          .collection('subfila_inventario')
          .where('fila_inventario_id', isEqualTo: fila.id)
          .where('talla', isEqualTo: item.tallaSeleccionada);

      if (item.tipoTieneColores) {
        q = q.where('colores', isEqualTo: item.colorSeleccionado);
      }
      if (item.tipoTieneTaco) {
        q = q.where('taco', isEqualTo: item.tacoSeleccionado ?? 0);
      }

      final subSnap = await q.get();
      for (final sub in subSnap.docs) {
        if (item.tipoTienePlataforma) {
          final p = sub['plataforma']?.toString() ?? '';
          if (p.isNotEmpty) platSet.add(p);
        }
      }
    }
    setState(() => item.plataformasDisponibles = platSet.toList()..sort());
  }

  Future<void> _calcularStockFinal(int index, String plataforma) async {
    var item = _itemsVenta[index];
    setState(() => item.cargandoStock = true);
    try {
      int total = 0;
      final filasSnap = await FirebaseFirestore.instance
          .collection('fila_inventario')
          .where('calzado_id', isEqualTo: item.calzadoId)
          .get();

      for (final fila in filasSnap.docs) {
        Query q = FirebaseFirestore.instance
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: fila.id)
            .where('talla', isEqualTo: item.tallaSeleccionada)
            .where('plataforma', isEqualTo: plataforma);

        if (item.tipoTieneColores) {
          q = q.where('colores', isEqualTo: item.colorSeleccionado);
        }
        if (item.tipoTieneTaco) {
          q = q.where('taco', isEqualTo: item.tacoSeleccionado ?? 0);
        }

        final subSnap = await q.get();
        for (final sub in subSnap.docs) {
          total += (sub['cantidad'] ?? 0) as int;
        }
      }
      setState(() {
        item.stockDisponible = total;
        item.cargandoStock = false;
      });
      if (_esCombinacionDuplicada(index)) _notificarDuplicado(index);
    } catch (e) {
      setState(() => item.cargandoStock = false);
    }
  }

  void _notificarDuplicado(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta combinación ya está en la lista.')));
    setState(() {
      _itemsVenta[index].tallaSeleccionada = null;
      _itemsVenta[index].cantidadVenta = 0;
      _itemsVenta[index].cantidadController.clear();
    });
  }

  Future<void> _realizarVenta() async {
    
    if (!_itemsVenta.every((i) =>
        i.calzadoId != null &&
        i.tallaSeleccionada != null &&
        i.metodoPagoSeleccionado != null &&
        i.lugarVentaSeleccionado != null &&
        i.cantidadVenta > 0 &&
        i.cantidadVenta <= i.stockDisponible)) return;

    _mostrarSplashScreen();
    try {
      final db = FirebaseFirestore.instance;
      for (var item in _itemsVenta) {
        final ventaData = {
          'calzado_id': item.calzadoId,
          'talla': item.tallaSeleccionada,
          'taco': item.tipoTieneTaco ? item.tacoSeleccionado ?? 0 : 0,
          'colores': item.tipoTieneColores ? item.colorSeleccionado ?? '' : '',
          'plataforma':
              item.tipoTienePlataforma ? item.plataformaSeleccionada ?? '' : '',
          'cantidad': item.cantidadVenta,
          'precio_venta_total': item.precioVentaTotal,
          'metodo_pago': item.metodoPagoSeleccionado, // 🔹 Valor por item
          'lugar_venta': item.lugarVentaSeleccionado, // 🔹 Valor por item'
          'fecha_venta': Timestamp.now(),
          'usuario_creacion': widget.firstName ?? 'anon',
          // 🔹 AGREGADOS A LA DATA DE FIREBASE
        };
        item.precioController.text = item.precioVentaTotal.toString();

        final ventaRef = await db.collection('venta').add(ventaData);
        await db.collection('fila_venta').add({
          ...ventaData,
          'id_inventario': widget.inventarioId,
          'venta_id': ventaRef.id,
          'fecha_creacion': Timestamp.now(),
          'email_user': widget.emailUser ?? 'anon',
        });

        int cantidadPorDescontar = item.cantidadVenta;
        final filasSnap = await db
            .collection('fila_inventario')
            .where('calzado_id', isEqualTo: item.calzadoId)
            .get();

        for (final fila in filasSnap.docs) {
          if (cantidadPorDescontar <= 0) break;
          Query subQuery = db
              .collection('subfila_inventario')
              .where('fila_inventario_id', isEqualTo: fila.id)
              .where('talla', isEqualTo: item.tallaSeleccionada);
          if (item.tipoTieneTaco && item.tacoSeleccionado != null) {
            subQuery = subQuery.where('taco', isEqualTo: item.tacoSeleccionado);
          }
          if (item.tipoTieneColores && item.colorSeleccionado != null) { // 🔥 Descuento color
            subQuery = subQuery.where('colores', isEqualTo: item.colorSeleccionado);
          }
          if (item.tipoTienePlataforma) {
            subQuery = subQuery.where('plataforma',
                isEqualTo: item.plataformaSeleccionada);
          }

          final subfilasSnap = await subQuery.get();
          for (final subDoc in subfilasSnap.docs) {
            if (cantidadPorDescontar <= 0) break;
            final cantidadActual = (subDoc['cantidad'] ?? 0) as int;
            final descuento = cantidadPorDescontar > cantidadActual
                ? cantidadActual
                : cantidadPorDescontar;
            cantidadPorDescontar -= descuento;
            final nuevaCantidad = cantidadActual - descuento;

            if (nuevaCantidad <= 0) {
              await subDoc.reference.delete();
            } else {
              await subDoc.reference.update({'cantidad': nuevaCantidad});
            }
          }
          final subRestantes = await db
              .collection('subfila_inventario')
              .where('fila_inventario_id', isEqualTo: fila.id)
              .get();
          if (subRestantes.docs.isEmpty) {
            await fila.reference.delete();
          } else {
            final nuevaCantFila = subRestantes.docs.fold<int>(
                0, (int sum, d) => sum + ((d['cantidad'] ?? 0) as int));
            await fila.reference.update({'cantidad': nuevaCantFila});
          }
        }
      }
      _ocultarSplashScreen();
      Navigator.pop(context, true);
    } catch (e) {
      _ocultarSplashScreen();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<String?> _obtenerIconoTipo(String id) async {
    if (_iconCache.containsKey(id)) return _iconCache[id];
    final snap = await FirebaseFirestore.instance
        .collection('tipo_calzado')
        .doc(id)
        .get();
    _iconCache[id] = snap.data()?['icono'];
    return _iconCache[id];
  }

  void _mostrarSplashScreen() => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SplashScreen02());
  void _ocultarSplashScreen() =>
      Navigator.of(context, rootNavigator: true).canPop()
          ? Navigator.of(context, rootNavigator: true).pop()
          : null;

  Widget _buildDropdownCalzado(int index) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('calzado')
          .where('id_inventario', isEqualTo: widget.inventarioId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
              labelText: 'Calzado', border: OutlineInputBorder()),
          value: _itemsVenta[index].calzadoId,
          items: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: FutureBuilder<String?>(
                future: _obtenerIconoTipo(data['tipo_calzado_id'] ?? ''),
                builder: (context, iconSnap) => Row(children: [
                  if (iconSnap.data != null)
                    Image.asset(iconSnap.data!, width: 24, height: 24),
                  const SizedBox(width: 8),
                  Text(data['nombre'] ?? 'S/N'),
                ]),
              ),
            );
          }).toList(),
          onChanged: (v) async {
            if (v == null) return;
            final doc = await FirebaseFirestore.instance
                .collection('calzado')
                .doc(v)
                .get();
            final data = doc.data()!;
            setState(() {
              var item = _itemsVenta[index];
              item.calzadoId = v;
              item.tipoTieneTaco = data['taco'] ?? false;
              item.tipoTienePlataforma = data['plataforma'] ?? false;
              item.tipoTieneColores = data['colores'] ?? false;
              item.precioController.text = item.precioVentaTotal == 0.0 ? '' : item.precioVentaTotal.toString();
              item.errorTalla = false;
              item.errorColor = false;
            });
            await _calcularStockPorCalzado(index, v);
          },
        );
      },
    );
  }

  Widget _buildDropdownTalla(int index) {
    var item = _itemsVenta[index];
    if (item.calzadoId == null ||
        item.tallasDisponibles.isEmpty ||
        item.errorTalla) {
      item.errorTalla = false;
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
            labelText: 'Talla', border: OutlineInputBorder()),
        value: item.tallaSeleccionada,
        items: item.tallasDisponibles
            .toSet()
            .map((t) => DropdownMenuItem(value: t, child: Text(t.toString())))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            item.tallaSeleccionada = v;
            item.cantidadVenta = 0;
            item.cantidadController.clear();
          });
          _calcularStockPorTalla(index, v);
        },
      ),
    );
  }

  Widget _buildDropdownColor(int index) {
    var item = _itemsVenta[index];
    if (!item.tipoTieneColores ||
        item.tallaSeleccionada == null ||
        item.coloresDisponibles.isEmpty ||
        item.errorColor) {
      item.errorColor = false;
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
            labelText: 'Color', border: OutlineInputBorder()),
        value: item.colorSeleccionado,
        items: item.coloresDisponibles
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            item.colorSeleccionado = v;
            item.cantidadVenta = 0;
            item.cantidadController.clear();
          });
          _calcularStockPorColor(index, v);
        },
      ),
    );
  }

  Widget _buildDropdownTaco(int index) {
    var item = _itemsVenta[index];
    if (!item.tipoTieneTaco ||
        item.tallaSeleccionada == null ||
        (item.tipoTieneColores && item.colorSeleccionado == null) ||
        item.tacosDisponibles.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: const InputDecoration(
            labelText: 'Taco (cm)', border: OutlineInputBorder()),
        value: item.tacoSeleccionado,
        items: item.tacosDisponibles
            .map((t) => DropdownMenuItem(value: t, child: Text('$t cm')))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            item.tacoSeleccionado = v;
            item.cantidadVenta = 0;
            item.cantidadController.clear();
          });
          _calcularStockPorTaco(index, v);
        },
      ),
    );
  }

  Widget _buildDropdownPlataforma(int index) {
    var item = _itemsVenta[index];
    if (!item.tipoTienePlataforma || item.plataformasDisponibles.isEmpty) {
      return const SizedBox();
    }

    // 🔥 VALIDACIÓN: Previene error de aserción si el valor actual no está en la nueva lista
    if (item.plataformaSeleccionada != null &&
        !item.plataformasDisponibles.contains(item.plataformaSeleccionada)) {
      item.plataformaSeleccionada = null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
            labelText: 'Plataforma',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.layers_outlined)),
        value: item.plataformaSeleccionada,
        items: item.plataformasDisponibles
            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            item.plataformaSeleccionada = v;
            item.cantidadVenta = 0;
            item.cantidadController.clear();
          });
          _calcularStockFinal(index, v);
        },
      ),
    );
  }

  Widget _buildMetodoYLugar(int index) {
    var item = _itemsVenta[index];

    bool listo = item.tallaSeleccionada != null &&
        (!item.tipoTieneColores || item.colorSeleccionado != null) &&
        (!item.tipoTieneTaco || item.tacoSeleccionado != null) &&
        (!item.tipoTienePlataforma || item.plataformaSeleccionada != null);

    if (!listo) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          // Método de Pago
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded:
                  true, // 🔹 Crucial: Fuerza al contenido a ajustarse al ancho
              decoration: const InputDecoration(
                labelText:
                    'Método de Pago', // Acorté un poco el texto para ganar espacio
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10), // Reduce padding interno
              ),
              value: item.metodoPagoSeleccionado,
              items: _metodosPago
                  .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m,
                          overflow: TextOverflow
                              .ellipsis) // 🔹 Evita desborde de texto
                      ))
                  .toList(),
              onChanged: (v) => setState(() => item.metodoPagoSeleccionado = v),
            ),
          ),
          const SizedBox(width: 8),
          // Lugar de Venta
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true, // 🔹 Crucial
              decoration: const InputDecoration(
                labelText: 'Lugar de Venta',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              value: item.lugarVentaSeleccionado,
              items: _lugaresVenta
                  .map((l) => DropdownMenuItem(
                      value: l,
                      child: Text(l,
                          overflow: TextOverflow
                              .ellipsis) // 🔹 Evita desborde de texto
                      ))
                  .toList(),
              onChanged: (v) => setState(() => item.lugarVentaSeleccionado = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCantidadYPrecio(int index) {
  var item = _itemsVenta[index];
  bool listo = item.tallaSeleccionada != null &&
      (!item.tipoTieneColores || item.colorSeleccionado != null) &&
      (!item.tipoTieneTaco || item.tacoSeleccionado != null) &&
      (!item.tipoTienePlataforma || item.plataformaSeleccionada != null);

  if (!listo) return const SizedBox();
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: item.cantidadController,
            decoration: InputDecoration(
                labelText: 'Cantidad',
                border: const OutlineInputBorder(),
                errorText: item.cantidadVenta > item.stockDisponible
                    ? 'Excede stock'
                    : null),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              setState(() {
                item.cantidadVenta = int.tryParse(v) ?? 0;
                if (v.isEmpty || item.cantidadVenta <= 0) {
                  // 🔹 Limpiamos visualmente el controlador
                  item.precioController.clear();
                  // 🔹 Reseteamos la variable a 0.0 internamente
                  item.precioVentaTotal = 0.0; 
                }
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: item.precioController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Precio Total',
              border: OutlineInputBorder(),
              prefixText: 'S/ ',
              hintText: '0.00', // Esto solo se ve cuando el campo está vacío
            ),
            onChanged: (v) {
              setState(() {
                // 🔹 Si el usuario borra el texto, la variable es 0, pero no tocamos el controller
                if (v.isEmpty) {
                  item.precioVentaTotal = 0.0;
                } else {
                  item.precioVentaTotal = double.tryParse(v) ?? 0.0;
                }
              });
            },
          ),
        ),
      ],
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    bool puedeVenderTodo = _itemsVenta.isNotEmpty &&
        _itemsVenta.every((i) =>
            i.calzadoId != null &&
            i.metodoPagoSeleccionado != null && // 🔹 Obligatorio
            i.lugarVentaSeleccionado != null && // 🔹 Obligatorio
            i.tallaSeleccionada != null &&
            i.cantidadVenta > 0 &&
            i.cantidadVenta <= i.stockDisponible &&
            i.precioVentaTotal > 0 &&
            (!i.tipoTienePlataforma || i.plataformaSeleccionada != null));

    return Scaffold(
      appBar: Designwidgets().appBarMain('Nueva Venta Por Mayor'),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _itemsVenta.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Venta #${index + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          if (_itemsVenta.length > 1)
                            IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminarItem(index)),
                        ]),
                    const Divider(),
                    _buildStockIndicator(index),
                    const SizedBox(height: 12),
                    _buildDropdownCalzado(index),
                    _buildDropdownTalla(index),
                    _buildDropdownColor(index),
                    _buildDropdownTaco(index),
                    _buildDropdownPlataforma(index),
                    _buildMetodoYLugar(index),
                    _buildCantidadYPrecio(index),
                  ]),
                ),
              ),
            ),
          ),
          _buildActionButtons(puedeVenderTodo),
        ],
      ),
    );
  }

  Widget _buildStockIndicator(int index) {
    var item = _itemsVenta[index];
    return Container(
      padding: const EdgeInsets.all(8),
      color:
          item.stockDisponible > 0 ? Colors.green.shade50 : Colors.red.shade50,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Stock disponible:'),
        item.cargandoStock
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text('${item.stockDisponible} unidades',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        item.stockDisponible > 0 ? Colors.green : Colors.red)),
      ]),
    );
  }

  Widget _buildActionButtons(bool puedeVenderTodo) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
                onPressed: _agregarNuevoItem,
                icon: const Icon(Icons.add),
                label: const Text('Agregar otro producto'))),
        const SizedBox(height: 12),
        SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      puedeVenderTodo ? Colors.green.shade600 : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.shopping_cart_checkout),
              onPressed: puedeVenderTodo ? _realizarVenta : null,
              label: const Text('Registrar Venta Total'),
            )),
      ]),
    );
  }
}

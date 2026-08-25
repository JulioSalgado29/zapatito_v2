import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/calzado.dart';
import 'package:zapatito_v2/services/API/fila_venta_multiple.dart';

class VentaItem {
  String? calzadoId;
  int? tallaSeleccionada;
  int? tacoSeleccionado;
  String? colorSeleccionado;
  String? plataformaSeleccionada;
  int stockDisponible = 0;
  int cantidadVenta = 0;
  double precioVentaTotal = 0.0;
  bool cargandoStock = false;
  List<int> calzadosDisponibles = [];
  List<int> tallasDisponibles = [];
  List<int> tacosDisponibles = [];
  List<String> coloresDisponibles = [];
  List<String> plataformasDisponibles = [];
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
  List<Map<String, dynamic>> _listaCalzados = [];
  bool _cargandoCalzados = true;

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
  List<int> _tallasInventario = [];

  @override
  void initState() {
    super.initState();
    _cargarTallasInicialesInventario();
    _cargarCalzados();
    _agregarNuevoItem();
  }

  Future<void> _cargarTallasInicialesInventario() async {
    // Llama a la API pasándole solo el idInventario actual
    final res = await FilaVentaMultipleService.consultarStockCascada(
      idInventario: widget.inventarioId,
    );

    if (res != null && res['tallas_disponibles'] != null) {
      setState(() {
        _tallasInventario = List<int>.from(res['tallas_disponibles']);
      });
    }
  }

  @override
  void dispose() {
    for (var item in _itemsVenta) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarCalzados() async {
    try {
      final data =
          await CalzadoService.obtenerPorInventario(widget.inventarioId);
      if (mounted) {
        setState(() {
          _listaCalzados = data;
          _cargandoCalzados = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargandoCalzados = false);
    }
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

  Future<void> _actualizarStockCascada(int index) async {
    if (index >= _itemsVenta.length) return;
    var item = _itemsVenta[index];

    // Si ambos son null o no hay inventarioId, no hay nada que consultar
    if ((item.calzadoId == null && item.tallaSeleccionada == null) ||
        widget.inventarioId == null) {
      return;
    }

    setState(() => item.cargandoStock = true);

    try {
      final data = await FilaVentaMultipleService.consultarStockCascada(
        idCalzado: item.calzadoId,
        idInventario: widget.inventarioId!,
        talla: item.tallaSeleccionada,
        colores: item.colorSeleccionado,
        taco: item.tacoSeleccionado,
      );

      print('Datos recibidos para stock cascada: $data');

      if (data != null && mounted) {
        setState(() {
          item.stockDisponible =
              (data['stock_disponible'] ?? data['stock'] ?? 0) as int;

          final rawCalzados =
              data['calzados_disponibles'] ?? data['calzados'] ?? [];
          item.calzadosDisponibles = List<int>.from(
            (rawCalzados as List)
                .map((c) => int.tryParse(c.toString()) ?? 0)
                .where((c) => c > 0),
          );

          print(data);
          final rawTallas = data['tallas_disponibles'];

          if (item.calzadoId != null && rawTallas == null) {
            item.tallasDisponibles = [];
            item.tallaSeleccionada = null;
          } else {
            final listaBase = rawTallas ?? data['tallas'] ?? [];
            item.tallasDisponibles = List<int>.from(
              (listaBase as List)
                  .map((t) => int.tryParse(t.toString()) ?? 0)
                  .where((t) => t > 0),
            );

            if (item.tallasDisponibles.isEmpty) {
              item.tallaSeleccionada = null;
            }
          }

          final rawColores =
              data['colores_disponibles'] ?? data['colores'] ?? [];
          item.coloresDisponibles = List<String>.from(
            (rawColores as List).map((c) => c.toString()),
          );

          final rawTacos = data['tacos_disponibles'] ?? data['tacos'] ?? [];
          item.tacosDisponibles = List<int>.from(
            (rawTacos as List)
                .map((t) => int.tryParse(t.toString()) ?? 0)
                .where((t) => t > 0),
          );

          final rawPlataformas =
              data['plataformas_disponibles'] ?? data['plataformas'] ?? [];
          item.plataformasDisponibles = List<String>.from(
            (rawPlataformas as List).map((p) => p.toString()),
          );

          item.cargandoStock = false;
        });

        if (_esCombinacionDuplicada(index)) {
          _notificarDuplicado(index);
        }
      } else if (mounted) {
        setState(() => item.cargandoStock = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => item.cargandoStock = false);
      }
    }
  }

  void _notificarDuplicado(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Esta combinación de producto ya existe en la lista de venta.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
    setState(() {
      _itemsVenta[index].tallaSeleccionada = null;
      _itemsVenta[index].colorSeleccionado = null;
      _itemsVenta[index].tacoSeleccionado = null;
      _itemsVenta[index].plataformaSeleccionada = null;
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
      final List<Map<String, dynamic>> itemsPayload = _itemsVenta.map((item) {
        return {
          'id_calzado': item.calzadoId,
          'talla': item.tallaSeleccionada,
          'taco': item.tipoTieneTaco ? (item.tacoSeleccionado ?? 0) : 0,
          'colores':
              item.tipoTieneColores ? (item.colorSeleccionado ?? '') : '',
          'plataforma': item.tipoTienePlataforma
              ? (item.plataformaSeleccionada ?? '')
              : '',
          'cantidad': item.cantidadVenta,
          'precio_venta_total': item.precioVentaTotal,
          'metodo_pago': item.metodoPagoSeleccionado,
          'lugar_venta': item.lugarVentaSeleccionado,
        };
      }).toList();

      final exito = await FilaVentaMultipleService.registrarVentaMultiple(
        idInventario: widget.inventarioId ?? '',
        usuarioCreacion: widget.firstName ?? 'anon',
        emailUser: widget.emailUser ?? 'anon',
        items: itemsPayload,
      );

      _ocultarSplashScreen();

      if (exito) {
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al registrar la venta.')),
          );
        }
      }
    } catch (e) {
      _ocultarSplashScreen();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $e')),
        );
      }
    }
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
    if (_cargandoCalzados) return const LinearProgressIndicator();

    final item = _itemsVenta[index];

    final calzadosFiltrados = item.calzadosDisponibles.isNotEmpty
        ? _listaCalzados.where((c) {
            final id = int.tryParse(c['id_calzado'].toString());
            return item.calzadosDisponibles.contains(id);
          }).toList()
        : _listaCalzados;

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Calzado',
        border: OutlineInputBorder(),
      ),
      value: calzadosFiltrados
              .any((c) => c['id_calzado'].toString() == item.calzadoId)
          ? item.calzadoId
          : null,
      items: calzadosFiltrados.map((calzado) {
        final idStr = calzado['id_calzado'].toString();
        final icono = calzado['icono'];
        return DropdownMenuItem(
          value: idStr,
          child: Row(
            children: [
              if (icono != null && icono.isNotEmpty)
                Image.asset(
                  icono,
                  width: 24,
                  height: 24,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported, size: 24),
                ),
              const SizedBox(width: 8),
              Text(calzado['nombre'] ?? 'S/N'),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v == null) return;
        final calzadoSel =
            _listaCalzados.firstWhere((c) => c['id_calzado'].toString() == v);

        setState(() {
          item.calzadoId = v;
          item.tipoTieneTaco = calzadoSel['taco'] ?? false;
          item.tipoTienePlataforma = calzadoSel['plataforma'] ?? false;
          item.tipoTieneColores = calzadoSel['colores'] ?? false;
        });

        _actualizarStockCascada(index);
      },
    );
  }

  Widget _buildDropdownTalla(int index) {
    var item = _itemsVenta[index];

    // Si ya seleccionó un calzado, se respeta ÚNICAMENTE su lista de tallas (aunque esté vacía).
    // Si NO ha seleccionado calzado, se muestran todas las tallas del inventario general.
    final listadoTallas = item.calzadoId != null
        ? item.tallasDisponibles
        : _tallasInventario;

    final estaHabilitado = listadoTallas.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        decoration: InputDecoration(
          labelText: 'Talla',
          border: const OutlineInputBorder(),
          hintText: item.calzadoId != null && listadoTallas.isEmpty
              ? 'Sin tallas disponibles'
              : 'Seleccione talla',
        ),
        // Si el listado no contiene la talla elegida previamente, pasa a null
        value: listadoTallas.contains(item.tallaSeleccionada)
            ? item.tallaSeleccionada
            : null,
        // Si no hay tallas disponibles para ese calzado, deshabilitamos el Dropdown (onChanged: null)
        onChanged: estaHabilitado
            ? (v) {
                if (v == null) return;
                setState(() {
                  item.tallaSeleccionada = v;
                  item.colorSeleccionado = null;
                  item.tacoSeleccionado = null;
                  item.plataformaSeleccionada = null;
                  item.cantidadVenta = 0;
                  item.cantidadController.clear();
                });
                _actualizarStockCascada(index);
              }
            : null,
        items: listadoTallas
            .map((t) => DropdownMenuItem(value: t, child: Text(t.toString())))
            .toList(),
      ),
    );
  }

  Widget _buildDropdownColor(int index) {
    var item = _itemsVenta[index];
    if (!item.tipoTieneColores ||
        item.tallaSeleccionada == null || item.calzadoId == null ||
        item.coloresDisponibles.isEmpty) {
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
            item.tacoSeleccionado = null;
            item.plataformaSeleccionada = null;
            item.cantidadVenta = 0;
            item.cantidadController.clear();
          });
          _actualizarStockCascada(index);
        },
      ),
    );
  }

  Widget _buildDropdownTaco(int index) {
    var item = _itemsVenta[index];
    if (!item.tipoTieneTaco ||
        item.tallaSeleccionada == null ||
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
            item.plataformaSeleccionada = null;
            item.cantidadVenta = 0;
            item.cantidadController.clear();
          });
          _actualizarStockCascada(index);
        },
      ),
    );
  }

  Widget _buildDropdownPlataforma(int index) {
    var item = _itemsVenta[index];
    if (!item.tipoTienePlataforma || item.plataformasDisponibles.isEmpty) {
      return const SizedBox();
    }

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
          _actualizarStockCascada(index);
        },
      ),
    );
  }

  Widget _buildMetodoYLugar(int index) {
    var item = _itemsVenta[index];

    bool listo = item.tallaSeleccionada != null && item.calzadoId != null &&
        (!item.tipoTieneColores || item.colorSeleccionado != null) &&
        (!item.tipoTieneTaco || item.tacoSeleccionado != null) &&
        (!item.tipoTienePlataforma || item.plataformaSeleccionada != null);

    if (!listo) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Método de Pago',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              value: item.metodoPagoSeleccionado,
              items: _metodosPago
                  .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => item.metodoPagoSeleccionado = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
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
                      child: Text(l, overflow: TextOverflow.ellipsis)))
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
    bool listo = item.tallaSeleccionada != null && item.calzadoId != null &&
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
                    item.precioController.clear();
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Precio Total',
                border: OutlineInputBorder(),
                prefixText: 'S/ ',
                hintText: '0.00',
              ),
              onChanged: (v) {
                setState(() {
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
            i.metodoPagoSeleccionado != null &&
            i.lugarVentaSeleccionado != null &&
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
              onPressed: puedeVenderTodo ? _realizarVenta : null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Registrar Todas las Ventas',
                  style: TextStyle(fontSize: 16)),
            )),
      ]),
    );
  }
}
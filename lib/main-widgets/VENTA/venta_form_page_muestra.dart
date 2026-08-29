import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/calzado.dart';
import 'package:zapatito_v2/services/API/dueno_muestra.dart';
import 'package:zapatito_v2/services/API/fila_venta.dart';

// Modelo para manejar cada fila de venta independiente
class VentaItem {
  String? duenoMuestraId;
  String? calzadoId;
  int? tallaSeleccionada;
  int? tacoSeleccionado;
  String? colorSeleccionado;
  String? plataformaSeleccionada;

  int cantidadVenta = 0;
  double precioVentaTotal = 0.0;

  bool muestra = true;

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

class VentaFormPageMuestra extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  const VentaFormPageMuestra({
    super.key,
    required this.firstName,
    this.emailUser,
    this.inventarioId,
  });

  @override
  State<VentaFormPageMuestra> createState() => _VentaFormPageMuestraState();
}

class _VentaFormPageMuestraState extends State<VentaFormPageMuestra> {
  final List<VentaItem> _itemsVenta = [];

  // Data general que solo se consulta 1 vez
  List<Map<String, dynamic>> _duenosMuestra = [];
  List<Map<String, dynamic>> _calzados = [];
  
  // Caché de detalles de calzado (para no reconsultar si ya se trajo una vez)
  final Map<String, Map<String, dynamic>> _calzadoDetallesCache = {};

  bool _cargandoInicial = true;

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
    _cargarDatosIniciales();
  }

  // 🔹 Carga de data por única vez al iniciar la pantalla
  Future<void> _cargarDatosIniciales() async {
    if (widget.inventarioId == null) {
      setState(() => _cargandoInicial = false);
      return;
    }

    try {
      final duenosFuturo =
          DuenoMuestraService.obtenerPorInventario(widget.inventarioId!);
      final calzadosFuturo =
          CalzadoService.obtenerPorInventario(widget.inventarioId!);

      final resultados = await Future.wait([duenosFuturo, calzadosFuturo]);

      if (mounted) {
        setState(() {
          _duenosMuestra = resultados[0];
          _calzados = resultados[1];
          _cargandoInicial = false;
        });
        _agregarNuevoItem();
      }
    } catch (e) {
      print('Error al cargar datos iniciales: $e');
      if (mounted) {
        setState(() => _cargandoInicial = false);
      }
    }
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

  Future<void> _realizarVenta() async {
    _mostrarSplashScreen();
    try {
      for (var item in _itemsVenta) {
        final ventaData = {
          'id_inventario': widget.inventarioId,
          'id_dueno_muestra': item.duenoMuestraId,
          'id_calzado': item.calzadoId,
          'talla': item.tallaSeleccionada,
          'taco': item.tipoTieneTaco ? item.tacoSeleccionado ?? 0 : 0,
          'colores': item.tipoTieneColores ? item.colorSeleccionado ?? '' : '',
          'plataforma':
              item.tipoTienePlataforma ? item.plataformaSeleccionada ?? '' : '',
          'cantidad': item.cantidadVenta,
          'precio_venta_total': item.precioVentaTotal,
          'metodo_pago': item.metodoPagoSeleccionado,
          'lugar_venta': item.lugarVentaSeleccionado,
          'usuario_creacion': widget.firstName ?? 'anon',
          'email_user': widget.emailUser ?? 'anon',
          'muestra': item.muestra,
        };

        final exito = await FilaVentaService.crearVenta(ventaData);

        if (!exito) {
          throw Exception('No se pudo registrar la venta/muestra.');
        }
      }

      _ocultarSplashScreen();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _ocultarSplashScreen();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildDropdownDueno(int index) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
          labelText: 'Dueño de Muestra', border: OutlineInputBorder()),
      value: _itemsVenta[index].duenoMuestraId,
      items: _duenosMuestra
          .map((item) => DropdownMenuItem(
                value: item['id_dueno_muestra'].toString(),
                child: Text(item['nombre'] ?? ''),
              ))
          .toList(),
      onChanged: (v) => setState(() => _itemsVenta[index].duenoMuestraId = v),
    );
  }

  Widget _buildDropdownCalzado(int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
            labelText: 'Calzado', border: OutlineInputBorder()),
        value: _itemsVenta[index].calzadoId,
        items: _calzados.map((data) {
          final String idStr = data['id_calzado'].toString();
          final String? icono = data['icono'];
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
                Text(data['nombre'] ?? 'S/N'),
              ],
            ),
          );
        }).toList(),
        onChanged: (v) async {
          if (v == null) return;
          
          Map<String, dynamic>? data;

          // Si ya existe en caché, evitamos consultar la API de nuevo
          if (_calzadoDetallesCache.containsKey(v)) {
            data = _calzadoDetallesCache[v];
          } else {
            data = await CalzadoService.obtenerPorId(v);
            if (data != null) {
              _calzadoDetallesCache[v] = data;
            }
          }

          if (data != null && mounted) {
            setState(() {
              var item = _itemsVenta[index];
              item.calzadoId = v;
              item.tipoTieneTaco = data!['taco'] ?? false;
              item.tipoTienePlataforma = data['plataforma'] ?? false;
              item.tipoTieneColores = data['colores'] ?? false;
            });
          }
        },
      ),
    );
  }

  Widget _buildCascadaAtributos(int index) {
    var item = _itemsVenta[index];
    if (item.calzadoId == null) return const SizedBox();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<int>(
            decoration: const InputDecoration(
                labelText: 'Talla', border: OutlineInputBorder()),
            value: item.tallaSeleccionada,
            items: List.generate(11, (i) => i + 30)
                .map((t) =>
                    DropdownMenuItem(value: t, child: Text(t.toString())))
                .toList(),
            onChanged: (v) => setState(() => item.tallaSeleccionada = v),
          ),
        ),
        if (item.tipoTieneColores)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.palette)),
              onChanged: (v) => setState(() => item.colorSeleccionado = v),
            ),
          ),
        if (item.tipoTieneTaco)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                  labelText: 'Taco (cm)', border: OutlineInputBorder()),
              value: item.tacoSeleccionado,
              items: [3, 5, 7, 9]
                  .map((t) => DropdownMenuItem(value: t, child: Text('$t cm')))
                  .toList(),
              onChanged: (v) => setState(() => item.tacoSeleccionado = v),
            ),
          ),
        if (item.tipoTienePlataforma)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                  labelText: 'Plataforma', border: OutlineInputBorder()),
              value: item.plataformaSeleccionada,
              items: ['Baja', 'Media', 'Alta']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => item.plataformaSeleccionada = v),
            ),
          ),
      ],
    );
  }

  Widget _buildPagoYLugar(int index) {
    var item = _itemsVenta[index];
    if (item.calzadoId == null) return const SizedBox();

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
                  contentPadding: EdgeInsets.symmetric(horizontal: 10)),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 10)),
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
    if (item.calzadoId == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: item.cantidadController,
              decoration: const InputDecoration(
                  labelText: 'Cantidad', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                setState(() {
                  item.cantidadVenta = int.tryParse(v) ?? 0;
                  if (item.cantidadVenta <= 0) {
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

  void _mostrarSplashScreen() => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SplashScreen02());

  void _ocultarSplashScreen() =>
      Navigator.of(context, rootNavigator: true).canPop()
          ? Navigator.of(context, rootNavigator: true).pop()
          : null;

  @override
  Widget build(BuildContext context) {
    if (_cargandoInicial) {
      return Scaffold(
        appBar: Designwidgets().appBarMain('Venta por Muestra'),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    bool puedeVenderTodo = _itemsVenta.isNotEmpty &&
        _itemsVenta.every((i) =>
            i.calzadoId != null &&
            i.duenoMuestraId != null &&
            i.tallaSeleccionada != null &&
            i.metodoPagoSeleccionado != null &&
            i.lugarVentaSeleccionado != null &&
            i.cantidadVenta > 0 &&
            i.precioVentaTotal > 0);

    return Scaffold(
      appBar: Designwidgets().appBarMain('Venta por Muestra'),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _itemsVenta.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Venta #${index + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          if (_itemsVenta.length > 1)
                            IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _eliminarItem(index)),
                        ]),
                    const Divider(),
                    _buildDropdownDueno(index),
                    _buildDropdownCalzado(index),
                    _buildCascadaAtributos(index),
                    _buildPagoYLugar(index),
                    _buildCantidadYPrecio(index),
                  ]),
                ),
              ),
            ),
          ),
          _buildFooter(puedeVenderTodo),
        ],
      ),
    );
  }

  Widget _buildFooter(bool puedeVenderTodo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
      ]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
              label: const Text('Registrar Venta Muestra'),
            )),
      ]),
    );
  }
}
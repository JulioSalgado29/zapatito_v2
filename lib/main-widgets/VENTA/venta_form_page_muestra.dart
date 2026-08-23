import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';

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
  
  // 🔹 NUEVA ETIQUETA: Identificador de muestra
  bool muestra = true;

  bool tipoTieneTaco = false;
  bool tipoTienePlataforma = false;
  bool tipoTieneColores = false;

  String? metodoPagoSeleccionado;
  String? lugarVentaSeleccionado;

  final TextEditingController cantidadController = TextEditingController();
  // 🔹 El controlador nace vacío para evitar el 0.0 visual
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

  const VentaFormPageMuestra(
      {super.key, required this.firstName, this.emailUser, this.inventarioId});

  @override
  State<VentaFormPageMuestra> createState() => _VentaFormPageMuestraState();
}

class _VentaFormPageMuestraState extends State<VentaFormPageMuestra> {
  final List<VentaItem> _itemsVenta = [];
  final Map<String, String?> _iconCache = {};

  final List<String> _metodosPago = [
    'Efectivo', 'Yape', 'Plin', 'Transferencia', 'POS', 
    'Efectivo y Yape', 'Efectivo y Plin', 'Efectivo y Transferencia', 'Efectivo y POS'
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

  Future<void> _realizarVenta() async {
    _mostrarSplashScreen();
    try {
      final db = FirebaseFirestore.instance;
      for (var item in _itemsVenta) {
        final ventaData = {
          'dueno_muestra_id': item.duenoMuestraId,
          'calzado_id': item.calzadoId,
          'talla': item.tallaSeleccionada,
          'taco': item.tipoTieneTaco ? item.tacoSeleccionado ?? 0 : 0,
          'colores': item.tipoTieneColores ? item.colorSeleccionado ?? '' : '',
          'plataforma': item.tipoTienePlataforma ? item.plataformaSeleccionada ?? '' : '',
          'cantidad': item.cantidadVenta,
          'precio_venta_total': item.precioVentaTotal,
          'metodo_pago': item.metodoPagoSeleccionado,
          'lugar_venta': item.lugarVentaSeleccionado,
          'fecha_venta': Timestamp.now(),
          'usuario_creacion': widget.firstName ?? 'anon',
          // 🔹 REGISTRO DE ETIQUETA EN FIREBASE
          'muestra': item.muestra, 
        };

        final ventaRef = await db.collection('venta').add(ventaData);
        await db.collection('fila_venta').add({
          ...ventaData,
          'id_inventario': widget.inventarioId,
          'venta_id': ventaRef.id,
          'fecha_creacion': Timestamp.now(),
          'email_user': widget.emailUser ?? 'anon',
          // 🔹 TAMBIÉN EN FILA_VENTA
          'muestra': item.muestra, 
        });
      }
      _ocultarSplashScreen();
      Navigator.pop(context, true);
    } catch (e) {
      _ocultarSplashScreen();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // --- WIDGETS DE FORMULARIO ---

  // ... (Tus otros widgets _buildDropdownDueno, _buildDropdownCalzado, _buildCascadaAtributos, _buildPagoYLugar se mantienen igual)

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
              decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  // ... (El resto del código del Scaffold y Footer se mantiene igual)

  // (Implementación de placeholders para que el código sea funcional)
  Widget _buildDropdownDueno(int index) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('dueno_muestra').where('estado', isEqualTo: true).where('id_inventario', isEqualTo: widget.inventarioId).orderBy('nombre', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Dueño de Muestra', border: OutlineInputBorder()),
          value: _itemsVenta[index].duenoMuestraId,
          items: snapshot.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['nombre']))).toList(),
          onChanged: (v) => setState(() => _itemsVenta[index].duenoMuestraId = v),
        );
      },
    );
  }

  Widget _buildDropdownCalzado(int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('calzado').where('id_inventario', isEqualTo: widget.inventarioId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          return DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Calzado', border: OutlineInputBorder()),
            value: _itemsVenta[index].calzadoId,
            items: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return DropdownMenuItem(
                value: doc.id,
                child: FutureBuilder<String?>(
                  future: _obtenerIconoTipo(data['tipo_calzado_id'] ?? ''),
                  builder: (context, iconSnap) => Row(children: [
                    if (iconSnap.data != null) Image.asset(iconSnap.data!, width: 24, height: 24),
                    const SizedBox(width: 8),
                    Text(data['nombre'] ?? 'S/N'),
                  ]),
                ),
              );
            }).toList(),
            onChanged: (v) async {
              if (v == null) return;
              final doc = await FirebaseFirestore.instance.collection('calzado').doc(v).get();
              final data = doc.data()!;
              setState(() {
                var item = _itemsVenta[index];
                item.calzadoId = v;
                item.tipoTieneTaco = data['taco'] ?? false;
                item.tipoTienePlataforma = data['plataforma'] ?? false;
                item.tipoTieneColores = data['colores'] ?? false;
              });
            },
          );
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
            decoration: const InputDecoration(labelText: 'Talla', border: OutlineInputBorder()),
            items: List.generate(11, (i) => i + 30).map((t) => DropdownMenuItem(value: t, child: Text(t.toString()))).toList(),
            onChanged: (v) => setState(() => item.tallaSeleccionada = v),
          ),
        ),
        if (item.tipoTieneColores)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder(), prefixIcon: Icon(Icons.palette)),
              onChanged: (v) => setState(() => item.colorSeleccionado = v),
            ),
          ),
        if (item.tipoTieneTaco)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Taco (cm)', border: OutlineInputBorder()),
              items: [3, 5, 7, 9].map((t) => DropdownMenuItem(value: t, child: Text('$t cm'))).toList(),
              onChanged: (v) => setState(() => item.tacoSeleccionado = v),
            ),
          ),
        if (item.tipoTienePlataforma)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Plataforma', border: OutlineInputBorder()),
              items: ['Baja', 'Media', 'Alta'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
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
              decoration: const InputDecoration(labelText: 'Método de Pago', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
              value: item.metodoPagoSeleccionado,
              items: _metodosPago.map((m) => DropdownMenuItem(value: m, child: Text(m, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => item.metodoPagoSeleccionado = v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Lugar de Venta', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
              value: item.lugarVentaSeleccionado,
              items: _lugaresVenta.map((l) => DropdownMenuItem(value: l, child: Text(l, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => item.lugarVentaSeleccionado = v),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _obtenerIconoTipo(String id) async {
    if (_iconCache.containsKey(id)) return _iconCache[id];
    final snap = await FirebaseFirestore.instance.collection('tipo_calzado').doc(id).get();
    _iconCache[id] = snap.data()?['icono'];
    return _iconCache[id];
  }

  void _mostrarSplashScreen() => showDialog(context: context, barrierDismissible: false, builder: (_) => const SplashScreen02());
  void _ocultarSplashScreen() => Navigator.of(context, rootNavigator: true).canPop() ? Navigator.of(context, rootNavigator: true).pop() : null;

  @override
  Widget build(BuildContext context) {
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
      appBar: Designwidgets().appBarMain('Nueva Venta Muestra'),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _itemsVenta.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Venta #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (_itemsVenta.length > 1) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _eliminarItem(index)),
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
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _agregarNuevoItem, icon: const Icon(Icons.add), label: const Text('Agregar otro producto'))),
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
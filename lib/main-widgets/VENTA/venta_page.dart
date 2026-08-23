import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/MAIN/home_page.dart';
import 'package:zapatito_v2/main-widgets/VENTA/venta_form_page.dart';
import 'package:zapatito_v2/main-widgets/VENTA/venta_form_page_muestra.dart';
import 'package:zapatito_v2/main-widgets/VENTA/venta_form_page_multiple.dart';

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
  final Map<String, Map<String, dynamic>> _calzadoCache = {};
  DateTime _fechaFiltro = DateTime.now();

  @override
  void initState() {
    super.initState();
    _verificarInventario();
  }

  // --- LÓGICA DE ELIMINACIÓN Y REVERSA CORREGIDA ---
  Future<void> _eliminarVentaConReversa(
      String filaVentaId, Map<String, dynamic> data) async {
    // 🔹 Determinar si es una muestra para cambiar el comportamiento
    final bool esMuestra = data['muestra'] ?? false;

    bool confirm = await showDialog(
          context: context,
          builder: (ctx) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            elevation: 20,
            backgroundColor:
                Colors.transparent, // Para que el Container maneje el fondo
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
                      // BOTÓN CANCELAR
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
                      // BOTÓN ELIMINAR
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
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      // 🔹 SOLO SI NO ES MUESTRA: Se modifica el inventario
      if (!esMuestra) {
        // 1. Localizar la fila_inventario (el contenedor principal del código)
        final filasSnap = await db
            .collection('fila_inventario')
            .where('calzado_id', isEqualTo: data['calzado_id'])
            .where('inventario_id', isEqualTo: widget.inventarioId)
            .limit(1)
            .get();

        DocumentReference filaRef;
        String filaId;

        if (filasSnap.docs.isEmpty) {
          // 🔹 NO EXISTE LA FILA PRINCIPAL: La creamos de nuevo
          filaRef = db.collection('fila_inventario').doc();
          filaId = filaRef.id;

          batch.set(filaRef, {
            'calzado_id': data['calzado_id'],
            'inventario_id': widget.inventarioId,
            'cantidad': data['cantidad'], // Empezamos con la cantidad devuelta
            'fecha_creacion': Timestamp.now(),
            'email': widget.emailUser,
            'usuario_creacion': widget.firstName
          });
        } else {
          // SI EXISTE: Obtenemos referencia e incrementamos
          final filaDoc = filasSnap.docs.first;
          filaRef = filaDoc.reference;
          filaId = filaDoc.id;

          batch.update(
              filaRef, {'cantidad': FieldValue.increment(data['cantidad'])});
        }

// 2. Buscar si la subfila existe
        final subfilasSnap = await db
            .collection('subfila_inventario')
            .where('fila_inventario_id', isEqualTo: filaId)
            .where('talla', isEqualTo: data['talla'])
            .where('colores', isEqualTo: data['colores'] ?? '')
            .where('taco', isEqualTo: data['taco'] ?? 0)
            .where('plataforma', isEqualTo: data['plataforma'] ?? '')
            .limit(1)
            .get();

        if (subfilasSnap.docs.isNotEmpty) {
          // SI EXISTE LA SUBFILA: Solo incrementamos
          batch.update(subfilasSnap.docs.first.reference,
              {'cantidad': FieldValue.increment(data['cantidad'])});
        } else {
          // NO EXISTE LA SUBFILA: La creamos
          final nuevaSubfilaRef = db.collection('subfila_inventario').doc();
          batch.set(nuevaSubfilaRef, {
            'fila_inventario_id': filaId,
            'talla': data['talla'],
            'colores': data['colores'] ?? '',
            'taco': data['taco'] ?? 0,
            'plataforma': data['plataforma'] ?? '',
            'cantidad': data['cantidad'],
          });
        }
      }

      // 4. Eliminar los registros de venta (Esto se hace siempre)
      batch.delete(db.collection('fila_venta').doc(filaVentaId));
      if (data['venta_id'] != null) {
        batch.delete(db.collection('venta').doc(data['venta_id']));
      }

      await batch.commit();

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(esMuestra
              ? 'Muestra eliminada.'
              : 'Venta eliminada y stock restaurado.')));
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al procesar: $e')));
    }
  }

  Stream<QuerySnapshot> _getFilasVenta() {
    DateTime inicioDia =
        DateTime(_fechaFiltro.year, _fechaFiltro.month, _fechaFiltro.day);
    DateTime finDia = DateTime(
        _fechaFiltro.year, _fechaFiltro.month, _fechaFiltro.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('fila_venta')
        .where('id_inventario', isEqualTo: widget.inventarioId)
        .where('fecha_creacion',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
        .where('fecha_creacion',
            isLessThanOrEqualTo: Timestamp.fromDate(finDia))
        .orderBy('fecha_creacion', descending: true)
        .snapshots();
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
    }
  }

  Future<void> _verificarInventario() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('inventario')
          .doc(widget.inventarioId)
          .get();
      if (!docSnapshot.exists) {
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
      }
    } catch (e) {
      print("Error de inventario: $e");
    }
  }

  String _formatFechaLarga(dynamic timestamp) {
    if (timestamp == null) return 'Sin fecha';
    try {
      final DateTime dt = (timestamp as Timestamp).toDate();
      String dia = DateFormat('EEEE', 'es_ES').format(dt);
      String resto = DateFormat("d 'de' MMMM - yyyy", "es_ES").format(dt);
      String hora = DateFormat('hh:mm a').format(dt);
      return "${dia[0].toUpperCase()}${dia.substring(1)} - $resto ($hora)";
    } catch (e) {
      return 'Fecha no válida';
    }
  }

  Future<Map<String, dynamic>> _getDatosCalzado(String calzadoId) async {
    if (_calzadoCache.containsKey(calzadoId)) return _calzadoCache[calzadoId]!;
    final snap = await FirebaseFirestore.instance
        .collection('calzado')
        .doc(calzadoId)
        .get();
    Map<String, dynamic> result =
        snap.exists ? snap.data()! : {'nombre': 'Sin nombre', 'icono': null};
    _calzadoCache[calzadoId] = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inventarioId == null) return const SplashScreen02();
    bool esHoy = DateFormat('dd/MM/yyyy').format(_fechaFiltro) ==
        DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff5b16c2),
        foregroundColor: Colors.white,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Ventas Realizadas',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Georgia')),
        actions: [
          IconButton(
              icon: const Icon(Icons.today),
              onPressed: () => setState(() => _fechaFiltro = DateTime.now())),
          IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => _seleccionarFecha(context)),
        ],
      ),
      drawer:
          Designwidgets().drawerHome(context, widget.firstName ?? "Invitado"),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: esHoy ? Colors.green.shade50 : Colors.blue.shade50,
              child: Text(
                esHoy
                    ? 'Ventas de Hoy: ${DateFormat('dd/MM/yyyy').format(_fechaFiltro)}'
                    : 'Filtrado: ${DateFormat('dd/MM/yyyy').format(_fechaFiltro)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: esHoy ? Colors.green.shade900 : Colors.blue.shade900,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getFilasVenta(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error de conexión.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text(esHoy
                            ? 'Aún no hay ventas registradas hoy.'
                            : 'No hay ventas para esta fecha.'));
                  }
                  final filas = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 150),
                    itemCount: filas.length,
                    itemBuilder: (context, index) =>
                        _buildVentaCard(filas[index]),
                  );
                },
              ),
            ),
          ],
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
              _navegarFormularioMultiple, "Por Mayor"),
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

  Future<Map<String, dynamic>> _getDatosDuenoMuestra(String? id) async {
    if (id == null || id.isEmpty) return {};
    try {
      final doc = await FirebaseFirestore.instance
          .collection('dueno_muestra')
          .doc(id)
          .get();
      return doc.data() ?? {};
    } catch (e) {
      return {};
    }
  }

  Widget _buildVentaCard(QueryDocumentSnapshot fila) {
    final filaId = fila.id;
    final filaData = fila.data() as Map<String, dynamic>;
    final bool esMuestra = filaData['muestra'] ?? false;
    final String? duenoMuestraId = filaData['dueno_muestra_id']; // ID del dueño

    final DateTime fechaVenta =
        (filaData['fecha_creacion'] as Timestamp).toDate();
    final bool esVentaDeHoy = DateFormat('dd/MM/yyyy').format(fechaVenta) ==
        DateFormat('dd/MM/yyyy').format(DateTime.now());

    return FutureBuilder<List<Map<String, dynamic>>>(
      // 1. Ejecutamos ambas consultas en paralelo para mayor velocidad
      future: Future.wait([
        _getDatosCalzado(filaData['calzado_id'] ?? ''),
        _getDatosDuenoMuestra(duenoMuestraId), // Nueva función
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final calzadoData = snapshot.data![0];
        final duenoData = snapshot.data![1];
        final precioTotal = (filaData['precio_venta_total'] ?? 0.0).toDouble();

        return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              // 🔹 2. Banner superior si es muestra
              if (esMuestra)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Text(
                    'MUESTRA DE ${(duenoData['nombre'] ?? "Desconocido")}'
                        .toUpperCase(),
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
                // Si es muestra, quitamos el redondeo superior del Tile para que encaje con el banner
                shape: const Border(),
                leading: _buildIcon(calzadoData['icono']),
                title: Text(calzadoData['nombre'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
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
                              filaData['colores'] != false)
                            _miniChip(
                                'Color: ${filaData['colores']}', Colors.purple),
                          if (filaData['taco'] != null && filaData['taco'] != 0)
                            _miniChip(
                                'Taco: ${filaData['taco']}', Colors.orange),
                          if (filaData['plataforma'] != null &&
                              filaData['plataforma'] != '' &&
                              filaData['plataforma'] != false)
                            _miniChip(
                                'Plat: ${filaData['plataforma']}', Colors.blue),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // ... resto del código (fecha y botones) igual ...
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
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
                              child: Text(
                                  _formatFechaLarga(filaData['fecha_creacion']),
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
                  _buildDetalleRow(Icons.shopping_bag, 'Cantidad Vendida',
                      filaData['cantidad'].toString()),
                  _buildDetalleRow(Icons.straighten, 'Talla Seleccionada',
                      filaData['talla'].toString()),
                  _buildDetalleRow(Icons.monetization_on, 'Precio de Venta',
                      'S/ ${precioTotal.toStringAsFixed(2)}'),
                  _buildDetalleRow(Icons.payments, 'Método de Pago',
                      filaData['metodo_pago'] ?? 'N/A'),
                  _buildDetalleRow(Icons.storefront, 'Lugar de Venta',
                      filaData['lugar_venta'] ?? 'N/A'),
                  _buildDetalleRow(Icons.person, 'Vendedor',
                      filaData['usuario_creacion'] ?? 'Desconocido'),
                  if (esVentaDeHoy)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => VentaFormPage(
                                          firstName: widget.firstName,
                                          emailUser: widget.emailUser,
                                          inventarioId: widget.inventarioId,
                                          ventaId: filaId,
                                          datosEdicion: filaData)));
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
            ]));
      },
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
  void _navegarFormularioMultiple() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => VentaFormPageMultiple(
              firstName: widget.firstName,
              emailUser: widget.emailUser,
              inventarioId: widget.inventarioId)));
  void _navegarFormularioMuestra() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => VentaFormPageMuestra(
              firstName: widget.firstName,
              emailUser: widget.emailUser,
              inventarioId: widget.inventarioId)));

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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/tipo_calzado.dart';

class InventarioSerieFormPage extends StatefulWidget {
  final String? firstName;
  final String? inventarioId;
  final String? emailUser;

  const InventarioSerieFormPage({
    super.key,
    required this.firstName,
    required this.emailUser,
    this.inventarioId,
  });

  @override
  State<InventarioSerieFormPage> createState() =>
      _InventarioSerieFormPageState();
}

class _InventarioSerieFormPageState extends State<InventarioSerieFormPage> {
  String? _calzadoId;
  bool _tipoTienePlataforma = false;
  bool _tipoTieneTaco = false;
  bool _tipoTieneColores = false; 

  int _cantidadSeriesTotal = 0;

  final List<Map<String, dynamic>> _subfilas = [];
  final Map<String, String?> _iconCache = {};

  final bool _cargandoDatos = false;

  /// SERIES
  final Map<String, List<int>> seriesMap = {
    '27-28-29-30-31-32': [27, 28, 29, 30, 31, 32],
    '33-33-34-34-35-36': [33, 33, 34, 34, 35, 36],
    '35-36-37-37-38-39': [35, 36, 37, 37, 38, 39],
    '39-40-40-41-42-43': [39, 40, 40, 41, 42, 43],
  };

  int _calcularTotalPares() {
    int total = 0;
    for (var sub in _subfilas) {
      String? serie = sub['serie'];
      if (serie != null && seriesMap.containsKey(serie)) {
        int cantidadSerie = sub['cantidad'] ?? 0;
        total += (seriesMap[serie]!.length * cantidadSerie);
      }
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _subfilas.add({'cantidad': 0, 'talla': 0, 'taco': 0, 'plataforma': null, 'colores': null}); 
  }

  void _mostrarSplashScreen() => showDialog(context: context, barrierDismissible: false, useRootNavigator: true, builder: (_) => const SplashScreen02());
  void _ocultarSplashScreen() { if (Navigator.of(context, rootNavigator: true).canPop()) Navigator.of(context, rootNavigator: true).pop(); }

  Future<void> _guardarInventarioSerie() async {
    if (_calzadoId == null || _cantidadSeriesTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona calzado y cantidad de series')));
      return;
    }

    int totalSeriesIngresadas = _subfilas.fold(0, (suma, item) => suma + (item['cantidad'] ?? 0) as int);

    if (totalSeriesIngresadas != _cantidadSeriesTotal) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La suma de subfilas debe ser igual al total de series')));
      return;
    }

    final combinaciones = <String>{};
    for (var sub in _subfilas) {
      final key = '${sub['serie']}_${sub['taco']}_${sub['plataforma']}_${sub['colores']}';
      if ((sub['cantidad'] ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todas las subfilas deben tener cantidad mayor a 0')));
        return;
      }
      if (sub['serie'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todas las subfilas deben tener una serie seleccionada')));
        return;
      }
      // 🔹 VALIDACION OBLIGATORIA PLATAFORMA
      if (_tipoTienePlataforma && sub['plataforma'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona el tipo de plataforma')));
        return;
      }
      if (_tipoTieneColores && (sub['colores'] == null || sub['colores'].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todas las subfilas deben tener un color seleccionado')));
        return;
      }
      if (combinaciones.contains(key)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pueden repetir subfilas con mismos atributos')));
        return;
      }
      combinaciones.add(key);
    }

    _mostrarSplashScreen();
    int totalPares = _calcularTotalPares();

    try {
      final filaExistenteSnap = await FirebaseFirestore.instance.collection('fila_inventario').where('inventario_id', isEqualTo: widget.inventarioId).where('calzado_id', isEqualTo: _calzadoId).limit(1).get();
      DocumentReference filaRef;

      if (filaExistenteSnap.docs.isNotEmpty) {
        final filaDoc = filaExistenteSnap.docs.first;
        filaRef = filaDoc.reference;
        await filaRef.update({'cantidad': (filaDoc['cantidad'] ?? 0) + totalPares});
      } else {
        filaRef = await FirebaseFirestore.instance.collection('fila_inventario').add({'inventario_id': widget.inventarioId, 'calzado_id': _calzadoId, 'cantidad': totalPares, 'fecha_creacion': Timestamp.now(), 'usuario_creacion': widget.firstName ?? 'anon', 'email_usuario': widget.emailUser ?? 'anon'});
      }

      Map<String, int> acumulado = {};
      for (var sub in _subfilas) {
        String serie = sub['serie'];
        int cantidadSerie = sub['cantidad'];
        int taco = sub['taco'] ?? 0;
        String plataforma = sub['plataforma'] ?? ''; // 🔹 Se guarda como String
        String color = sub['colores'] ?? '';

        List<int> tallas = seriesMap[serie]!;
        for (var talla in tallas) {
          String key = '${talla}_${taco}_${plataforma}_$color';
          acumulado[key] = (acumulado[key] ?? 0) + cantidadSerie;
        }
      }

      for (var entry in acumulado.entries) {
        var partes = entry.key.split('_');
        int talla = int.parse(partes[0]);
        int taco = int.parse(partes[1]);
        String plataforma = partes[2]; // 🔹 String
        String color = partes[3];
        int cantidadNueva = entry.value;

        final subExistente = await FirebaseFirestore.instance.collection('subfila_inventario').where('fila_inventario_id', isEqualTo: filaRef.id).where('talla', isEqualTo: talla).where('taco', isEqualTo: taco).where('plataforma', isEqualTo: plataforma).where('colores', isEqualTo: color).limit(1).get();

        if (subExistente.docs.isNotEmpty) {
          final doc = subExistente.docs.first;
          await doc.reference.update({'cantidad': (doc['cantidad'] ?? 0) + cantidadNueva});
        } else {
          await FirebaseFirestore.instance.collection('subfila_inventario').add({
            'fila_inventario_id': filaRef.id, 'cantidad': cantidadNueva, 'talla': talla, 'taco': _tipoTieneTaco ? taco : 0, 'plataforma': _tipoTienePlataforma ? plataforma : '', 'colores': _tipoTieneColores ? color : '', 'fecha_creacion': Timestamp.now(), 'usuario_creacion': widget.firstName ?? 'anon', 'email_usuario': widget.emailUser ?? 'anon',
          });
        }
      }

      _ocultarSplashScreen();
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codigo de inventario seriado guardado')));
      Navigator.pop(context, true);
    } catch (e) {
      _ocultarSplashScreen();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildSubfilaSerie(int index) {
    final sub = _subfilas[index];
    final opcionesPlataforma = ['Bajo', 'Mediano', 'Alto'];
    final plataformaActual = opcionesPlataforma.contains(sub['plataforma']) ? sub['plataforma'] : null;

    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Flexible(
              flex: 1,
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) => _subfilas[index]['cantidad'] = int.tryParse(v) ?? 0,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 3,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Serie', border: OutlineInputBorder()),
                value: sub['serie'],
                isExpanded: true,
                items: seriesMap.keys.map((serie) => DropdownMenuItem(value: serie, child: Text(serie, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _subfilas[index]['serie'] = v),
              ),
            ),
            SizedBox(width: 40, child: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _subfilas.removeAt(index)))),
          ],
        ),
        const SizedBox(height: 12),
        if (_tipoTieneColores)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder(), prefixIcon: Icon(Icons.palette), hintText: 'Ej: Negro, Blanco, etc.'),
              onChanged: (v) => _subfilas[index]['colores'] = v,
            ),
          ),
        if (_tipoTieneTaco)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Taco', border: OutlineInputBorder()),
              items: List.generate(15, (i) => i + 1).map((t) => DropdownMenuItem(value: t, child: Text('$t'))).toList(),
              onChanged: (v) => _subfilas[index]['taco'] = v ?? 0,
            ),
          ),
        // 🔹 MODIFICACIÓN PLATAFORMA (Igual al ancho de color)
        if (_tipoTienePlataforma)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Plataforma',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.layers_outlined),
              ),
              value: plataformaActual,
              items: opcionesPlataforma.map((opcion) => DropdownMenuItem(value: opcion, child: Text(opcion))).toList(),
              onChanged: (v) => setState(() => _subfilas[index]['plataforma'] = v),
            ),
          ),
        const Divider(),
      ],
    );
  }

  Future<String?> _obtenerIconoTipo(String tipoCalzadoId) async {
    if (_iconCache.containsKey(tipoCalzadoId)) return _iconCache[tipoCalzadoId];
    //final tipoSnap = await TipoCalzadoService.obtenerPorId(tipoCalzadoId);
    final tipoSnap = await FirebaseFirestore.instance.collection('tipo_calzado').doc(tipoCalzadoId).get();
    String? icono;
    final data = tipoSnap.data();
    if (data != null && data['icono'] != null) icono = data['icono'].toString();
    _iconCache[tipoCalzadoId] = icono;
    return icono;
  }

  Widget _buildDropdownConIconos(AsyncSnapshot<QuerySnapshot> snapshot) {
    final calzados = snapshot.data!.docs;
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Seleccionar código', border: OutlineInputBorder()),
      value: _calzadoId,
      items: calzados.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final tipoCalzadoId = data['tipo_calzado_id'];
        final nombre = data['nombre'] ?? 'Sin nombre';
        return DropdownMenuItem(
          value: doc.id,
          child: FutureBuilder<String?>(
            future: _obtenerIconoTipo(tipoCalzadoId),
            builder: (context, iconSnapshot) {
              final icono = iconSnapshot.data;
              return Row(children: [if (icono != null && icono.isNotEmpty) Image.asset(icono, width: 32, height: 32), const SizedBox(width: 8), Text(nombre)]);
            },
          ),
        );
      }).toList(),
      onChanged: (v) async {
        setState(() => _calzadoId = v);
        if (v != null) {
          final calzadoDoc = await FirebaseFirestore.instance.collection('calzado').doc(v).get();
          if (calzadoDoc.exists) {
            final calzadoData = calzadoDoc.data()!;
            setState(() {
              _tipoTieneTaco = calzadoData['taco'] ?? true;
              _tipoTienePlataforma = calzadoData['plataforma'] ?? true;
              _tipoTieneColores = calzadoData['colores'] ?? true;
            });
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) return const SplashScreen02();
    return Scaffold(
      appBar: Designwidgets().appBarMain("Agregar Serie"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('calzado').where('id_inventario', isEqualTo: widget.inventarioId).where('activo', isEqualTo: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text('No tienes calzados registrados.');
                  return _buildDropdownConIconos(snapshot);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(decoration: const InputDecoration(labelText: 'Cantidad total de series', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => _cantidadSeriesTotal = int.tryParse(v) ?? 0),
              const Divider(height: 32),
              const Text('Subfilas de inventario', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._subfilas.asMap().entries.map((e) => _buildSubfilaSerie(e.key)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_cantidadSeriesTotal <= 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero ingresa una cantidad total'))); return; }
                    if (_subfilas.length >= _cantidadSeriesTotal) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No puede exceder la cantidad total'))); return; }
                    final totalActual = _subfilas.fold<int>(0, (suma, item) => suma + (item['cantidad'] ?? 0) as int);
                    if (totalActual >= _cantidadSeriesTotal) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya suman la cantidad total'))); return; }
                    setState(() => _subfilas.add({'cantidad': 0, 'taco': 0, 'plataforma': null, 'colores': null}));
                  },
                  label: const Text('Agregar subfila'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _guardarInventarioSerie, icon: const Icon(Icons.save), label: const Text('Guardar inventario seriado'))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
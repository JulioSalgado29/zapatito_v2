import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/calzado.dart';
import 'package:zapatito_v2/services/API/fila_inventario.dart';
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

  // Caché local para carga única estática
  List<Map<String, dynamic>> _catalogoCalzados = [];
  bool _cargandoDatos = true;

  // Variables de Paginación (Base 0)
  int _paginaActual = 0;
  static const int _subfilasPorPagina = 5;

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
    _cargarCatalogoEstatico();
  }

  /// CARGA ESTÁTICA ÚNICA DE ENTIDADES
  Future<void> _cargarCatalogoEstatico() async {
    final calzados = await CalzadoService.obtenerPorInventario(widget.inventarioId);
    if (mounted) {
      setState(() {
        _catalogoCalzados = calzados;
        _cargandoDatos = false;
      });
    }
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
      Map<String, int> acumulado = {};
      for (var sub in _subfilas) {
        String serie = sub['serie'];
        int cantidadSerie = sub['cantidad'];
        int taco = sub['taco'] ?? 0;
        String plataforma = sub['plataforma'] ?? '';
        String color = sub['colores'] ?? '';

        List<int> tallas = seriesMap[serie]!;
        for (var talla in tallas) {
          String key = '${talla}_${taco}_${plataforma}_$color';
          acumulado[key] = (acumulado[key] ?? 0) + cantidadSerie;
        }
      }

      List<Map<String, dynamic>> subfilasPayload = [];
      for (var entry in acumulado.entries) {
        var partes = entry.key.split('_');
        int talla = int.parse(partes[0]);
        int taco = int.parse(partes[1]);
        String plataforma = partes[2];
        String color = partes[3];
        int cantidadNueva = entry.value;

        subfilasPayload.add({
          'cantidad': cantidadNueva,
          'talla': talla,
          'taco': _tipoTieneTaco ? taco : 0,
          'plataforma': _tipoTienePlataforma ? plataforma : '',
          'colores': _tipoTieneColores ? color : '',
          'usuario_creacion': widget.firstName ?? 'anon',
          'email_usuario': widget.emailUser ?? 'anon',
        });
      }

      final Map<String, dynamic> payload = {
        'id_inventario': widget.inventarioId,
        'id_calzado': _calzadoId,
        'cantidad': totalPares,
        'usuario_creacion': widget.firstName ?? 'anon',
        'email_user': widget.emailUser ?? 'anon',
        'subfilas': subfilasPayload,
      };

      print(payload);

      final exito = await FilaInventarioService.guardar(payload);

      _ocultarSplashScreen();
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Codigo de inventario seriado guardado')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al guardar el inventario seriado')));
      }
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
      key: ValueKey(sub), // Mantiene la referencia visual correcta al reordenar
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Flexible(
              flex: 1,
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                initialValue: sub['cantidad'] != null && sub['cantidad'] > 0 ? sub['cantidad'].toString() : '',
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
            SizedBox(
              width: 40,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    _subfilas.removeAt(index);
                    final totalPaginas = (_subfilas.isEmpty) ? 1 : (_subfilas.length / _subfilasPorPagina).ceil();
                    if (_paginaActual >= totalPaginas) {
                      _paginaActual = totalPaginas - 1;
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_tipoTieneColores)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Color', border: OutlineInputBorder(), prefixIcon: Icon(Icons.palette), hintText: 'Ej: Negro, Blanco, etc.'),
              initialValue: sub['colores'] ?? '',
              onChanged: (v) => _subfilas[index]['colores'] = v,
            ),
          ),
        if (_tipoTieneTaco)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Taco', border: OutlineInputBorder()),
              value: sub['taco'] != 0 ? sub['taco'] : null,
              items: List.generate(15, (i) => i + 1).map((t) => DropdownMenuItem(value: t, child: Text('$t'))).toList(),
              onChanged: (v) => _subfilas[index]['taco'] = v ?? 0,
            ),
          ),
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
    
    final tipoData = await TipoCalzadoService.obtenerPorId(tipoCalzadoId);
    String? icono;
    if (tipoData != null && tipoData['icono'] != null) {
      icono = tipoData['icono'].toString();
    }
    
    _iconCache[tipoCalzadoId] = icono;
    return icono;
  }

  Widget _buildDropdownConIconos() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Seleccionar código', border: OutlineInputBorder()),
      value: _calzadoId,
      items: _catalogoCalzados.map((doc) {
        final idDoc = (doc['id'] ?? doc['id_calzado'] ?? doc['_id']).toString();
        final tipoCalzadoId = (doc['tipo_calzado_id'] ?? doc['id_tipo_calzado'] ?? '').toString();
        final nombre = doc['nombre'] ?? 'Sin nombre';
        
        return DropdownMenuItem(
          value: idDoc,
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
          final calzadoData = await CalzadoService.obtenerPorId(v);
          if (calzadoData != null) {
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

  Widget _buildPaginacionControles(int totalPaginas) {
    if (totalPaginas <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _paginaActual > 0
              ? () => setState(() => _paginaActual--)
              : null,
        ),
        Text('Página ${_paginaActual + 1} de $totalPaginas', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios),
          onPressed: _paginaActual < totalPaginas - 1
              ? () => setState(() => _paginaActual++)
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) return const SplashScreen02();

    final totalPaginas = (_subfilas.isEmpty) ? 1 : (_subfilas.length / _subfilasPorPagina).ceil();
    final inicio = _paginaActual * _subfilasPorPagina;
    final fin = (inicio + _subfilasPorPagina < _subfilas.length)
        ? inicio + _subfilasPorPagina
        : _subfilas.length;

    final subfilasPaginadas = _subfilas.isEmpty ? <Map<String, dynamic>>[] : _subfilas.sublist(inicio, fin);
    
    // Invertimos únicamente los elementos visibles de la página para que el más reciente salga arriba
    final subfilasVisuales = subfilasPaginadas.reversed.toList();

    return Scaffold(
      appBar: Designwidgets().appBarMain("Agregar Serie"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _catalogoCalzados.isEmpty
                  ? const Text('No tienes calzados registrados.')
                  : _buildDropdownConIconos(),
              const SizedBox(height: 12),
              TextFormField(decoration: const InputDecoration(labelText: 'Cantidad total de series', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => _cantidadSeriesTotal = int.tryParse(v) ?? 0),
              const Divider(height: 32),
              const Text('Subfilas de inventario', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...subfilasVisuales.map((subfila) {
                final indexReal = _subfilas.indexOf(subfila);
                return _buildSubfilaSerie(indexReal);
              }),
              _buildPaginacionControles(totalPaginas),
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
                    
                    setState(() {
                      _subfilas.add({'cantidad': 0, 'taco': 0, 'plataforma': null, 'colores': null});
                      _paginaActual = 0; // Se mantiene en la página 0 donde el nuevo elemento aparece arriba
                    });
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
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

  // Caché local para carga estática
  List<Map<String, dynamic>> _catalogoCalzados = [];
  bool _cargandoDatos = true;

  // Control de paginación visual
  int _paginaActual = 1;
  final int _itemsPorPagina = 5;

  // Variables para Filtros
  String? _filtroSerie;
  int? _filtroTaco;
  String? _filtroPlataforma;
  String _filtroColor = '';
  final TextEditingController _filtroColorController = TextEditingController();

  // Control para mostrar u ocultar la sección de filtros
  bool _mostrarFiltros = false;

  /// MAPA DE SERIES
  final Map<String, List<int>> seriesMap = {
    '27-28-29-30-31-32': [27, 28, 29, 30, 31, 32],
    '33-33-34-34-35-36': [33, 33, 34, 34, 35, 36],
    '35-36-37-37-38-39': [35, 36, 37, 37, 38, 39],
    '39-40-40-41-42-43': [39, 40, 40, 41, 42, 43],
  };

  // Getter para determinar si hay algún filtro activo
  bool get _estaFiltrado =>
      _filtroSerie != null ||
      _filtroTaco != null ||
      _filtroPlataforma != null ||
      _filtroColor.trim().isNotEmpty;

  void _limpiarFiltros() {
    setState(() {
      _filtroSerie = null;
      _filtroTaco = null;
      _filtroPlataforma = null;
      _filtroColor = '';
      _filtroColorController.clear();
      _paginaActual = 1;
    });
  }

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
    _subfilas.add({
      'cantidad': 0,
      'serie': null,
      'taco': 0,
      'plataforma': null,
      'colores': ''
    });
    _cargarCatalogoEstatico();
  }

  @override
  void dispose() {
    _filtroColorController.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogoEstatico() async {
    final calzados =
        await CalzadoService.obtenerPorInventario(widget.inventarioId);
    if (mounted) {
      setState(() {
        _catalogoCalzados = calzados;
        _cargandoDatos = false;
      });
    }
  }

  void _mostrarSplashScreen() => showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) => const SplashScreen02(),
      );

  void _ocultarSplashScreen() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _guardarInventarioSerie() async {
    if (_calzadoId == null || _cantidadSeriesTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona calzado y cantidad de series')),
      );
      return;
    }

    int totalSeriesIngresadas = _subfilas.fold(
        0, (suma, item) => suma + (item['cantidad'] ?? 0) as int);

    if (totalSeriesIngresadas != _cantidadSeriesTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'La suma de subfilas debe ser igual al total de series')),
      );
      return;
    }

    final combinaciones = <String>{};
    for (var sub in _subfilas) {
      final key =
          '${sub['serie']}_${sub['taco']}_${sub['plataforma']}_${sub['colores']}';
      if ((sub['cantidad'] ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Todas las subfilas deben tener cantidad mayor a 0')),
        );
        return;
      }
      if (sub['serie'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Todas las subfilas deben tener una serie seleccionada')),
        );
        return;
      }
      if (_tipoTienePlataforma &&
          (sub['plataforma'] == null ||
              sub['plataforma'].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Selecciona el tipo de plataforma en todas las subfilas')),
        );
        return;
      }
      if (_tipoTieneColores &&
          (sub['colores'] == null || sub['colores'].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Todas las subfilas deben tener un color especificado')),
        );
        return;
      }
      if (combinaciones.contains(key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('No se pueden repetir subfilas con mismos atributos')),
        );
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

      final exito = await FilaInventarioService.guardar(payload);

      _ocultarSplashScreen();
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Codigo de inventario seriado guardado')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error al guardar el inventario seriado')),
        );
      }
    } catch (e) {
      _ocultarSplashScreen();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  Widget _buildSeccionFiltros(int visibles, int total) {
    final tacos = List.generate(15, (i) => i + 1);
    final opcionesPlataforma = ['Bajo', 'Mediano', 'Alto'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barra superior de control
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () =>
                  setState(() => _mostrarFiltros = !_mostrarFiltros),
              icon: Icon(_mostrarFiltros
                  ? Icons.filter_alt_off
                  : Icons.filter_alt_outlined),
              label:
                  Text(_mostrarFiltros ? 'Ocultar filtros' : 'Mostrar filtros'),
            ),
            Row(
              children: [
                if (_estaFiltrado) ...[
                  TextButton.icon(
                    onPressed: _limpiarFiltros,
                    icon: const Icon(Icons.clear_all,
                        size: 18, color: Colors.red),
                    label: const Text(
                      'Limpiar',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _estaFiltrado
                        ? Colors.yellow.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _estaFiltrado ? Colors.yellow : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _estaFiltrado
                            ? Icons.filter_alt
                            : Icons.filter_alt_outlined,
                        size: 16,
                        color: _estaFiltrado
                            ? Colors.yellow.shade800
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _estaFiltrado ? 'Filtrado' : 'Sin filtrar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _estaFiltrado
                              ? Colors.yellow.shade800
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // Campos de filtro desplegables
        if (_mostrarFiltros) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(
                    labelText: 'Filtrar Serie',
                    border: OutlineInputBorder(),
                  ),
                  value: _filtroSerie,
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('Todas')),
                    ...seriesMap.keys.map((s) => DropdownMenuItem<String?>(
                          value: s,
                          child: Text(s, style: const TextStyle(fontSize: 11)),
                        )),
                  ],
                  onChanged: (v) => setState(() {
                    _filtroSerie = v;
                    _paginaActual = 1;
                  }),
                ),
              ),
              if (_tipoTieneTaco) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(
                      labelText: 'Filtrar Taco',
                      border: OutlineInputBorder(),
                    ),
                    value: _filtroTaco,
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text('Todos')),
                      ...tacos.map((t) => DropdownMenuItem<int?>(
                            value: t,
                            child: Text(t.toString()),
                          )),
                    ],
                    onChanged: (v) => setState(() {
                      _filtroTaco = v;
                      _paginaActual = 1;
                    }),
                  ),
                ),
              ],
            ],
          ),
          if (_tipoTienePlataforma || _tipoTieneColores)
            const SizedBox(height: 12),
          Row(
            children: [
              if (_tipoTienePlataforma)
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(
                      labelText: 'Filtrar Plataforma',
                      border: OutlineInputBorder(),
                    ),
                    value: _filtroPlataforma,
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('Todas')),
                      ...opcionesPlataforma.map((p) => DropdownMenuItem<String?>(
                            value: p,
                            child: Text(p),
                          )),
                    ],
                    onChanged: (v) => setState(() {
                      _filtroPlataforma = v;
                      _paginaActual = 1;
                    }),
                  ),
                ),
              if (_tipoTienePlataforma && _tipoTieneColores)
                const SizedBox(width: 8),
              if (_tipoTieneColores)
                Expanded(
                  child: TextFormField(
                    controller: _filtroColorController,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar Color',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() {
                      _filtroColor = v;
                      _paginaActual = 1;
                    }),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBannerOcultas(int ocultas) {
    if (!_estaFiltrado || ocultas <= 0) return const SizedBox.shrink();

    final esPlural = ocultas > 1;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade700),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_off_outlined,
              color: Colors.yellow.shade900, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Se ${esPlural ? "ocultaron" : "ocultó"} $ocultas subfila${esPlural ? "s" : ""} por los filtros activos.',
              style: TextStyle(
                color: Colors.yellow.shade900,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          InkWell(
            onTap: _limpiarFiltros,
            child: Text(
              'Ver todas',
              style: TextStyle(
                color: Colors.yellow.shade900,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginacionVisual(int totalItems) {
    if (totalItems <= _itemsPorPagina) return const SizedBox.shrink();

    final int totalPaginas = (totalItems / _itemsPorPagina).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _paginaActual > 1
                ? () => setState(() => _paginaActual--)
                : null,
          ),
          Text(
            'Página $_paginaActual de $totalPaginas',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _paginaActual < totalPaginas
                ? () => setState(() => _paginaActual++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSubfilaItem(int index) {
    final sub = _subfilas[index];
    final tacos = List.generate(15, (i) => i + 1);
    final opcionesPlataforma = ['Bajo', 'Mediano', 'Alto'];

    final tacoActual = (sub['taco'] != null && tacos.contains(sub['taco']))
        ? sub['taco']
        : null;
    final cantidadActual = (sub['cantidad'] ?? 0) > 0 ? sub['cantidad'] : 0;
    final plataformaActual = opcionesPlataforma.contains(sub['plataforma'])
        ? sub['plataforma']
        : null;

    return Column(
      key: ValueKey('subfila_$index'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        if (_tipoTieneColores)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextFormField(
              decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.color_lens_outlined)),
              initialValue: sub['colores'] ?? '',
              onChanged: (v) => setState(() => _subfilas[index]['colores'] = v),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('cantidad_${index}_${_subfilas[index]['id'] ?? ''}'),
                decoration: const InputDecoration(
                    labelText: 'Cantidad', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                initialValue: cantidadActual > 0 ? cantidadActual.toString() : '',
                onChanged: (val) {
                  final parsed = int.tryParse(val) ?? 0;
                  setState(() => _subfilas[index]['cantidad'] = parsed);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'Serie', border: OutlineInputBorder()),
                value: sub['serie'],
                isExpanded: true,
                items: seriesMap.keys
                    .map((serie) => DropdownMenuItem(
                          value: serie,
                          child: Text(serie, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => sub['serie'] = val),
              ),
            ),
            if (_tipoTieneTaco) ...[
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                      labelText: 'Taco', border: OutlineInputBorder()),
                  value: tacoActual,
                  items: tacos
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.toString())))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _subfilas[index]['taco'] = v ?? 0),
                ),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() {
                _subfilas.removeAt(index);
                final totalPaginas = (_subfilas.length / _itemsPorPagina).ceil();
                if (_paginaActual > totalPaginas && totalPaginas > 0) {
                  _paginaActual = totalPaginas;
                }
              }),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (_tipoTienePlataforma)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Tipo de Plataforma',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.layers_outlined),
              ),
              value: plataformaActual,
              items: opcionesPlataforma
                  .map((opcion) => DropdownMenuItem(
                        value: opcion,
                        child: Text(opcion),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _subfilas[index]['plataforma'] = v),
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
      decoration: const InputDecoration(
          labelText: 'Seleccionar código', border: OutlineInputBorder()),
      value: _calzadoId,
      items: _catalogoCalzados.map((doc) {
        final idDoc = (doc['id'] ?? doc['id_calzado'] ?? doc['_id']).toString();
        final tipoCalzadoId =
            (doc['tipo_calzado_id'] ?? doc['id_tipo_calzado'] ?? '').toString();
        final nombre = doc['nombre'] ?? 'Sin nombre';

        return DropdownMenuItem(
          value: idDoc,
          child: FutureBuilder<String?>(
            future: _obtenerIconoTipo(tipoCalzadoId),
            builder: (context, iconSnapshot) {
              final icono = iconSnapshot.data;
              return Row(
                children: [
                  if (icono != null && icono.isNotEmpty)
                    Image.asset(icono, width: 32, height: 32),
                  const SizedBox(width: 8),
                  Text(nombre),
                ],
              );
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

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) return const SplashScreen02();

    final List<int> subfilasFiltradasIndices = [];
    for (int i = 0; i < _subfilas.length; i++) {
      final sub = _subfilas[i];

      final bool coincideSerie =
          _filtroSerie == null || sub['serie'] == _filtroSerie;
      final bool coincideTaco =
          !_tipoTieneTaco || _filtroTaco == null || sub['taco'] == _filtroTaco;
      final bool coincidePlataforma = !_tipoTienePlataforma ||
          _filtroPlataforma == null ||
          sub['plataforma'] == _filtroPlataforma;
      final bool coincideColor = !_tipoTieneColores ||
          _filtroColor.trim().isEmpty ||
          (sub['colores'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_filtroColor.trim().toLowerCase());

      if (coincideSerie &&
          coincideTaco &&
          coincidePlataforma &&
          coincideColor) {
        subfilasFiltradasIndices.add(i);
      }
    }

    final int totalSubfilas = _subfilas.length;
    final int visibles = subfilasFiltradasIndices.length;
    final int ocultas = totalSubfilas - visibles;

    final List<int> indicesInvertidos =
        subfilasFiltradasIndices.reversed.toList();

    final int inicio = (_paginaActual - 1) * _itemsPorPagina;
    final int fin = (inicio + _itemsPorPagina < indicesInvertidos.length)
        ? inicio + _itemsPorPagina
        : indicesInvertidos.length;

    final List<int> indicesPaginados = (inicio < indicesInvertidos.length)
        ? indicesInvertidos.sublist(inicio, fin)
        : [];

    return Scaffold(
      appBar: Designwidgets().appBarMain("Agregado por Serie"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _catalogoCalzados.isEmpty
                  ? const Text('No tienes calzados registrados.')
                  : _buildDropdownConIconos(),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Cantidad total de series',
                    border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (v) => _cantidadSeriesTotal = int.tryParse(v) ?? 0,
              ),
              const Divider(height: 32),
              const Text('Subfilas de inventario',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildSeccionFiltros(visibles, totalSubfilas),
              const SizedBox(height: 12),
              ...indicesPaginados.map((index) => _buildSubfilaItem(index)),
              _buildPaginacionVisual(visibles),
              _buildBannerOcultas(ocultas),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_cantidadSeriesTotal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Primero ingresa una cantidad total')));
                      return;
                    }
                    if (_subfilas.length >= _cantidadSeriesTotal) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('No puede exceder la cantidad total')));
                      return;
                    }
                    final totalActual = _subfilas.fold<int>(0,
                        (suma, item) => suma + (item['cantidad'] ?? 0) as int);
                    if (totalActual >= _cantidadSeriesTotal) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Ya suman la cantidad total')));
                      return;
                    }
                    setState(() {
                      _subfilas.add({
                        'cantidad': 0,
                        'serie': null,
                        'taco': 0,
                        'plataforma': null,
                        'colores': ''
                      });
                      _paginaActual = 1;
                    });
                  },
                  label: const Text('Agregar subfila'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardarInventarioSerie,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar inventario seriado'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
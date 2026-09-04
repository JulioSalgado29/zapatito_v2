import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/calzado.dart';
import 'package:zapatito_v2/services/API/fila_inventario.dart';
import 'package:zapatito_v2/services/API/tipo_calzado.dart';

class InventarioFormPageColor extends StatefulWidget {
  final String? firstName;
  final String? inventarioId;
  final String? emailUser;

  const InventarioFormPageColor({
    super.key,
    this.firstName,
    this.inventarioId,
    this.emailUser,
  });

  @override
  State<InventarioFormPageColor> createState() =>
      _InventarioFormPageColorState();
}

class _InventarioFormPageColorState extends State<InventarioFormPageColor> {
  late Future<List<Map<String, dynamic>>> _calzadosFuture;
  String? _calzadoId;
  bool _tipoTienePlataforma = false;
  bool _tipoTieneColores = false;
  bool _tipoTieneTaco = false;

  // Variables de control para los filtros visuales de subfilas
  int? _filtroTalla;
  int? _filtroTaco;
  String? _filtroPlataforma;
  String _filtroColor = '';
  final TextEditingController _filtroColorController = TextEditingController();

  // Control para mostrar u ocultar la sección de filtros
  bool _mostrarFiltros = false;

  // Control de paginación visual
  int _paginaActual = 1;
  final int _itemsPorPagina = 5;

  // Getter para determinar si hay algún filtro activo
  bool get _estaFiltrado =>
      _filtroTalla != null ||
      _filtroTaco != null ||
      _filtroPlataforma != null ||
      _filtroColor.trim().isNotEmpty;

  // Getter para calcular la cantidad total general sumando todas las subfilas
  int get _cantidadFila {
    int total = 0;
    for (var bloque in _subfilasColor) {
      final miniSubfilas = (bloque['minisubfilas'] as List<dynamic>?) ?? [];
      for (var mini in miniSubfilas) {
        total += ((mini['cantidad'] ?? 0) as int);
      }
    }
    return total;
  }

  final List<Map<String, dynamic>> _subfilasColor = [];
  final Map<String, String?> _iconCache = {};

  @override
  void initState() {
    super.initState();
    _calzadosFuture = CalzadoService.obtenerPorInventarioConColores(
      widget.inventarioId.toString(),
    );
    _agregarNuevoBloqueColor();
  }

  @override
  void dispose() {
    _filtroColorController.dispose();
    super.dispose();
  }

  void _agregarNuevoBloqueColor() {
    _subfilasColor.add({
      'color': '',
      'cantidad_color': 0,
      'minisubfilas': <Map<String, dynamic>>[
        <String, dynamic>{
          'cantidad': 0,
          'talla': 0,
          'taco': 0,
          'plataforma': null,
        }
      ]
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroTalla = null;
      _filtroTaco = null;
      _filtroPlataforma = null;
      _filtroColor = '';
      _filtroColorController.clear();
      _paginaActual = 1;
    });
  }

  Future<String?> _obtenerIconoTipo(String? tipoCalzadoId) async {
    if (tipoCalzadoId == null || tipoCalzadoId.isEmpty) return null;

    if (_iconCache.containsKey(tipoCalzadoId)) {
      return _iconCache[tipoCalzadoId];
    }

    try {
      final listado = await TipoCalzadoService.obtenerTodosPorInventario(
        widget.inventarioId.toString(),
      );

      final coincide = listado.firstWhere(
        (e) {
          final idEnMap = (e['id_tipo_calzado'] ?? e['id'])?.toString();
          return idEnMap == tipoCalzadoId.toString();
        },
        orElse: () => <String, dynamic>{},
      );

      final String? icono = coincide['icono']?.toString();
      _iconCache[tipoCalzadoId] = icono;
      return icono;
    } catch (e) {
      print('Error al obtener ícono tipo calzado: $e');
      return null;
    }
  }

  void _mostrarSplashScreen() => showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const SplashScreen02());

  void _ocultarSplashScreen() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  String normalizarA0(dynamic valor) {
    if (valor == null) return '0';
    final texto = valor.toString().trim();
    return texto.isEmpty ? '0' : texto;
  }

  Future<void> _guardarFilaInventario() async {
    if (_calzadoId == null || _cantidadFila <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Selecciona un calzado y registra al menos una cantidad')));
      return;
    }

    if (_subfilasColor.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes registrar al menos un color')));
      return;
    }

    final combinaciones = <String>{};
    final List<Map<String, dynamic>> subfilasAplanadas = [];

    for (var i = 0; i < _subfilasColor.length; i++) {
      final bloqueColor = _subfilasColor[i];
      final colorNombre = (bloqueColor['color'] ?? '').toString().trim();
      final miniSubfilas =
          (bloqueColor['minisubfilas'] as List<dynamic>?) ?? [];

      if (_tipoTieneColores && colorNombre.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Ingresa un nombre de color válido en la sección #${i + 1}')));
        return;
      }

      int sumaMiniSubfilas = 0;
      if (miniSubfilas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'El color "$colorNombre" debe tener al menos una subfila de talla/cantidad')));
        return;
      }

      for (var mini in miniSubfilas) {
        final cant = (mini['cantidad'] ?? 0) as int;
        final talla = (mini['talla'] ?? 0) as int;
        final taco = mini['taco'] ?? 0;
        final plataforma = mini['plataforma'];

        if (cant <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Todas las subfilas del color "$colorNombre" deben tener cantidad mayor a 0')));
          return;
        }

        if (talla <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Todas las subfilas del color "$colorNombre" deben tener una talla seleccionada')));
          return;
        }

        if (_tipoTienePlataforma &&
            (plataforma == null || plataforma.toString().isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Selecciona el tipo de plataforma en todas las subfilas del color "$colorNombre"')));
          return;
        }

        final key = '${talla}_${taco}_${plataforma}_$colorNombre';
        if (combinaciones.contains(key)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'No se pueden repetir subfilas con iguales atributos ($colorNombre - Talla $talla)')));
          return;
        }
        combinaciones.add(key);

        sumaMiniSubfilas += cant;

        subfilasAplanadas.add({
          'cantidad': cant,
          'talla': talla.toString(),
          'taco': normalizarA0(taco),
          'plataforma': normalizarA0(plataforma),
          'colores': normalizarA0(colorNombre),
        });
      }

      bloqueColor['cantidad_color'] = sumaMiniSubfilas;
      if (sumaMiniSubfilas <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('El total del color "$colorNombre" debe ser mayor a 0')));
        return;
      }
    }

    _mostrarSplashScreen();
    try {
      final datos = {
        'id_inventario': widget.inventarioId,
        'id_calzado': _calzadoId,
        'cantidad': _cantidadFila,
        'usuario_creacion': widget.firstName ?? 'anon',
        'email_user': widget.emailUser ?? 'anon',
        'subfilas': subfilasAplanadas,
      };

      final exito = await FilaInventarioService.guardar(datos);
      _ocultarSplashScreen();

      if (exito) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inventario guardado correctamente')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar en el servidor')),
          );
        }
      }
    } catch (e) {
      _ocultarSplashScreen();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  Widget _buildSeccionFiltros(int visibles, int total) {
    final tallas = List.generate(22, (i) => i + 22);
    final tacos = List.generate(15, (i) => i + 1);
    final opcionesPlataforma = ['Bajo', 'Mediano', 'Alto'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (_mostrarFiltros) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(
                    labelText: 'Filtrar Talla',
                    border: OutlineInputBorder(),
                  ),
                  value: _filtroTalla,
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text('Todas')),
                    ...tallas.map((t) => DropdownMenuItem<int?>(
                          value: t,
                          child: Text(t.toString()),
                        )),
                  ],
                  onChanged: (v) => setState(() {
                    _filtroTalla = v;
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
                      ...opcionesPlataforma
                          .map((p) => DropdownMenuItem<String?>(
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
              'Se ${esPlural ? "ocultaron" : "ocultó"} $ocultas bloque${esPlural ? "s" : ""} de color por los filtros activos.',
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

  Widget _buildMiniSubfilaItem(int colorIndex, int miniIndex) {
    final mini = _subfilasColor[colorIndex]['minisubfilas'][miniIndex];
    final tallas = List.generate(22, (i) => i + 22);
    final tacos = List.generate(15, (i) => i + 1);
    final opcionesPlataforma = ['Bajo', 'Mediano', 'Alto'];

    final tallaActual =
        (mini['talla'] != null && tallas.contains(mini['talla']))
            ? mini['talla']
            : null;
    final tacoActual = (mini['taco'] != null && tacos.contains(mini['taco']))
        ? mini['taco']
        : null;
    final cantidadActual = (mini['cantidad'] ?? 0) > 0 ? mini['cantidad'] : 0;
    final plataformaActual = opcionesPlataforma.contains(mini['plataforma'])
        ? mini['plataforma']
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('cant_color_${colorIndex}_mini_$miniIndex'),
                    decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        isDense: true,
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    initialValue:
                        cantidadActual > 0 ? cantidadActual.toString() : '',
                    onChanged: (val) {
                      final parsed = int.tryParse(val) ?? 0;
                      setState(() => mini['cantidad'] = parsed);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                        labelText: 'Talla',
                        isDense: true,
                        border: OutlineInputBorder()),
                    value: tallaActual,
                    items: tallas
                        .map((talla) => DropdownMenuItem<int>(
                            value: talla, child: Text(talla.toString())))
                        .toList(),
                    onChanged: (val) => setState(() => mini['talla'] = val),
                  ),
                ),
                if (_tipoTieneTaco) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                          labelText: 'Taco',
                          isDense: true,
                          border: OutlineInputBorder()),
                      value: tacoActual,
                      items: tacos
                          .map((t) => DropdownMenuItem(
                              value: t, child: Text(t.toString())))
                          .toList(),
                      onChanged: (v) => setState(() => mini['taco'] = v ?? 0),
                    ),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => setState(() {
                    (_subfilasColor[colorIndex]['minisubfilas'] as List)
                        .removeAt(miniIndex);
                  }),
                ),
              ],
            ),
            if (_tipoTienePlataforma)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Plataforma',
                    isDense: true,
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.layers_outlined, size: 18),
                  ),
                  value: plataformaActual,
                  items: opcionesPlataforma
                      .map((opcion) => DropdownMenuItem<String>(
                            value: opcion,
                            child: Text(opcion),
                          ))
                      .toList(),
                  onChanged: (String? v) {
                    setState(() {
                      mini['plataforma'] = v;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloqueColorItem(int colorIndex) {
    final bloque = _subfilasColor[colorIndex];
    final miniSubfilas = (bloque['minisubfilas'] as List<dynamic>?) ?? [];

    // Cálculo automático del total de este bloque de color
    final int cantidadColor = miniSubfilas.fold<int>(
      0,
      (sum, m) => sum + ((m['cantidad'] ?? 0) as int),
    );
    bloque['cantidad_color'] = cantidadColor;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Color',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.color_lens_outlined),
                      isDense: true,
                    ),
                    initialValue: bloque['color'] ?? '',
                    onChanged: (v) => setState(() => bloque['color'] = v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
  key: ValueKey('total_color_${colorIndex}_$cantidadColor'),
  initialValue: cantidadColor.toString(),
  readOnly: true,
  enabled: false,
  style: TextStyle(
    color: cantidadColor > 0
        ? Colors.green.shade900
        : Colors.black54,
    fontWeight: FontWeight.bold,
  ),
  decoration: InputDecoration(
    labelText: 'Total Color',
    border: const OutlineInputBorder(),
    filled: true,
    fillColor: cantidadColor > 0
        ? Colors.green.shade100
        : Colors.grey.shade200,
    disabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: cantidadColor > 0
            ? Colors.green.shade400
            : Colors.grey.shade400,
      ),
    ),
  ),
),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () => setState(() {
                    _subfilasColor.removeAt(colorIndex);
                    final totalPaginas =
                        (_subfilasColor.length / _itemsPorPagina).ceil();
                    if (_paginaActual > totalPaginas && totalPaginas > 0) {
                      _paginaActual = totalPaginas;
                    }
                  }),
                )
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Tallas y Cantidades:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              miniSubfilas.length,
              (miniIndex) => _buildMiniSubfilaItem(colorIndex, miniIndex),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Agregar subfila'),
                onPressed: () {
                  setState(() {
                    miniSubfilas.add(<String, dynamic>{
                      'cantidad': 0,
                      'talla': 0,
                      'taco': 0,
                      'plataforma': null,
                    });
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownConIconos(List<Map<String, dynamic>> calzados) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Seleccionar código',
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      value: _calzadoId?.toString(),
      items: calzados.map((doc) {
        final idCalzado = (doc['id_calzado'] ?? doc['id'])?.toString();
        final tipoCalzadoId =
            (doc['id_tipo_calzado'] ?? doc['tipo_calzado_id'])?.toString();
        final nombre = doc['nombre'] ?? 'Sin nombre';
        return DropdownMenuItem(
          value: idCalzado,
          child: FutureBuilder<String?>(
            future: _obtenerIconoTipo(tipoCalzadoId),
            builder: (context, iconSnapshot) {
              final icono = iconSnapshot.data;
              return Row(children: [
                if (icono != null && icono.isNotEmpty)
                  Image.asset(icono, width: 32, height: 32),
                const SizedBox(width: 8),
                Text(nombre, style: const TextStyle(color: Colors.black))
              ]);
            },
          ),
        );
      }).toList(),
      onChanged: (v) async {
        setState(() => _calzadoId = v);
        if (v != null) {
          final calzadoSeleccionado = calzados.firstWhere(
            (item) => (item['id_calzado'] ?? item['id'])?.toString() == v,
            orElse: () => {},
          );
          if (calzadoSeleccionado.isNotEmpty) {
            _tipoTieneTaco = calzadoSeleccionado['taco'] ?? true;
            _tipoTienePlataforma = calzadoSeleccionado['plataforma'] ?? true;
            _tipoTieneColores = calzadoSeleccionado['colores'] ?? true;
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<int> subfilasFiltradasIndices = [];
    for (int i = 0; i < _subfilasColor.length; i++) {
      final bloque = _subfilasColor[i];
      final colorNombre = (bloque['color'] ?? '').toString();
      final miniSubfilas = (bloque['minisubfilas'] as List<dynamic>?) ?? [];

      final bool coincideColor = !_tipoTieneColores ||
          _filtroColor.trim().isEmpty ||
          colorNombre.toLowerCase().contains(_filtroColor.trim().toLowerCase());

      bool coincideMiniSubfilas = true;

      if (_filtroTalla != null ||
          _filtroTaco != null ||
          _filtroPlataforma != null) {
        coincideMiniSubfilas = miniSubfilas.any((sub) {
          final bool coincideTalla =
              _filtroTalla == null || sub['talla'] == _filtroTalla;
          final bool coincideTaco = !_tipoTieneTaco ||
              _filtroTaco == null ||
              sub['taco'] == _filtroTaco;
          final bool coincidePlataforma = !_tipoTienePlataforma ||
              _filtroPlataforma == null ||
              sub['plataforma'] == _filtroPlataforma;

          return coincideTalla && coincideTaco && coincidePlataforma;
        });
      }

      if (coincideColor && coincideMiniSubfilas) {
        subfilasFiltradasIndices.add(i);
      }
    }

    final int totalSubfilas = _subfilasColor.length;
    final int visibles = subfilasFiltradasIndices.length;
    final int ocultas = totalSubfilas - visibles;

    final List<int> indicesOrdenadosVisualmente =
        subfilasFiltradasIndices.reversed.toList();

    final int inicio = (_paginaActual - 1) * _itemsPorPagina;
    final int fin =
        (inicio + _itemsPorPagina < indicesOrdenadosVisualmente.length)
            ? inicio + _itemsPorPagina
            : indicesOrdenadosVisualmente.length;

    final List<int> indicesPaginados =
        (inicio < indicesOrdenadosVisualmente.length)
            ? indicesOrdenadosVisualmente.sublist(inicio, fin)
            : [];

    return Scaffold(
      appBar: Designwidgets().appBarMain("Agregado por Color"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _calzadosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No tienes calzados registrados.');
                  }

                  final calzados = snapshot.data!
                      .where((item) =>
                          item['activo'] == true || item['activo'] == 1)
                      .toList();

                  if (calzados.isEmpty) {
                    return const Text('No tienes calzados registrados.');
                  }

                  return _buildDropdownConIconos(calzados);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey('cant_total_fila_$_cantidadFila'),
                readOnly: true,
                enabled: false,
                initialValue: '$_cantidadFila',
                style: TextStyle(
                  color: _cantidadFila > 0
                      ? Colors.green.shade800
                      : Colors.black87,
                  fontWeight:
                      _cantidadFila > 0 ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Cantidad total',
                  border: const OutlineInputBorder(),
                  filled: _cantidadFila > 0,
                  fillColor: _cantidadFila > 0 ? Colors.green.shade50 : null,
                ),
              ),
              const Divider(height: 32),
              const Text('Desglose por Color',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _buildSeccionFiltros(visibles, totalSubfilas),
              const SizedBox(height: 12),
              ...indicesPaginados.map((index) => KeyedSubtree(
                    key: ValueKey(_subfilasColor[index]),
                    child: _buildBloqueColorItem(index),
                  )),
              _buildPaginacionVisual(visibles),
              _buildBannerOcultas(ocultas),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.palette_outlined),
                  onPressed: () {
                    setState(() {
                      _agregarNuevoBloqueColor();
                      _paginaActual = 1;
                    });
                  },
                  label: const Text('Agregar Color'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardarFilaInventario,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Inventario'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

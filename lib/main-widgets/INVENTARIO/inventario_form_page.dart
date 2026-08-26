import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/calzado.dart';
import 'package:zapatito_v2/services/API/fila_inventario.dart';
import 'package:zapatito_v2/services/API/tipo_calzado.dart';

class InventarioFormPage extends StatefulWidget {
  final String? firstName;
  final String? inventarioId;
  final String? filaId;
  final String? emailUser;

  const InventarioFormPage({
    super.key,
    this.firstName,
    this.inventarioId,
    this.filaId,
    this.emailUser,
  });

  @override
  State<InventarioFormPage> createState() => _InventarioFormPageState();
}

class _InventarioFormPageState extends State<InventarioFormPage> {
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

  int _cantidadFila = 0;
  final List<Map<String, dynamic>> _subfilas = [];
  final Map<String, String?> _iconCache = {};
  bool _cargandoDatos = false;

  @override
  void initState() {
    super.initState();
    _calzadosFuture = CalzadoService.obtenerPorInventario(
      widget.inventarioId.toString(),
    );
    if (widget.filaId != null) {
      _cargarDatosExistentes();
    } else {
      _subfilas.add({
        'cantidad': 0,
        'talla': 0,
        'taco': 0,
        'plataforma': null, // 🔹 Forzamos null para obligar selección
        'colores': ''
      });
    }
  }

  @override
  void dispose() {
    _filtroColorController.dispose();
    super.dispose();
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

  Future<void> _cargarDatosExistentes() async {
    setState(() => _cargandoDatos = true);

    try {
      // Peticiones en paralelo a la API
      final resultados = await Future.wait([
        FilaInventarioService.obtenerDetallePorId(widget.filaId),
        FilaInventarioService.obtenerSubfilas(widget.filaId),
      ]);

      final detalle = resultados[0] as Map<String, dynamic>?;
      final listadoSubfilas = resultados[1] as List<Map<String, dynamic>>;

      if (detalle != null) {
        // 1. Asignar datos de la fila y calzado (vienen del INNER JOIN)
        _calzadoId = detalle['id_calzado']?.toString();
        _cantidadFila = detalle['cantidad'] ?? 0;
        _tipoTieneTaco = detalle['taco'] ?? true;
        _tipoTienePlataforma = detalle['plataforma'] ?? true;
        _tipoTieneColores = detalle['colores'] ?? true;

        // 2. Cargar subfilas de la API
        _subfilas.clear();
        for (var item in listadoSubfilas) {
          _subfilas.add({
            'id': item['id_subfila_inventario'] ?? item['id'],
            'cantidad': item['cantidad'] ?? 0,
            'talla': item['talla'] ?? 0,
            'taco': item['taco'] ?? 0,
            'plataforma': item['plataforma'], // String o null
            'colores': item['colores'] ?? '',
          });
        }

        // 3. Fila por defecto si no existen subfilas registradas
        if (_subfilas.isEmpty) {
          _subfilas.add({
            'cantidad': 0,
            'talla': 0,
            'taco': 0,
            'plataforma': null,
            'colores': ''
          });
        }
      }
    } catch (e) {
      print('Error al cargar datos existentes: $e');
    } finally {
      if (mounted) {
        setState(() => _cargandoDatos = false);
      }
    }
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
          content: Text('Selecciona un calzado y una cantidad válida')));
      return;
    }

    final combinaciones = <String>{};
    for (var sub in _subfilas) {
      final key =
          '${sub['talla']}_${sub['taco']}_${sub['plataforma']}_${sub['colores']}';

      if ((sub['cantidad'] ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Todas las subfilas deben tener cantidad mayor a 0')));
        return;
      }
      if ((sub['talla'] ?? 0) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Todas las subfilas deben tener una talla seleccionada')));
        return;
      }
      if (_tipoTienePlataforma &&
          (sub['plataforma'] == null || sub['plataforma'].toString().isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Selecciona el tipo de plataforma en todas las subfilas')));
        return;
      }
      if ((sub['colores'] ?? '') == '' && _tipoTieneColores) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Todas las subfilas deben tener un color especificado')));
        return;
      }
      if (combinaciones.contains(key)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('No se pueden repetir subfilas con mismos atributos')));
        return;
      }
      combinaciones.add(key);
    }

    final totalSubfila = _subfilas.fold<int>(
        0, (suma, item) => suma + (item['cantidad'] ?? 0) as int);
    if (totalSubfila != _cantidadFila) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('La suma de subfilas debe ser igual a la cantidad total')));
      return;
    }

    _mostrarSplashScreen();
    try {
      final List<Map<String, dynamic>> subfilasMapeadas = _subfilas.map((sub) {
        return {
          'cantidad': int.tryParse(sub['cantidad']?.toString() ?? '') ?? 0,
          'talla': sub['talla']?.toString().trim() ?? '0',
          'taco': normalizarA0(sub['taco']),
          'plataforma': normalizarA0(sub['plataforma']),
          'colores': normalizarA0(sub['colores']),
        };
      }).toList();

      bool exito = false;

      if (widget.filaId == null) {
        final datos = {
          'id_inventario': widget.inventarioId,
          'id_calzado': _calzadoId,
          'cantidad': _cantidadFila,
          'usuario_creacion': widget.firstName ?? 'anon',
          'email_user': widget.emailUser ?? 'anon',
          'subfilas': subfilasMapeadas,
        };

        exito = await FilaInventarioService.guardar(datos);
      } else {
        final datos = {
          'id_calzado': _calzadoId,
          'cantidad': _cantidadFila,
          'usuario_creacion': widget.firstName ?? 'anon',
          'email_user': widget.emailUser ?? 'anon@mail.com',
          'subfilas': subfilasMapeadas,
        };

        exito = await FilaInventarioService.actualizar(widget.filaId!, datos);
      }
      _ocultarSplashScreen();

      if (exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventario guardado correctamente')),
        );
        Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar en el servidor')),
          );
        }
      }
    } catch (e) {
      _ocultarSplashScreen();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  Widget _buildSeccionFiltros(int visibles, int total) {
    final tallas = List.generate(18, (i) => i + 25);
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
                // 🔴 Botón de limpiar filtros (visible solo si hay filtros aplicados)
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

                // 🔴 Indicador de estado que cambia a ROJO si está filtrado
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
    final tallas = List.generate(18, (i) => i + 25);
    final tacos = List.generate(15, (i) => i + 1);
    final opcionesPlataforma = ['Bajo', 'Mediano', 'Alto'];

    final tallaActual = (sub['talla'] != null && tallas.contains(sub['talla']))
        ? sub['talla']
        : null;
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
                key: ValueKey(
                    'cantidad_${index}_${_subfilas[index]['id'] ?? ''}'),
                decoration: const InputDecoration(
                    labelText: 'Cantidad', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                initialValue:
                    cantidadActual > 0 ? cantidadActual.toString() : '',
                onChanged: (val) {
                  final parsed = int.tryParse(val) ?? 0;
                  setState(() => _subfilas[index]['cantidad'] = parsed);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                    labelText: 'Talla', border: OutlineInputBorder()),
                value: tallaActual,
                items: tallas
                    .map((talla) => DropdownMenuItem<int>(
                        value: talla, child: Text(talla.toString())))
                    .toList(),
                onChanged: (val) => setState(() => sub['talla'] = val),
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
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.toString())))
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
                      final totalPaginas =
                          (_subfilas.length / _itemsPorPagina).ceil();
                      if (_paginaActual > totalPaginas && totalPaginas > 0) {
                        _paginaActual = totalPaginas;
                      }
                    })),
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

  Widget _buildDropdownConIconos(
      List<Map<String, dynamic>> calzados, bool esEdicion) {
    return IgnorePointer(
      ignoring: esEdicion,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
            labelText: 'Seleccionar código',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: esEdicion ? Colors.grey.shade200 : Colors.white),
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
                  Text(nombre,
                      style: TextStyle(
                          color: esEdicion ? Colors.grey : Colors.black))
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargandoDatos) return const SplashScreen02();

    final List<int> subfilasFiltradasIndices = [];
    for (int i = 0; i < _subfilas.length; i++) {
      final sub = _subfilas[i];

      final bool coincideTalla =
          _filtroTalla == null || sub['talla'] == _filtroTalla;
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

      if (coincideTalla &&
          coincideTaco &&
          coincidePlataforma &&
          coincideColor) {
        subfilasFiltradasIndices.add(i);
      }
    }

    final int totalSubfilas = _subfilas.length;
    final int visibles = subfilasFiltradasIndices.length;
    final int ocultas = totalSubfilas - visibles;

    // 1. Invertimos la lista filtrada completa: El elemento más nuevo queda en la posición 0
    final List<int> indicesInvertidos = subfilasFiltradasIndices.reversed.toList();

    // 2. Calculamos los rangos según la página activa
    final int inicio = (_paginaActual - 1) * _itemsPorPagina;
    final int fin = (inicio + _itemsPorPagina < indicesInvertidos.length)
        ? inicio + _itemsPorPagina
        : indicesInvertidos.length;

    // 3. Extraemos el bloque correspondientes a la página activa
    final List<int> indicesPaginados = (inicio < indicesInvertidos.length)
        ? indicesInvertidos.sublist(inicio, fin)
        : [];

    return Scaffold(
      appBar: Designwidgets().appBarMain(
          widget.filaId != null ? "Editar por Código" : "Agregado por Código"),
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

                  final calzados = widget.filaId == null
                      ? snapshot.data!
                          .where((item) =>
                              item['activo'] == true || item['activo'] == 1)
                          .toList()
                      : snapshot.data!;

                  if (calzados.isEmpty) {
                    return const Text('No tienes calzados registrados.');
                  }

                  return _buildDropdownConIconos(
                      calzados, widget.filaId != null);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                  initialValue: _cantidadFila > 0 ? '$_cantidadFila' : '',
                  decoration: const InputDecoration(
                      labelText: 'Cantidad total',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _cantidadFila = int.tryParse(v) ?? 0),
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
                    if (_cantidadFila <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Primero ingresa una cantidad total')));
                      return;
                    }
                    if (_subfilas.length >= _cantidadFila) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('No puede exceder la cantidad total')));
                      return;
                    }
                    final totalActual = _subfilas.fold<int>(0,
                        (suma, item) => suma + (item['cantidad'] ?? 0) as int);
                    if (totalActual >= _cantidadFila) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Ya suman la cantidad total')));
                      return;
                    }
                    setState(() {
                      _subfilas.add({
                        'cantidad': 0,
                        'talla': 0,
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
                    onPressed: _guardarFilaInventario,
                    icon: Icon(
                        widget.filaId != null ? Icons.save_as : Icons.save),
                    label: Text(widget.filaId == null
                        ? 'Guardar inventario'
                        : 'Actualizar inventario')),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

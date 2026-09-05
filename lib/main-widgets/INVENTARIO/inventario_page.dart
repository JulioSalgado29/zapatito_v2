import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/INVENTARIO/inventario_form_page.dart';
import 'package:zapatito_v2/main-widgets/INVENTARIO/inventario_form_page_color.dart';
import 'package:zapatito_v2/main-widgets/INVENTARIO/inventario_form_page_serie.dart';
import 'package:zapatito_v2/services/API/calzado.dart';
import 'package:zapatito_v2/services/API/fila_inventario.dart';
import 'package:zapatito_v2/services/API/inventario.dart';
import 'package:zapatito_v2/services/API/usuario.dart';

class InventarioPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;
  final bool? isVendedor;

  const InventarioPage({
    super.key,
    this.firstName,
    this.emailUser,
    this.inventarioId,
    this.isVendedor,
  });

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  String? inventarioId;
  List<Map<String, dynamic>> _todasLasFilas = [];

  // Controladores de Búsqueda y Filtros
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tallaController = TextEditingController();
  final TextEditingController _tacoController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  bool _cargando = true;
  bool _mostrarFiltros = false; // Estado del panel colapsable

  String _searchQuery = '';
  String _filtroTalla = '';
  String _filtroTaco = '';
  String _filtroColor = '';

  bool tieneCalzadoConColores = false;

  @override
  void initState() {
    super.initState();
    InventarioService.validarYRedirigir(context, widget.inventarioId);
    _escucharControladores();
    _cargarDatosIniciales();
  }

  void _escucharControladores() {
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _tallaController.addListener(() {
      setState(() => _filtroTalla = _tallaController.text);
    });
    _tacoController.addListener(() {
      setState(() => _filtroTaco = _tacoController.text);
    });
    _colorController.addListener(() {
      setState(() => _filtroColor = _colorController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tallaController.dispose();
    _tacoController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  // Carga paralela de colores, filas y catálogo
  Future<void> _cargarDatosIniciales() async {
    if (widget.inventarioId == null) return;

    setState(() => _cargando = true);

    try {
      final resultados = await Future.wait([
        UsuarioService.verificarTieneCalzadoConColores(widget.inventarioId),
        FilaInventarioService.obtenerPorInventario(widget.inventarioId!),
        CalzadoService.obtenerPorInventario(widget.inventarioId!),
      ]);

      final bool resultadoColores = resultados[0] as bool;
      final filas = List<Map<String, dynamic>>.from(resultados[1] as List);
      final calzados = List<Map<String, dynamic>>.from(resultados[2] as List);

      // Mapa rápido de calzados
      final Map<String, Map<String, dynamic>> mapaCalzados = {
        for (var c in calzados)
          (c['id_calzado'] ?? c['id'])?.toString() ?? '': c
      };

      // Subfilas en paralelo
      final futuresSubfilas = filas.map((fila) {
        final filaId = fila['id_fila_inventario']?.toString() ?? '';
        return FilaInventarioService.obtenerSubfilas(filaId);
      }).toList();

      final listaSubfilas = await Future.wait(futuresSubfilas);

      // Inyección de datos
      for (int i = 0; i < filas.length; i++) {
        final idCalzado = filas[i]['id_calzado']?.toString() ?? '';
        final calzadoData = mapaCalzados[idCalzado];

        filas[i]['nombre_calzado'] = calzadoData?['nombre'] ?? 'Sin nombre';
        filas[i]['calzado_data'] = {
          'nombre': calzadoData?['nombre'] ?? 'Sin nombre',
          'icono': calzadoData?['icono'],
          'taco': calzadoData?['taco'] ?? true,
          'plataforma': calzadoData?['plataforma'] ?? true,
          'colores': calzadoData?['colores'] ?? true,
          'activo': calzadoData?['activo'] ?? true,
        };
        filas[i]['subfilas'] = listaSubfilas[i];
      }

      if (mounted) {
        setState(() {
          tieneCalzadoConColores = resultadoColores;
          _todasLasFilas = filas;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _tallaController.clear();
      _tacoController.clear();
      _colorController.clear();
      _filtroTalla = '';
      _filtroTaco = '';
      _filtroColor = '';
    });
  }

  bool _tieneFiltrosActivos() {
    return _filtroTalla.isNotEmpty ||
        _filtroTaco.isNotEmpty ||
        _filtroColor.isNotEmpty;
  }

  void _mostrarSplashScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const SplashScreen02(),
    );
  }

  void _ocultarSplashScreen() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _eliminarFila(String filaId) async {
    await FilaInventarioService.eliminar(filaId);

    _ocultarSplashScreen();
    _ocultarSplashScreen();

    await Future.delayed(const Duration(milliseconds: 150));

    if (mounted) {
      _cargarDatosIniciales();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código de inventario eliminado correctamente 🗑️'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _abrirFormulario({String? filaId}) async {
    final String? idValido =
        (filaId != null && filaId.isNotEmpty) ? filaId : null;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventarioFormPage(
          firstName: widget.firstName,
          emailUser: widget.emailUser,
          inventarioId: widget.inventarioId,
          filaId: idValido,
        ),
      ),
    );

    if (result == true) {
      _cargarDatosIniciales();
    }
  }

  Future<void> _abrirFormularioSerie() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventarioSerieFormPage(
          firstName: widget.firstName,
          emailUser: widget.emailUser,
          inventarioId: widget.inventarioId,
        ),
      ),
    );

    if (result == true) {
      _cargarDatosIniciales();
    }
  }

  Future<void> _abrirFormularioColor() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventarioFormPageColor(
          firstName: widget.firstName,
          emailUser: widget.emailUser,
          inventarioId: widget.inventarioId,
        ),
      ),
    );
    if (result == true) {
      _cargarDatosIniciales();
    }
  }

  Widget _buildIcon(String? icono) {
    if (icono == null || icono.isEmpty) {
      return const Icon(
        Icons.shopping_bag_outlined,
        size: 40,
        color: Colors.blueAccent,
      );
    }

    final lower = icono.toLowerCase();

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return Image.network(
        icono,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, size: 40),
      );
    }

    return Image.asset(
      icono,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.image_not_supported, size: 40),
    );
  }

  void _confirmarEliminacion(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 20,
        backgroundColor: Colors.black.withOpacity(0.85),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 33, 47, 243),
                Color(0xFF4A5AF7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Eliminar código de inventario?',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Esta acción no se puede deshacer.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      _mostrarSplashScreen();
                      await _eliminarFila(id);
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, {bool isColor = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isColor ? Colors.indigo[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isColor ? Colors.indigo[100]! : Colors.grey[300]!,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isColor ? Colors.indigo[900] : Colors.black87,
          fontWeight: isColor ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEstadoChip(bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: activo ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activo ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Text(
        activo ? 'CODIGO\nACTIVO' : 'CODIGO\nINACTIVO',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          height: 1.1,
          fontWeight: FontWeight.bold,
          color: activo ? Colors.green[700] : Colors.red[700],
        ),
      ),
    );
  }

  Widget _buildInputFiltro({
  required TextEditingController controller,
  required String label,
  required IconData icon,
}) {
  return TextField(
    controller: controller, // El listener del initState detecta el cambio automáticamente
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      prefixIcon: Icon(icon, size: 16, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    if (widget.inventarioId == null || _cargando) {
      return const SplashScreen02();
    }

    // Filtrado considerando Nombre de Calzado y propiedades de Subfilas
    final filasFiltradas = _todasLasFilas.where((fila) {
      // 1. Filtro por Nombre
      final nombre = (fila['nombre_calzado'] ?? '').toString().toLowerCase();
      if (!nombre.contains(_searchQuery.trim().toLowerCase())) {
        return false;
      }

      // Si no hay filtros secundarios activos, se aprueba la fila
      if (!_tieneFiltrosActivos()) return true;

      // 2. Filtro por Subfilas
      final List subfilas = (fila['subfilas'] as List?) ?? [];

      return subfilas.any((sub) {
        // Convertimos a Map seguro
        final subMap = sub as Map<String, dynamic>? ?? {};

        // Extraemos valores asegurando string y evaluando llaves alternativas
        final String talla = (subMap['talla'] ?? subMap['talla_calzado'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final String taco = (subMap['taco'] ?? subMap['taco_calzado'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final String color = (subMap['colores'] ?? subMap['color'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        // Verificación de coincidencias
        final bool coincideTalla = _filtroTalla.trim().isEmpty ||
            talla.contains(_filtroTalla.trim().toLowerCase());

        final bool coincideTaco = _filtroTaco.trim().isEmpty ||
            taco.contains(_filtroTaco.trim().toLowerCase());

        final bool coincideColor = _filtroColor.trim().isEmpty ||
            color.contains(_filtroColor.trim().toLowerCase());

        return coincideTalla && coincideTaco && coincideColor;
      });
    }).toList();

    return Scaffold(
      appBar: Designwidgets().appBarMain("Inventario"),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Barra superior: Buscador + Botón Alternar Filtros
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar por calzado...',
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.blueAccent),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: _tieneFiltrosActivos()
                        ? Colors.blueAccent
                        : Colors.grey.shade200,
                    foregroundColor:
                        _tieneFiltrosActivos() ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: Icon(_mostrarFiltros
                      ? Icons.filter_alt_off
                      : Icons.filter_alt),
                  onPressed: () {
                    setState(() {
                      _mostrarFiltros = !_mostrarFiltros;
                    });
                  },
                ),
              ],
            ),

            // Panel Colapsable de Filtros Secundarios
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _mostrarFiltros ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _mostrarFiltros ? 1.0 : 0.0,
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputFiltro(
                                controller: _tallaController,
                                label: 'Talla',
                                icon: Icons.straighten,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInputFiltro(
                                controller: _tacoController,
                                label: 'Taco',
                                icon: Icons.height,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInputFiltro(
                                controller: _colorController,
                                label: 'Color',
                                icon: Icons.palette_outlined,
                              ),
                            ),
                          ],
                        ),
                        if (_tieneFiltrosActivos()) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _limpiarFiltros,
                              icon: const Icon(
                                Icons.cleaning_services_rounded,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                              label: const Text(
                                'Limpiar Filtros',
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Lista de Resultados
            Expanded(
              child: filasFiltradas.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty && !_tieneFiltrosActivos()
                            ? 'No hay filas de inventario registradas.'
                            : 'No se encontraron coincidencias con los filtros aplicados.',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarDatosIniciales,
                      child: ListView.builder(
                        itemCount: filasFiltradas.length,
                        itemBuilder: (context, index) {
                          final fila = filasFiltradas[index];
                          final filaId =
                              fila['id_fila_inventario']?.toString() ??
                                  index.toString();

                          return _FilaInventarioItem(
                            key: ValueKey(filaId),
                            fila: fila,
                            isVendedor: widget.isVendedor,
                            onEliminar: (id) =>
                                _confirmarEliminacion(context, id),
                            onEditar: (id) => _abrirFormulario(filaId: id),
                            buildIcon: _buildIcon,
                            buildEstadoChip: _buildEstadoChip,
                            buildInfoChip: _buildInfoChip,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFab(
            Designwidgets().linearGradientBlue(context),
            "btn1",
            _abrirFormulario,
            "Codigo",
            Icons.add_circle_outline,
          ),
          const SizedBox(height: 12),
          if (tieneCalzadoConColores) ...[
            _buildFab(
              Designwidgets().linearGradientPurple(context),
              "btn2",
              _abrirFormularioColor,
              "Color",
              Icons.add_circle_outline,
            ),
            const SizedBox(height: 12),
          ],
          _buildFab(
            Designwidgets().linearGradientFire(context),
            "btn3",
            _abrirFormularioSerie,
            "Por serie",
            Icons.inventory_2,
          ),
        ],
      ),
    );
  }
}

Widget _buildFab(
  Gradient gradient,
  String tag,
  VoidCallback onPressed,
  String label,
  IconData icon,
) {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: tag,
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}

class _FilaInventarioItem extends StatelessWidget {
  final Map<String, dynamic> fila;
  final bool? isVendedor;
  final Function(String) onEliminar;
  final Function(String) onEditar;
  final Widget Function(String?) buildIcon;
  final Widget Function(bool) buildEstadoChip;
  final Widget Function(String, {bool isColor}) buildInfoChip;

  const _FilaInventarioItem({
    super.key,
    required this.fila,
    this.isVendedor,
    required this.onEliminar,
    required this.onEditar,
    required this.buildIcon,
    required this.buildEstadoChip,
    required this.buildInfoChip,
  });

  @override
  Widget build(BuildContext context) {
    final filaId = fila['id_fila_inventario']?.toString() ?? '';
    final cantidad = fila['cantidad'];

    final calzadoData = (fila['calzado_data'] as Map<String, dynamic>?) ?? {};
    final nombreCalzado = calzadoData['nombre'] ?? 'Sin nombre';
    final icono = calzadoData['icono'] as String?;
    final tieneTaco = calzadoData['taco'] ?? true;
    final tienePlataforma = calzadoData['plataforma'] ?? true;
    final tieneColores = calzadoData['colores'] ?? true;
    final estaActivo = calzadoData['activo'] ?? true;

    final List subfilas = (fila['subfilas'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 3,
      child: ExpansionTile(
        leading: buildIcon(icono),
        title: Row(
          children: [
            Expanded(
              child: Text(
                nombreCalzado,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            buildEstadoChip(estaActivo),
          ],
        ),
        subtitle: Text('Cantidad total: $cantidad'),
        trailing: isVendedor != true
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') {
                    onEditar(filaId);
                  } else if (value == 'eliminar') {
                    onEliminar(filaId);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                ],
              )
            : null,
        children: subfilas.isEmpty
            ? const [
                Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Sin subfilas registradas.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ]
            : subfilas.map((sub) {
                final cantSub = sub['cantidad'];
                final talla = sub['talla'];
                final taco = sub['taco'];
                final plataforma = sub['plataforma'];
                final colores = sub['colores'];

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF4E4E4E),
                    ),
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          'Talla: $talla',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Cant: $cantSub',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (tieneTaco) buildInfoChip('Taco: $taco'),
                      if (tienePlataforma && plataforma != null)
                        buildInfoChip('Plataforma: $plataforma'),
                      if (tieneColores &&
                          colores != null &&
                          colores.toString().isNotEmpty)
                        buildInfoChip('Color: $colores', isColor: true),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }
}

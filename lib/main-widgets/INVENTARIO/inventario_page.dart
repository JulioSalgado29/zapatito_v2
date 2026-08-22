import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/INVENTARIO/inventario_form_page.dart';
import 'package:zapatito_v2/main-widgets/INVENTARIO/inventario_form_page_serie.dart';
import 'package:zapatito_v2/services/API/calzado.dart';
import 'package:zapatito_v2/services/API/fila_inventario.dart';
import 'package:zapatito_v2/services/API/inventario.dart';

class InventarioPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  const InventarioPage(
      {super.key, this.firstName, this.emailUser, this.inventarioId});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  String? inventarioId;
  List<Map<String, dynamic>> _todasLasFilas = [];
  final TextEditingController _searchController = TextEditingController();
  bool _cargando = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarFilas();
    InventarioService.validarYRedirigir(context, widget.inventarioId);
  }

  Future<void> _cargarFilas() async {
    if (widget.inventarioId == null) return;

    setState(() => _cargando = true);

    try {
      // 1. Obtenemos las filas y el catálogo de calzados en paralelo
      final resultados = await Future.wait([
        FilaInventarioService.obtenerPorInventario(widget.inventarioId!),
        CalzadoService.obtenerPorInventario(widget.inventarioId!),
      ]);

      final filas = resultados[0];
      final calzados = resultados[1];

      // 2. Creamos un mapa rápido de id_calzado -> nombre
      final Map<String, String> mapaNombres = {
        for (var c in calzados)
          (c['id_calzado'] ?? c['id'])?.toString() ?? '':
              (c['nombre'] ?? 'Sin nombre').toString()
      };

      // 3. Adjuntamos el nombre a cada fila para el filtro dinámico
      for (var fila in filas) {
        final idCalzado = fila['id_calzado']?.toString() ?? '';
        fila['nombre_calzado'] = mapaNombres[idCalzado] ?? 'Sin nombre';
      }

      setState(() {
        _todasLasFilas = filas;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<Map<String, dynamic>> _getDatosCalzado(String calzadoId) async {
    // Llamada al método estático de tu servicio (ajusta 'CalzadoService' según el nombre de tu clase)
    final calzadoData = await CalzadoService.obtenerPorId(calzadoId);

    // Si la API devuelve null (no lo encuentra o error de red), retorna los valores por defecto
    if (calzadoData == null) {
      return {
        'nombre': 'Sin nombre',
        'icono': null,
        'taco': true,
        'plataforma': true,
        'colores': true,
        'activo': false,
      };
    }

    // Mapeo seguro con valores por defecto desde la respuesta JSON de PostgreSQL
    return {
      'nombre': calzadoData['nombre'] ?? 'Sin nombre',
      'icono': calzadoData['icono'],
      'taco': calzadoData['taco'] ?? true,
      'plataforma': calzadoData['plataforma'] ?? true,
      'colores': calzadoData['colores'] ?? true,
      'activo': calzadoData['activo'] ?? true,
    };
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
      setState(() {
        _cargarFilas(); // 👈 Recarga la lista tras eliminar
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Codigo de inventario eliminado correctamente 🗑️'),
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
      setState(() {
        _cargarFilas(); // 👈 Recarga los datos solo cuando se crea/edita algo
      });
    }
  }

  Future<void> _abrirFormularioSerie() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InventarioSerieFormPage(
            firstName: widget.firstName,
            emailUser: widget.emailUser,
            inventarioId: widget.inventarioId),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Widget _buildIcon(String? icono) {
    if (icono == null || icono.isEmpty) {
      return const Icon(Icons.shopping_bag_outlined,
          size: 40, color: Colors.blueAccent);
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
              const Icon(Icons.warning_amber_rounded,
                  size: 60, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                '¿Eliminar codigo de inventario?',
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
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.cancel, color: Colors.white),
                    label: const Text('Cancelar',
                        style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () async {
                      _mostrarSplashScreen();
                      await _eliminarFila(id);
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Eliminar',
                        style: TextStyle(color: Colors.white)),
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
            color: isColor ? Colors.indigo[100]! : Colors.grey[300]!),
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
        border:
            Border.all(color: activo ? Colors.green[200]! : Colors.red[200]!),
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

  @override
  Widget build(BuildContext context) {
    if (widget.inventarioId == null) {
      return const SplashScreen02();
    }

    final filasFiltradas = _todasLasFilas.where((fila) {
      final nombre = (fila['nombre_calzado'] ?? '').toString().toLowerCase();
      return nombre.contains(_searchQuery.trim().toLowerCase());
    }).toList();

    return Scaffold(
      appBar: Designwidgets().appBarMain("Inventario"),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // 🔹 Campo de texto para buscar por Nombre
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre de calzado...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
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
                  borderSide:
                      const BorderSide(color: Colors.blueAccent, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 🔹 Renderizado de lista
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : filasFiltradas.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No hay filas de inventario registradas.'
                                : 'No se encontraron calzados con "$_searchQuery"',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarFilas,
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
                                getDatosCalzado: _getDatosCalzado,
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
            "Manual",
            Icons.add_circle_outline,
          ),
          const SizedBox(height: 12),
          _buildFab(
            Designwidgets().linearGradientFire(context),
            "btn2",
            _abrirFormularioSerie,
            "Por serie",
            Icons.inventory_2,
          ),
        ],
      ),
    );
  }
}

Widget _buildFab(Gradient gradient, String tag, VoidCallback onPressed,
    String label, IconData icon) {
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
        icon: Icon(icon, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    ),
  );
}

class _FilaInventarioItem extends StatefulWidget {
  final Map<String, dynamic> fila;
  final Future<Map<String, dynamic>> Function(String) getDatosCalzado;
  final Function(String) onEliminar;
  final Function(String) onEditar;
  final Widget Function(String?) buildIcon;
  final Widget Function(bool) buildEstadoChip;
  final Widget Function(String, {bool isColor}) buildInfoChip;

  const _FilaInventarioItem({
    super.key,
    required this.fila,
    required this.getDatosCalzado,
    required this.onEliminar,
    required this.onEditar,
    required this.buildIcon,
    required this.buildEstadoChip,
    required this.buildInfoChip,
  });

  @override
  State<_FilaInventarioItem> createState() => _FilaInventarioItemState();
}

class _FilaInventarioItemState extends State<_FilaInventarioItem>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> _calzadoFuture;
  late Future<List<Map<String, dynamic>>> _subfilasFuture;

  @override
  bool get wantKeepAlive => true; // 👈 Mantiene vivo el ítem al hacer scroll

  @override
  void initState() {
    super.initState();
    final filaId = widget.fila['id_fila_inventario']?.toString() ?? '';
    final calzadoId = widget.fila['id_calzado']?.toString() ?? '';

    _calzadoFuture = widget.getDatosCalzado(calzadoId);
    _subfilasFuture = FilaInventarioService.obtenerSubfilas(filaId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filaId = widget.fila['id_fila_inventario']?.toString() ?? '';
    final cantidad = widget.fila['cantidad'];

    return FutureBuilder<Map<String, dynamic>>(
      future: _calzadoFuture,
      builder: (context, calzadoSnap) {
        if (!calzadoSnap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: LinearProgressIndicator(),
          );
        }

        final calzadoData = calzadoSnap.data!;
        final nombreCalzado = calzadoData['nombre'] ?? 'Sin nombre';
        final icono = calzadoData['icono'] as String?;
        final tieneTaco = calzadoData['taco'] ?? true;
        final tienePlataforma = calzadoData['plataforma'] ?? true;
        final tieneColores = calzadoData['colores'] ?? true;
        final estaActivo = calzadoData['activo'] ?? true;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _subfilasFuture,
          builder: (context, subfilaSnap) {
            if (subfilaSnap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              );
            }

            final subfilas = subfilaSnap.data ?? [];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              elevation: 3,
              child: ExpansionTile(
                leading: widget.buildIcon(icono),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombreCalzado,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    widget.buildEstadoChip(estaActivo),
                  ],
                ),
                subtitle: Text('Cantidad total: $cantidad'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'editar') {
                      widget.onEditar(filaId); // 🔹 LLAMAR A LA FUNCIÓN AQUÍ
                    } else if (value == 'eliminar') {
                      widget.onEliminar(filaId);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                  ],
                ),
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
                        final cantidad = sub['cantidad'];
                        final talla = sub['talla'];
                        final taco = sub['taco'];
                        final plataforma = sub['plataforma'];
                        final colores = sub['colores'];

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: Color(0xFF4E4E4E)),
                          ),
                          title: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Text(
                                  'Talla: $talla',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const Spacer(),
                                Text(
                                  'Cant: $cantidad',
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
                              if (tieneTaco)
                                widget.buildInfoChip('Taco: $taco'),
                              if (tienePlataforma && plataforma != null)
                                widget.buildInfoChip('Plataforma: $plataforma'),
                              if (tieneColores &&
                                  colores != null &&
                                  colores.toString().isNotEmpty)
                                widget.buildInfoChip('Color: $colores',
                                    isColor: true),
                            ],
                          ),
                        );
                      }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

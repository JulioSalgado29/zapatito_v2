import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/CALZADO/calzado_form_page.dart';
import 'package:zapatito_v2/services/API/calzado.dart';
import 'package:zapatito_v2/services/API/inventario.dart';
import 'package:zapatito_v2/services/API/tipo_calzado.dart';

class CalzadoPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;
  final bool? isAlmacenero;

  const CalzadoPage(
      {super.key,
      this.firstName,
      this.emailUser,
      this.inventarioId,
      this.isAlmacenero});

  @override
  State<CalzadoPage> createState() => _CalzadoPageState();
}

class _CalzadoPageState extends State<CalzadoPage> {
  bool isOnline = true;

  // 1. Nuevas variables de estado para el filtro
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _todosLosCalzados = [];
  bool _cargando = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    InventarioService.validarYRedirigir(context, widget.inventarioId);
    _cargarCalzados(); // Carga inicial
  }

  @override
  void dispose() {
    _searchController.dispose(); // Limpieza de memoria
    super.dispose();
  }

  // Carga los datos de la API en memoria
  Future<void> _cargarCalzados() async {
    if (widget.inventarioId == null) return;
    setState(() => _cargando = true);

    final datos = await CalzadoService.obtenerPorInventario(
        widget.inventarioId.toString());

    setState(() {
      _todosLosCalzados = datos;
      _cargando = false;
    });
  }

  void _navegarFormulario({Map<String, dynamic>? calzado}) async {
    final seGuardo = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CalzadoFormPage(
          firstName: widget.firstName,
          emailUser: widget.emailUser,
          inventarioId: widget.inventarioId,
          isAlmacenero: widget.isAlmacenero,
          calzado: calzado,
        ),
      ),
    );

    if (seGuardo == true) {
      _cargarCalzados(); // Recarga la lista local tras guardar/editar
    }
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
              const Text(
                '¿Eliminar código?',
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
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
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      _mostrarSplashScreen();

                      final exito = await CalzadoService.eliminar(id);

                      _ocultarSplashScreen();
                      await Future.delayed(const Duration(milliseconds: 150));

                      if (context.mounted) {
                        if (exito) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Código eliminado correctamente 🗑️'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          _cargarCalzados(); // Recarga los datos al eliminar
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo eliminar el calzado ❌'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _obtenerIconoTipo(String? tipoId) async {
    if (tipoId == null || tipoId.isEmpty) return "❓";

    final listado = await TipoCalzadoService.obtenerTodosPorInventario(
        widget.inventarioId.toString());

    final coincide = listado.firstWhere(
      (e) {
        final idEnMap = (e['id_tipo_calzado'] ?? e['id'])?.toString();
        return idEnMap == tipoId.toString();
      },
      orElse: () => <String, dynamic>{},
    );

    return (coincide['icono'] ?? "❓").toString();
  }

  Widget _buildFeatureChip(IconData icon, String label, bool value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: value ? Colors.blue : Colors.grey),
        const SizedBox(width: 4),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Text(
          value ? "Sí" : "No",
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: value ? Colors.green[700] : Colors.red[700]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inventarioId == null) return const SplashScreen02();

    // 2. Filtrado dinámico por nombre del calzado
    final calzadosFiltrados = _todosLosCalzados.where((c) {
      final nombre = (c['nombre'] ?? '').toString().toLowerCase();
      return nombre.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: Designwidgets().appBarMain("Códigos"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 3. Campo de texto para la búsqueda
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

            // 4. Renderizado de la lista filtrada
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : calzadosFiltrados.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'No hay códigos aún'
                                : 'No se encontraron calzados con "$_searchQuery"',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _cargarCalzados,
                          child: ListView.builder(
                            itemCount: calzadosFiltrados.length,
                            itemBuilder: (context, index) {
                              final data = calzadosFiltrados[index];
                              final idCalzado =
                                  data['id_calzado']?.toString() ?? '';
                              final nombre = data['nombre'] ?? '';
                              final precio = double.tryParse(
                                      data['precio_real']?.toString() ?? '0') ??
                                  0.0;
                              final usuario = data['usuario_creacion'] ?? '';
                              final tipoId =
                                  data['id_tipo_calzado']?.toString();
                              final taco = data['taco'] ?? false;
                              final plataforma = data['plataforma'] ?? false;
                              final colores = data['colores'] ?? false;

                              return FutureBuilder<String>(
                                future: _obtenerIconoTipo(tipoId),
                                builder: (context, iconSnapshot) {
                                  final icono = iconSnapshot.data ?? "❓";
                                  final bool mostrarAvisoPrecio =
                                      (precio <= 0 &&
                                          widget.isAlmacenero == false);

                                  return Card(
                                    elevation: 3,
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      children: [
                                        if (mostrarAvisoPrecio)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            color: Colors.red.shade100,
                                            child: const Text(
                                              "⚠️ Falta ingresar el precio",
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          child: ListTile(
                                            leading: (icono
                                                        .toString()
                                                        .endsWith('.png') ||
                                                    icono
                                                        .toString()
                                                        .endsWith('.jpg'))
                                                ? Image.asset(icono,
                                                    width: 45,
                                                    height: 45,
                                                    fit: BoxFit.contain)
                                                : Text(icono,
                                                    style: const TextStyle(
                                                        fontSize: 32)),
                                            title: Text(nombre,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18)),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 12,
                                                  runSpacing: 8,
                                                  children: [
                                                    _buildFeatureChip(
                                                        Icons.height,
                                                        'Taco',
                                                        taco),
                                                    _buildFeatureChip(
                                                        Icons.layers,
                                                        'Plataforma',
                                                        plataforma),
                                                    _buildFeatureChip(
                                                        Icons.palette,
                                                        'Colores',
                                                        colores),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Icon(Icons.account_circle,
                                                        size: 14,
                                                        color:
                                                            Colors.grey[400]),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text.rich(
                                                        TextSpan(
                                                          children: [
                                                            if (widget
                                                                    .isAlmacenero !=
                                                                true) ...[
                                                              TextSpan(
                                                                text:
                                                                    'S/ ${precio.toStringAsFixed(2)}',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .blue
                                                                      .shade800,
                                                                ),
                                                              ),
                                                              const TextSpan(
                                                                text: '  |  ',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .grey),
                                                              ),
                                                            ],
                                                            TextSpan(
                                                              text: widget.isAlmacenero ==
                                                                      true
                                                                  ? 'Creado por: $usuario'
                                                                  : usuario,
                                                              style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors
                                                                          .grey[
                                                                      500]),
                                                            ),
                                                          ],
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            trailing: Wrap(
                                              direction: Axis.vertical,
                                              alignment: WrapAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.blueAccent,
                                                      size: 22),
                                                  onPressed: () =>
                                                      _navegarFormulario(
                                                          calzado: data),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_forever,
                                                      color: Colors.redAccent,
                                                      size: 22),
                                                  onPressed: () =>
                                                      _confirmarEliminacion(
                                                          context, idCalzado),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarFormulario(),
        backgroundColor: const Color.fromARGB(255, 33, 47, 243),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

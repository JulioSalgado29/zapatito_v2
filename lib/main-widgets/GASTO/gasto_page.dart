import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/GASTO/gasto_form.dart';
import 'package:zapatito_v2/services/API/gasto.dart';
import 'package:zapatito_v2/services/API/inventario.dart';
import 'package:zapatito_v2/services/API/tienda.dart'; // 🔹 Import de TiendaService

class GastoPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;
  final String? tiendaId;

  const GastoPage({
    super.key,
    this.firstName,
    this.emailUser,
    this.inventarioId,
    this.tiendaId,
  });

  @override
  State<GastoPage> createState() => _GastoPageState();
}

class _GastoPageState extends State<GastoPage> {
  // 🔹 Estado de Carga / Data local
  bool _isLoading = true;
  bool _isFetchingGastos = false;
  List<Map<String, dynamic>> _gastos = [];
  Map<String, String> _mapaTiendas = {}; // 🔹 Mapa para almacenar id_tienda -> nombre

  @override
  void initState() {
    super.initState();
    _inicializarPagina();
  }

  Future<void> _inicializarPagina() async {
    // Redirección si no hay inventario
    InventarioService.validarYRedirigir(context, widget.inventarioId);

    // Carga inicial de datos y nombres de tiendas una sola vez al entrar
    if (widget.inventarioId != null) {
      await Future.wait([
        _cargarGastos(),
        _cargarNombresTiendas(),
      ]);
    }

    // Mantenemos el SplashScreen visible un breve momento para suavizar la transición
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔹 Carga manual de datos al renderizar o tras eventos de cambio
  Future<void> _cargarGastos() async {
    if (widget.inventarioId == null) return;
    if (mounted) setState(() => _isFetchingGastos = true);

    try {
      final data = await GastoService.obtenerPorInventario(widget.inventarioId!);
      if (mounted) {
        setState(() {
          _gastos = data;
          _isFetchingGastos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _gastos = [];
          _isFetchingGastos = false;
        });
      }
    }
  }

  // 🔹 Carga el listado de tiendas para mapear los IDs con sus nombres
  Future<void> _cargarNombresTiendas() async {
    if (widget.inventarioId == null) return;
    try {
      final listaTiendas = await TiendaService.obtenerPorInventario(widget.inventarioId!);
      final Map<String, String> mapaTemp = {};
      for (var tienda in listaTiendas) {
        final id = tienda['id_tienda']?.toString();
        final nombre = tienda['nombre']?.toString();
        if (id != null && nombre != null) {
          mapaTemp[id] = nombre;
        }
      }
      if (mounted) {
        setState(() {
          _mapaTiendas = mapaTemp;
        });
      }
    } catch (_) {
      // Manejo silencioso en caso de error al traer las tiendas
    }
  }

  void _confirmarEliminacion(String id, String montoFormateado) {
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
                '¿Eliminar Gasto?',
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '¿Seguro que deseas eliminar el gasto por S/ $montoFormateado? Esta acción no se puede deshacer.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón Eliminar
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx); // Cierra el diálogo de confirmación
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const SplashScreen02(),
                      );

                      try {
                        final bool exito = await GastoService.eliminar(id);

                        if (mounted && Navigator.canPop(context)) {
                          Navigator.pop(context); // Cierra el SplashScreen02
                        }

                        if (mounted) {
                          if (exito) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Gasto quitado de la lista correctamente 🗑️'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                            await _cargarGastos(); // Recarga la lista local
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo eliminar el gasto'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al procesar: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Eliminar',
                        style: TextStyle(color: Colors.white)),
                  ),
                  // Botón Cancelar
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContenidoGastos() {
    if (_isFetchingGastos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_gastos.isEmpty) {
      return const Center(child: Text('No hay gastos registrados.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _gastos.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final data = _gastos[index];

        final String id = data['id_gasto']?.toString() ?? '';
        final double monto =
            double.tryParse(data['monto']?.toString() ?? '0') ?? 0.0;
        final String descripcion = data['descripcion'] ?? '';
        final String usuarioCreacion =
            data['usuario_creacion'] ?? 'Anónimo';
        final String montoFormateado = monto.toStringAsFixed(2);
        
        final dynamic idTiendaRegistro = data['id_tienda'];
        final String tiendaIdStr = idTiendaRegistro?.toString() ?? '';
        // 🔹 Obtiene el nombre del mapa, o usa un texto alternativo si no se encuentra
        final String nombreTienda = _mapaTiendas[tiendaIdStr] ?? 'Tienda principal';

        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.black12,
            child: Text(
              'S/',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          title: Text(
            'S/ $montoFormateado',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Indicador visual del nombre de la tienda
              if (descripcion.isNotEmpty)
                Text(
                  descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.store,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      nombreTienda,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      usuarioCreacion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Editar
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: Color.fromARGB(255, 33, 47, 243),
                ),
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GastoForm(
                        firstName: widget.firstName,
                        emailUser: widget.emailUser,
                        inventarioId: widget.inventarioId,
                        tiendaId: idTiendaRegistro?.toString() ?? widget.tiendaId,
                        gastoId: id,
                        montoInicial: monto,
                        descripcionInicial: descripcion,
                      ),
                    ),
                  );

                  if (res == true) {
                    await _cargarGastos();
                  }
                },
              ),
              // Botón Eliminar
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () =>
                    _confirmarEliminacion(id, montoFormateado),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Muestra el SplashScreen02 mientras inicializa o falta inventarioId
    if (_isLoading || widget.inventarioId == null) {
      return const SplashScreen02();
    }

    return Scaffold(
      appBar: Designwidgets().appBarMain('Control de Gastos'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 33, 47, 243),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GastoForm(
                firstName: widget.firstName,
                emailUser: widget.emailUser,
                inventarioId: widget.inventarioId,
                tiendaId: widget.tiendaId,
              ),
            ),
          );

          if (res == true) {
            await _cargarGastos();
          }
        },
      ),
      body: _buildContenidoGastos(),
    );
  }
}
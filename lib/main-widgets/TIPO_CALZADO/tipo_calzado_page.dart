import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/TIPO_CALZADO/tipo_calzado_form.dart';
import 'package:zapatito_v2/services/API/inventario.dart';
import 'package:zapatito_v2/services/API/tipo_calzado.dart';

class TipoCalzadoPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  const TipoCalzadoPage(
      {super.key, this.firstName, this.emailUser, this.inventarioId});

  @override
  State<TipoCalzadoPage> createState() => _TipoCalzadoPageState();
}

class _TipoCalzadoPageState extends State<TipoCalzadoPage> {
  @override
  void initState() {
    super.initState();
    InventarioService.validarYRedirigir(context, widget.inventarioId);
  }

  Future<dynamic> _mostrarFormulario({Map<String, dynamic>? item}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: TipoCalzadoForm(
          firstName: widget.firstName,
          emailUser: widget.emailUser,
          inventarioId: widget.inventarioId,
          itemData: item,
        ),
      ),
    );
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

  Future<bool?> _confirmarEliminacion(BuildContext context, String id) async {
    return showDialog<bool>(
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
                '¿Eliminar tipo de calzado?',
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

                      // 🔹 Invocación al servicio REST para la baja lógica
                      final bool exito = await TipoCalzadoService.eliminar(id);

                      _ocultarSplashScreen();

                      await Future.delayed(const Duration(milliseconds: 150));

                      if (context.mounted) {
                        if (exito) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Tipo de calzado eliminado correctamente 🗑️'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          setState(() {});
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Error al eliminar el tipo de calzado'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Eliminar',
                        style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label, bool value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: value ? Colors.blue : Colors.grey),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),
        Text(
          value ? "Sí" : "No",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: value ? Colors.green[700] : Colors.red[700],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inventarioId == null) {
      return const SplashScreen02();
    }
    return Scaffold(
      appBar: Designwidgets().appBarMain("Tipo de Calzado"),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: TipoCalzadoService.obtenerPorInventario(
              widget.inventarioId ?? ''),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar'));
            }

            final lista = snapshot.data ?? [];

            if (lista.isEmpty) {
              return const Center(child: Text('No hay tipos de calzado aún'));
            }

            return ListView.builder(
              itemCount: lista.length,
              itemBuilder: (context, index) {
                final item = lista[index];
                final String id = item['id_tipo_calzado']?.toString() ?? '';
                final nombre = item['nombre'] ?? '';
                final icono = item['icono'] ?? '🥿';
                final usuario = item['usuario_creacion'] ?? '';
                final taco = item['taco'] ?? false;
                final plataforma = item['plataforma'] ?? false;
                final colores = item['colores'] ?? false;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: (icono.toString().endsWith('.png') ||
                              icono.toString().endsWith('.jpg'))
                          ? Image.asset(
                              icono,
                              width: 45,
                              height: 45,
                              fit: BoxFit.contain,
                            )
                          : Text(
                              icono,
                              style: const TextStyle(fontSize: 32),
                            ),
                      title: Text(
                        nombre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _buildFeatureChip(Icons.height, 'Taco', taco),
                              _buildFeatureChip(
                                  Icons.layers, 'Plataforma', plataforma),
                              _buildFeatureChip(
                                  Icons.palette, 'Colores', colores),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.account_circle,
                                  size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Creado por: $usuario',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[500]),
                                  overflow: TextOverflow.ellipsis,
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
                                color: Colors.blueAccent, size: 22),
                            onPressed: () async {
                              final res = await _mostrarFormulario(item: item);
                              if (res == true && mounted) {
                                setState(() {});
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.redAccent,
                              size: 22,
                            ),
                            onPressed: () async {
                              // 🔹 Esperamos a que el diálogo cierre y devuelva true si eliminó
                              final res =
                                  await _confirmarEliminacion(context, id);

                              // 🔹 Si eliminó con éxito, refrescamos la pantalla principal
                              if (res == true && mounted) {
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 🔹 Esperamos la respuesta que envía Navigator.pop(context, true) al guardar
          final res = await _mostrarFormulario();

          // 🔹 Si el formulario retornó true, refrescamos el FutureBuilder
          if (res == true && mounted) {
            setState(() {});
          }
        },
        backgroundColor: const Color.fromARGB(255, 33, 47, 243),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

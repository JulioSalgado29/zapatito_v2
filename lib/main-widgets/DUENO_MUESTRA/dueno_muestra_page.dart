import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/DUENO_MUESTRA/dueno_muestra_form.dart';
import 'package:zapatito_v2/services/API/dueno_muestra.dart';
import 'package:zapatito_v2/services/API/inventario.dart';

class DuenoMuestraPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;
  const DuenoMuestraPage(
      {super.key, this.firstName, this.emailUser, this.inventarioId});

  @override
  State<DuenoMuestraPage> createState() => _DuenoMuestraPageState();
}

class _DuenoMuestraPageState extends State<DuenoMuestraPage> {
  @override
  void initState() {
    super.initState();
    InventarioService.validarYRedirigir(context, widget.inventarioId);
  }

  void _confirmarEliminacion(String id, String nombre) {
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
                '¿Eliminar Dueño?',
                style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '¿Seguro que deseas eliminar a "$nombre"? Esta acción no se puede deshacer.',
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
                      Navigator.pop(
                          ctx); // Cierra el diálogo de confirmación previa
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const SplashScreen02(),
                      );

                      try {
                        // 🔹 CAMBIO: Invocación al servicio REST en lugar de Firestore
                        final bool exito =
                            await DuenoMuestraService.eliminar(id);

                        // Cierra el indicador de carga (SplashScreen02)
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }

                        if (mounted) {
                          if (exito) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Dueño quitado de la lista correctamente 🗑️'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.orangeAccent,
                              ),
                            );
                            setState(() {});
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'No se pudo eliminar el dueño de la muestra'),
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

  @override
  Widget build(BuildContext context) {
    if (widget.inventarioId == null) {
      return const SplashScreen02();
    }
    return Scaffold(
      appBar: Designwidgets().appBarMain('Dueños de Muestras'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 33, 47, 243),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          // 🔹 Esperamos a que regrese de la pantalla del formulario
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DuenoMuestraForm(
                firstName: widget.firstName,
                emailUser: widget.emailUser,
                inventarioId: widget.inventarioId,
              ),
            ),
          );

          // 🔹 Si el formulario retornó `true` al crear, refrescamos el FutureBuilder
          if (res == true && mounted) {
            setState(() {});
          }
        },
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future:
            DuenoMuestraService.obtenerPorInventario(widget.inventarioId ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar'));
          }

          final lista = snapshot.data ?? [];
          if (lista.isEmpty) {
            return const Center(child: Text('No hay registros disponibles.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final data = lista[index];
              // 🔹 ID extraído de la columna de PostgreSQL 'id_dueno_muestra'
              final String id = data['id_dueno_muestra']?.toString() ?? '';
              final String nombre = data['nombre'] ?? 'Sin nombre';

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.black12,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                title: Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                // 🔹 Trailing con botones de Editar y Eliminar
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón Editar Azul
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Color.fromARGB(255, 33, 47, 243),
                      ),
                      onPressed: () async {
                        // 🔹 Esperamos la respuesta que envía el Navigator.pop(context, true)
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DuenoMuestraForm(
                              firstName: widget.firstName,
                              emailUser: widget.emailUser,
                              inventarioId: widget.inventarioId,
                              duenoId: id,
                              nombreInicial: nombre,
                            ),
                          ),
                        );

                        // 🔹 Si regresó con true, recargamos la vista
                        if (res == true && mounted) {
                          setState(() {});
                        }
                      },
                    ),
                    // Botón Eliminar Rojo
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _confirmarEliminacion(id, nombre),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/main-widgets/CIERRE_CAJA/cierre_caja_form.dart';
import 'package:zapatito_v2/services/API/cierre_caja.dart';
import 'package:zapatito_v2/services/API/tienda.dart';

class CierreCajaPage extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  const CierreCajaPage({
    super.key,
    this.firstName,
    this.emailUser,
    this.inventarioId,
  });

  @override
  State<CierreCajaPage> createState() => _CierreCajaPageState();
}

class _CierreCajaPageState extends State<CierreCajaPage> {
  String _filtroSeleccionado = 'Hoy';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _actualizarFechasPorFiltro('Hoy');
  }

  void _actualizarFechasPorFiltro(String filtro) {
    setState(() {
      _filtroSeleccionado = filtro;
      final ahora = DateTime.now();

      switch (filtro) {
        case 'Hoy':
          _fechaInicio = DateTime(ahora.year, ahora.month, ahora.day, 0, 0, 0);
          _fechaFin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
          break;
        case 'Ayer':
          final ayer = ahora.subtract(const Duration(days: 1));
          _fechaInicio = DateTime(ayer.year, ayer.month, ayer.day, 0, 0, 0);
          _fechaFin = DateTime(ayer.year, ayer.month, ayer.day, 23, 59, 59);
          break;
        case 'Últimos 7 días':
          _fechaInicio = ahora.subtract(const Duration(days: 6));
          _fechaInicio = DateTime(_fechaInicio!.year, _fechaInicio!.month,
              _fechaInicio!.day, 0, 0, 0);
          _fechaFin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
          break;
        case 'Este Mes':
          _fechaInicio = DateTime(ahora.year, ahora.month, 1, 0, 0, 0);
          _fechaFin = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);
          break;
        case 'Personalizado':
          _fechaInicio ??=
              DateTime(ahora.year, ahora.month, ahora.day, 0, 0, 0);
          _fechaFin ??=
              DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
          break;
      }
    });
  }

  Future<void> _seleccionarRangoPersonalizado() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: (_fechaInicio != null && _fechaFin != null)
          ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _filtroSeleccionado = 'Personalizado';
        _fechaInicio = DateTime(
            picked.start.year, picked.start.month, picked.start.day, 0, 0, 0);
        _fechaFin = DateTime(
            picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
    }
  }

  Widget _buildFab(
      Gradient gradient, String tag, VoidCallback onPressed, String label) {
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
          icon: const Icon(Icons.point_of_sale, color: Colors.white),
          label: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Future<void> _visualizarDetalleCierre(dynamic idCierre) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SplashScreen02(),
    );

    try {
      final resultado = await CierreCajaService.obtenerCierrePorId(idCierre);
/*
      const encoder = JsonEncoder.withIndent('  ');
      final prettyPrint = encoder.convert(resultado);

// debugPrint fracciona los strings largos para que la consola no los trunque
      debugPrint('=== RESPUESTA COMPLETA DE CIERRE DE CAJA ===');
      debugPrint(prettyPrint);
*/
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (resultado != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CierreCajaForm(datosRespuesta: resultado),
          ),
        ).then((_) => setState(() {}));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Error al cargar el detalle del cierre de caja'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red al visualizar el cierre: $e')),
      );
    }
  }

  Future<void> _ejecutarCierrePersonal() async {
    if (widget.inventarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No hay un inventario asociado para buscar usuarios')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SplashScreen02(),
    );

    try {
      final usuariosInventario =
          await CierreCajaService.obtenerCorreosPorInventario(
              widget.inventarioId!);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (usuariosInventario.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se encontraron usuarios asociados a este inventario')),
        );
        return;
      }

      String emailSeleccionado =
          usuariosInventario.first['email']?.toString() ?? '';
      DateTime fechaSeleccionada = DateTime.now();

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Configurar Cierre Personal'),
            content: StatefulBuilder(
              builder: (context, setStateModal) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Usuario / Correo',
                        border: OutlineInputBorder(),
                      ),
                      value: emailSeleccionado,
                      items: usuariosInventario.map((u) {
                        final email = u['email']?.toString() ?? '';
                        return DropdownMenuItem<String>(
                          value: email,
                          child: Text(email),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setStateModal(() {
                            emailSeleccionado = v;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: fechaSeleccionada,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                          helpText: 'SELECCIONE LA FECHA DE CIERRE',
                        );
                        if (picked != null) {
                          setStateModal(() {
                            fechaSeleccionada = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Cierre',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(fechaSeleccionada
                                .toIso8601String()
                                .split('T')[0]),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const SplashScreen02(),
                  );

                  final fechaFormateada =
                      fechaSeleccionada.toIso8601String().split('T')[0];

                  final resultado = await CierreCajaService.cerrarPorCorreo(
                    fecha: fechaFormateada,
                    emailUser: emailSeleccionado,
                    usuario: widget.firstName ?? 'Administrador',
                    idInventario: widget.inventarioId ?? '',
                  );

                  if (!mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();

                  if (resultado != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CierreCajaForm(datosRespuesta: resultado),
                      ),
                    ).then((_) => setState(() {}));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('Error al procesar el cierre personal'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                },
                child: const Text('Procesar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos del inventario: $e')),
      );
    }
  }

  Future<void> _ejecutarCierreTiendaModal() async {
    if (widget.inventarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay un inventario asociado para buscar tiendas')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SplashScreen02(),
    );

    try {
      final tiendas =
          await TiendaService.obtenerPorInventario(widget.inventarioId!);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (tiendas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se encontraron tiendas asociadas a este inventario')),
        );
        return;
      }

      dynamic tiendaSeleccionadaId = tiendas.first['id_tienda'];
      DateTime fechaSeleccionada = DateTime.now();

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Configurar Cierre de Tienda'),
            content: StatefulBuilder(
              builder: (context, setStateModal) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<dynamic>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tienda',
                        border: OutlineInputBorder(),
                      ),
                      value: tiendaSeleccionadaId,
                      items: tiendas.map((t) {
                        return DropdownMenuItem<dynamic>(
                          value: t['id_tienda'],
                          child: Text(t['nombre']?.toString() ?? 'Sin nombre'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        setStateModal(() {
                          tiendaSeleccionadaId = v;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: fechaSeleccionada,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setStateModal(() {
                            fechaSeleccionada = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Cierre',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(fechaSeleccionada
                                .toIso8601String()
                                .split('T')[0]),
                            const Icon(Icons.calendar_today, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const SplashScreen02(),
                  );

                  final fechaFormateada =
                      fechaSeleccionada.toIso8601String().split('T')[0];
                  final resultado = await CierreCajaService.cerrarPorTienda(
                    fecha: fechaFormateada,
                    idTienda: tiendaSeleccionadaId,
                    usuario: widget.firstName ?? 'Administrador',
                    idInventario: widget.inventarioId ?? '',
                  );

                  if (!mounted) return;
                  Navigator.of(context, rootNavigator: true).pop();

                  if (resultado != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CierreCajaForm(datosRespuesta: resultado),
                      ),
                    ).then((_) => setState(() {}));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            const Text('Error al procesar el cierre de tienda'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                },
                child: const Text('Procesar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar tiendas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets().appBarMain('Cierre de Caja'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...['Hoy', 'Ayer', 'Últimos 7 días', 'Este Mes']
                      .map((filtro) {
                    final seleccionado = _filtroSeleccionado == filtro;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filtro),
                        selected: seleccionado,
                        onSelected: (selected) {
                          if (selected) _actualizarFechasPorFiltro(filtro);
                        },
                      ),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.date_range, size: 16),
                    label: Text(_filtroSeleccionado == 'Personalizado'
                        ? 'Personalizado'
                        : 'Rango...'),
                    onPressed: () async {
                      await _seleccionarRangoPersonalizado();
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: CierreCajaService.obtenerHistorialCierres(
                  widget.inventarioId ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error al cargar los registros'));
                }

                final listaTotal = snapshot.data ?? [];

                final lista = listaTotal.where((data) {
                  final String? fechaStr = data['fecha_creacion']?.toString();
                  if (fechaStr == null) return false;

                  final String fechaItemStr = fechaStr.length >= 10
                      ? fechaStr.substring(0, 10)
                      : fechaStr;

                  if (_fechaInicio == null || _fechaFin == null) return true;

                  final String inicioStr =
                      _fechaInicio!.toIso8601String().substring(0, 10);
                  final String finStr =
                      _fechaFin!.toIso8601String().substring(0, 10);

                  return fechaItemStr.compareTo(inicioStr) >= 0 &&
                      fechaItemStr.compareTo(finStr) <= 0;
                }).toList();

                if (lista.isEmpty) {
                  return const Center(
                      child: Text(
                          'No hay registros de cierre para este periodo.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final data = lista[index];

                    final String idCierre =
                        data['id_cierre_caja']?.toString() ?? '';
                    final String nombreCierre = data['nombre'] ?? 'Sin Nombre';
                    final String usuario =
                        data['usuario_creacion'] ?? 'Desconocido';
                    final dynamic totalVentas =
                        data['total_calzados_vendidos'] ?? 0;
                    final double controlCaja = double.tryParse(
                            data['control_caja']?.toString() ?? '0') ??
                        0.0;

                    final String fechaCierre =
                        data['fecha_cierre']?.toString().split('T')[0] ?? '';
                    final String fechaCreacion =
                        data['fecha_creacion']?.toString().split('T')[0] ?? '';

                    final Color colorControlCaja = controlCaja > 0
                        ? Colors.green.shade700
                        : Colors.red.shade700;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    nombreCierre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_task,
                                          size: 12,
                                          color: Colors.blue.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Creado: $fechaCreacion',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 12,
                                          color: Colors.grey.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Cierre: $fechaCierre',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.person_outline_rounded,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    usuario,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.shopping_bag_outlined,
                                    size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 6),
                                Text(
                                  'Cantidad total: $totalVentas pares',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20, thickness: 1),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: colorControlCaja.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: colorControlCaja.withOpacity(0.3),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        controlCaja > 0
                                            ? Icons.trending_up_rounded
                                            : Icons.trending_down_rounded,
                                        color: colorControlCaja,
                                        size: 26,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Control de Caja',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'S/ ${controlCaja.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: colorControlCaja,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0EA5E9),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () =>
                                    _visualizarDetalleCierre(idCierre),
                                icon: const Icon(Icons.visibility_rounded,
                                    size: 18),
                                label: const Text(
                                  'VISUALIZAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 12),
          _buildFab(
            Designwidgets().linearGradientPurple(context),
            "btn_cierre_tienda",
            _ejecutarCierreTiendaModal,
            "Cierre Tienda",
          ),
          const SizedBox(height: 12),
          _buildFab(
            Designwidgets().linearGradientFire(context),
            "btn_cierre_personal",
            _ejecutarCierrePersonal,
            "Cierre Personal",
          ),
        ],
      ),
    );
  }
}

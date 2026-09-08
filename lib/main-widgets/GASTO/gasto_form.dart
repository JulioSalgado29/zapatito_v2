import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/gasto.dart';
import 'package:zapatito_v2/services/API/tienda.dart'; // 🔹 Import de TiendaService

class GastoForm extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;
  final String? tiendaId; // Se usa como valor inicial o respaldo

  // Parámetros para edición
  final String? gastoId;
  final double? montoInicial;
  final String? descripcionInicial;

  const GastoForm({
    super.key,
    this.firstName,
    this.emailUser,
    this.inventarioId,
    this.tiendaId,
    this.gastoId,
    this.montoInicial,
    this.descripcionInicial,
  });

  @override
  State<GastoForm> createState() => _GastoFormState();
}

class _GastoFormState extends State<GastoForm> {
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  
  String? _tiendaSeleccionadaId; // 🔹 Estado local para la tienda elegida
  bool _estaEditando = false;
  Future<List<Map<String, dynamic>>>? _futureTiendas;

  @override
  void initState() {
    super.initState();
    _tiendaSeleccionadaId = widget.tiendaId;

    if (widget.inventarioId != null && widget.inventarioId!.isNotEmpty) {
      _futureTiendas = TiendaService.obtenerPorInventario(widget.inventarioId!);
    }

    if (widget.gastoId != null) {
      _estaEditando = true;
      if (widget.montoInicial != null) {
        _montoController.text = widget.montoInicial.toString();
      }
      _descripcionController.text = widget.descripcionInicial ?? '';
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  // 🔹 Validación: Monto > 0, Descripción no vacía Y Tienda seleccionada
  bool get _puedeGuardar {
    final textoMonto = _montoController.text.trim().replaceAll(',', '.');
    final textoDescripcion = _descripcionController.text.trim();

    if (textoMonto.isEmpty || textoDescripcion.isEmpty) return false;
    if (_tiendaSeleccionadaId == null || _tiendaSeleccionadaId!.isEmpty) return false;

    final valorMonto = double.tryParse(textoMonto);
    return valorMonto != null && valorMonto > 0;
  }

  void _mostrarSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guardarGasto() async {
    if (!_puedeGuardar) {
      _mostrarSnack('Por favor, complete todos los campos obligatorios correctamente.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SplashScreen02(),
    );

    try {
      final String textoNormalizado =
          _montoController.text.trim().replaceAll(',', '.');
      final double monto = double.parse(textoNormalizado);
      final String descripcion = _descripcionController.text.trim();
      final String emailUsuario = widget.emailUser ?? '';
      final String usuarioCreacion = widget.firstName ?? 'anon';
      final dynamic idInventario = widget.inventarioId ?? '';
      final dynamic idTienda = _tiendaSeleccionadaId; // 👈 Tienda seleccionada

      bool exito = false;

      if (_estaEditando) {
        exito = await GastoService.actualizar(
          id: widget.gastoId!,
          emailUsuario: emailUsuario,
          idTienda: idTienda,
          monto: monto,
          descripcion: descripcion,
          usuarioCreacion: usuarioCreacion,
        );
      } else {
        exito = await GastoService.crear(
          emailUsuario: emailUsuario,
          idInventario: idInventario,
          idTienda: idTienda,
          monto: monto,
          descripcion: descripcion,
          usuarioCreacion: usuarioCreacion,
        );
      }

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Cierra SplashScreen
      }

      if (exito) {
        _mostrarSnack(_estaEditando
            ? 'Gasto actualizado correctamente'
            : 'Gasto registrado correctamente');
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _mostrarSnack('No se pudo guardar la información en el servidor.');
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _mostrarSnack('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Designwidgets()
          .appBarMain(_estaEditando ? 'Editar Gasto' : 'Nuevo Gasto'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del Gasto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 🔹 Selector Desplegable de Tienda
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _futureTiendas,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(),
                  );
                }

                final tiendas = snapshot.data ?? [];

                // Verifica si la tienda seleccionada se encuentra dentro del listado obtenido
                final existeSeleccion = tiendas.any(
                  (t) => t['id_tienda']?.toString() == _tiendaSeleccionadaId,
                );

                return DropdownButtonFormField<String>(
                  value: existeSeleccion ? _tiendaSeleccionadaId : null,
                  decoration: const InputDecoration(
                    labelText: 'Tienda *',
                    hintText: 'Seleccione una tienda',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.store),
                  ),
                  items: tiendas.map((tienda) {
                    final String id = tienda['id_tienda']?.toString() ?? '';
                    final String nombre = tienda['nombre'] ?? 'Sin nombre';
                    return DropdownMenuItem<String>(
                      value: id,
                      child: Text(nombre),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _tiendaSeleccionadaId = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Campo de Monto
            TextFormField(
              controller: _montoController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Monto *',
                hintText: '0.00',
                border: const OutlineInputBorder(),
                prefixIcon: Container(
                  width: 45,
                  alignment: Alignment.center,
                  child: const Text(
                    'S/',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Campo de Descripción
            TextFormField(
              controller: _descripcionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción *',
                hintText: 'Ej: Transporte, suministros, servicios, etc.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _puedeGuardar ? _guardarGasto : null,
                icon: Icon(_estaEditando ? Icons.save_as : Icons.save),
                label: Text(
                  _estaEditando ? 'Actualizar Gasto' : 'Guardar Gasto',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
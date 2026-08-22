import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/dueno_muestra.dart';

class DuenoMuestraForm extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  // 🔹 Parámetros para edición
  final String? duenoId;
  final String? nombreInicial;

  const DuenoMuestraForm({
    super.key,
    this.firstName,
    this.emailUser,
    this.inventarioId,
    this.duenoId,
    this.nombreInicial,
  });

  @override
  State<DuenoMuestraForm> createState() => _DuenoMuestraFormState();
}

class _DuenoMuestraFormState extends State<DuenoMuestraForm> {
  final TextEditingController _nombreController = TextEditingController();
  bool _estaEditando = false;

  @override
  void initState() {
    super.initState();
    // 🔹 Si recibimos un ID, significa que estamos editando
    if (widget.duenoId != null) {
      _estaEditando = true;
      _nombreController.text = widget.nombreInicial ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  // 🔹 Validación: El nombre no puede estar vacío
  bool get _puedeGuardar => _nombreController.text.trim().isNotEmpty;

  void _mostrarSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guardarDueno() async {
    if (!_puedeGuardar) {
      _mostrarSnack('Por favor, ingrese un nombre.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SplashScreen02(),
    );

    try {
      final String nombre = _nombreController.text.trim();
      final String emailUsuario = widget.emailUser ?? '';
      final String usuarioCreacion = widget.firstName ?? 'anon';
      final dynamic idInventario = widget.inventarioId ?? '';

      bool exito = false;

      if (_estaEditando) {
        // 🔹 UPDATE: Actualiza el registro existente por ID
        exito = await DuenoMuestraService.actualizar(
          id: widget.duenoId!,
          emailUsuario: emailUsuario,
          nombre: nombre,
          usuarioCreacion: usuarioCreacion,
        );
      } else {
        // 🔹 INSERT: Crea un nuevo registro
        exito = await DuenoMuestraService.crear(
          emailUsuario: emailUsuario,
          idInventario: idInventario,
          nombre: nombre,
          usuarioCreacion: usuarioCreacion,
        );
      }

      // Cierra el indicador de carga (SplashScreen02)
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (exito) {
        _mostrarSnack(_estaEditando
            ? 'Actualizado correctamente'
            : 'Registrado correctamente');
        if (mounted) {
          Navigator.pop(
              context, true); // Regresa a la vista anterior indicando éxito
        }
      } else {
        _mostrarSnack('No se pudo guardarla información en el servidor.');
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
          .appBarMain(_estaEditando ? 'Editar Dueño' : 'Nuevo Dueño'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos del Propietario',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombreController,
              textCapitalization:
                  TextCapitalization.words, // 🔹 Primera letra en mayúscula
              decoration: const InputDecoration(
                labelText: 'Nombre Completo',
                hintText: 'Ej: Juan Pérez',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_add_alt_1),
              ),
              onChanged: (v) =>
                  setState(() {}), // Refresca el botón al escribir
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardarDueno,
                icon: Icon(_estaEditando ? Icons.save_as : Icons.save),
                label:
                    Text(_estaEditando ? 'Actualizar Dueño' : 'Guardar Dueño'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

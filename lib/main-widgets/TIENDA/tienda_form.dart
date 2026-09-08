import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/tienda.dart';

class TiendaForm extends StatefulWidget {
  final String? firstName;
  final String? emailUser;
  final String? inventarioId;

  final String? tiendaId;
  final String? nombreInicial;

  const TiendaForm({
    super.key,
    this.firstName,
    this.emailUser,
    this.inventarioId,
    this.tiendaId,
    this.nombreInicial,
  });

  @override
  State<TiendaForm> createState() => _TiendaFormState();
}

class _TiendaFormState extends State<TiendaForm> {
  final TextEditingController _nombreController = TextEditingController();
  bool _estaEditando = false;

  @override
  void initState() {
    super.initState();
    if (widget.tiendaId != null) {
      _estaEditando = true;
      _nombreController.text = widget.nombreInicial ?? '';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  bool get _puedeGuardar => _nombreController.text.trim().isNotEmpty;

  void _mostrarSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _guardarTienda() async {
    if (!_puedeGuardar) {
      _mostrarSnack('Por favor, ingrese un nombre para la tienda.');
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
        exito = await TiendaService.actualizar(
          id: widget.tiendaId!,
          emailUsuario: emailUsuario,
          nombre: nombre,
          usuarioCreacion: usuarioCreacion,
        );
      } else {
        exito = await TiendaService.crear(
          emailUsuario: emailUsuario,
          idInventario: idInventario,
          nombre: nombre,
          usuarioCreacion: usuarioCreacion,
        );
      }

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (exito) {
        _mostrarSnack(_estaEditando
            ? 'Actualizado correctamente'
            : 'Registrado correctamente');
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
          .appBarMain(_estaEditando ? 'Editar Tienda' : 'Nueva Tienda'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos de la Tienda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre de la Tienda',
                hintText: 'Ej: Tienda Central',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.storefront),
              ),
              onChanged: (v) => setState(() {}),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardarTienda,
                icon: Icon(_estaEditando ? Icons.save_as : Icons.save),
                label: Text(_estaEditando ? 'Actualizar Tienda' : 'Guardar Tienda'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
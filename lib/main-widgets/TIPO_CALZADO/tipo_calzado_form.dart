import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/services/API/tipo_calzado.dart';

class TipoCalzadoForm extends StatefulWidget {
  final String? firstName;
  final Map<String, dynamic>? itemData;
  final String? inventarioId;
  final String? emailUser;

  const TipoCalzadoForm({
    super.key,
    this.firstName,
    this.itemData,
    this.inventarioId,
    this.emailUser,
  });

  @override
  State<TipoCalzadoForm> createState() => _TipoCalzadoFormState();
}

class _TipoCalzadoFormState extends State<TipoCalzadoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  String? _iconoSeleccionado;
  bool _taco = false;
  bool _plataforma = false;
  bool _colores = false;

  bool get isEditing => widget.itemData != null;

  List<String> _iconos = [];
  bool _loadingIconos = true;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final data = widget.itemData!;
      _nombreController.text = data['nombre'] ?? '';
      _iconoSeleccionado = data['icono']; // ruta guardada
      _taco = data['taco'] ?? false;
      _plataforma = data['plataforma'] ?? false;
      _colores = data['colores'] ?? false;
    }
    _cargarIconos();
  }

  Future<void> _cargarIconos() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final iconos = manifestMap.keys
        .where((key) =>
            key.startsWith('lib/assets/calzados/') &&
            (key.endsWith('.png') || key.endsWith('.jpg')))
        .toList();

    setState(() {
      _iconos = iconos;
      _loadingIconos = false;
    });
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

  Future<void> _guardarTipoCalzado() async {
  if (!_formKey.currentState!.validate()) return;

  _mostrarSplashScreen();

  try {
    final String nombre = _nombreController.text.trim();
    final String? icono = _iconoSeleccionado;
    final String usuarioCreacion = widget.firstName ?? '';
    final String emailUsuario = widget.emailUser ?? '';
    final String idInventario = widget.inventarioId ?? '';

    bool exito = false;

    if (isEditing) {
      // Extrae el ID del itemData recibido
      final String id = widget.itemData?['id_tipo_calzado']?.toString() ?? '';

      exito = await TipoCalzadoService.actualizar(
        id: id,
        nombre: nombre,
        icono: icono,
        usuarioCreacion: usuarioCreacion,
        emailUsuario: emailUsuario,
        taco: _taco,
        plataforma: _plataforma,
        colores: _colores,
      );
    } else {
      exito = await TipoCalzadoService.crear(
        nombre: nombre,
        icono: icono,
        usuarioCreacion: usuarioCreacion,
        emailUsuario: emailUsuario,
        taco: _taco,
        plataforma: _plataforma,
        colores: _colores,
        idInventario: idInventario,
      );
    }

    _ocultarSplashScreen();

    await Future.delayed(const Duration(milliseconds: 150));

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Tipo de calzado actualizado ✏️'
                : 'Tipo de calzado agregado ✅',
          ),
        ),
      );
      // Retorna `true` a la pantalla principal para refrescar la grilla
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar la información.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    _ocultarSplashScreen();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20)
          .copyWith(top: 24, bottom: 40),
      child: SizedBox(
        height: MediaQuery.of(context).size.height *
            0.75, // Limita la altura del formulario al 75% de la pantalla
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  isEditing
                      ? "Editar Tipo de Calzado"
                      : "Agregar Tipo de Calzado",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                IgnorePointer(
                  ignoring: isEditing,
                  child: TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor:
                          isEditing ? Colors.grey.shade200 : Colors.white,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese un nombre' : null,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Seleccionar ícono:",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_loadingIconos)
                  const Center(child: CircularProgressIndicator())
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _iconos.map((path) {
                      final isSelected = _iconoSeleccionado == path;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _iconoSeleccionado = path);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: Colors.blue.withOpacity(0.2),
                                        blurRadius: 5)
                                  ]
                                : null,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            path,
                            width: 48,
                            height: 48,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('¿Puede tener diferentes tacos?'),
                  value: _taco,
                  onChanged: (value) {
                    setState(() {
                      _taco = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('¿Puede tener diferentes plataformas?'),
                  value: _plataforma,
                  onChanged: (value) {
                    setState(() {
                      _plataforma = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('¿Puede tener diferentes colores?'),
                  value: _colores,
                  onChanged: (value) {
                    setState(() {
                      _colores = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _iconoSeleccionado == null ? null : _guardarTipoCalzado,
                    icon: Icon(isEditing ? Icons.save_as : Icons.save),
                    label: Text(isEditing
                        ? 'Actualizar Tipo de Calzado'
                        : 'Guardar Tipo de Calzado'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

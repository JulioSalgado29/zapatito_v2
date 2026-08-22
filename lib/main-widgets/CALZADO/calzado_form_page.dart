import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/calzado.dart';
import 'package:zapatito_v2/services/API/tipo_calzado.dart';

class CalzadoFormPage extends StatefulWidget {
  final String? firstName;
  final Map<String, dynamic>? calzado;
  final String? emailUser;
  final String? inventarioId;
  final bool? isAlmacenero;

  const CalzadoFormPage({
    super.key,
    this.firstName,
    this.calzado,
    this.emailUser,
    this.inventarioId,
    this.isAlmacenero,
  });

  @override
  State<CalzadoFormPage> createState() => _CalzadoFormPageState();
}

class _CalzadoFormPageState extends State<CalzadoFormPage> {
  bool _primerCargaCompletada = false;
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  String? _selectedTipoCalzadoId;

  bool _taco = false;
  bool _plataforma = false;
  bool _colores = false;
  bool _tacoCheckbox = false;
  bool _plataformaCheckbox = false;
  bool _coloresCheckbox = false;
  String? _iconoSeleccionado;

  bool get isEditing => widget.calzado != null;
  bool _intentoGuardar = false;
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final data = widget.calzado!; _nombreController.text = data['nombre'] ?? '';
      final double precio = double.tryParse(data['precio_real']?.toString() ?? '0') ?? 0.0;
      _precioController.text = precio.toStringAsFixed(2);
      _selectedTipoCalzadoId = (data['id_tipo_calzado'] ?? data['tipo_calzado_id'])?.toString();
      _tacoCheckbox = data['taco'] ?? false;
      _plataformaCheckbox = data['plataforma'] ?? false;
      _coloresCheckbox = data['colores'] ?? false;
      _iconoSeleccionado = data['icono'] ?? '';
    }

    _nombreController.addListener(_validarFormulario);
    _precioController.addListener(_validarFormulario);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _validarFormulario();
      if (isEditing && _selectedTipoCalzadoId != null) {
        final tipoMap =
            await TipoCalzadoService.obtenerPorId(_selectedTipoCalzadoId!);

        if (tipoMap != null) {
          final data = tipoMap;
          setState(() {
            _taco = data['taco'] ?? false;
            _plataforma = data['plataforma'] ?? false;
            _colores = data['colores'] ?? false;
          });
        }
      }
    });
  }

  void _validarFormulario() {
    final nombre = _nombreController.text.trim();
    final precio = _precioController.text.trim();

    final valido = nombre.isNotEmpty &&
        (widget.isAlmacenero == true || precio.isNotEmpty) &&
        _selectedTipoCalzadoId != null &&
        _formKey.currentState?.validate() != false;

    setState(() {
      _isFormValid = valido;
    });
  }

  String? validarPrecio(String? valor) {
    if (widget.isAlmacenero == true) return null;
    if (valor == null || valor.isEmpty) return 'Ingrese un precio';
    final precioText = valor.replaceAll("S/", "").trim();
    final precio = double.tryParse(precioText);
    if (precio == null) return 'Ingrese solo números válidos';
    if (precio > 150) return 'No puede superar el precio de S/ 150';
    return null;
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

  Future<void> _guardarCalzado() async {
    setState(() => _intentoGuardar = true);

    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    _mostrarSplashScreen();

    final tipoMap =
        await TipoCalzadoService.obtenerPorId(_selectedTipoCalzadoId!);

    final tipoData = tipoMap ?? {};
    final icono = tipoData['icono'] ?? _iconoSeleccionado ?? '';

    double precio = 0.0;
    if (widget.isAlmacenero == true) {
      precio = isEditing ? (widget.calzado!['precio_real'] ?? 0.0) : 0.0;
    } else {
      final precioText = _precioController.text.replaceAll("S/", "").trim();
      precio = double.tryParse(precioText) ?? 0.0;
    }

    final double precioReal = double.parse(precio.toStringAsFixed(2));
    final String nombre = _nombreController.text.trim();

    try {
      final bool exito = isEditing
          ? await CalzadoService.actualizar(
              id: (widget.calzado!['id_calzado'] ?? widget.calzado!['id'])
                  .toString(),
              nombre: nombre,
              icono: icono,
              precioReal: precioReal,
              taco: _tacoCheckbox,
              plataforma: _plataformaCheckbox,
              colores: _coloresCheckbox,
              idTipoCalzado: _selectedTipoCalzadoId,
              usuarioCreacion: widget.firstName,
              emailUsuario: widget.emailUser,
            )
          : await CalzadoService.crear(
              nombre: nombre,
              icono: icono,
              precioReal: precioReal,
              taco: _tacoCheckbox,
              plataforma: _plataformaCheckbox,
              colores: _coloresCheckbox,
              idTipoCalzado: _selectedTipoCalzadoId,
              usuarioCreacion: widget.firstName,
              emailUsuario: widget.emailUser,
              idInventario: widget.inventarioId,
            );

      _ocultarSplashScreen();

      if (exito) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Código actualizado correctamente ✏️'
                    : 'Código agregado correctamente ✅',
              ),
            ),
          );
        }

        await Future.delayed(const Duration(milliseconds: 150));

        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? 'Error al actualizar el código ❌'
                    : 'Error al agregar el código ❌',
              ),
            ),
          );
        }
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
    return Scaffold(
      appBar: Designwidgets().appBarMain(
        isEditing ? "Editar Código" : "Agregar Código",
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20)
            .copyWith(top: 24, bottom: 40),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            onChanged: _validarFormulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // 🔸 Tipo de calzado
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: !isEditing
                      ? TipoCalzadoService.obtenerPorInventario(
                          widget.inventarioId.toString(),
                        )
                      : TipoCalzadoService.obtenerTodosPorInventario(
                          widget.inventarioId.toString(),
                        ),
                  builder: (context, snapshot) {
                    if (!_primerCargaCompletada &&
                        snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasData) _primerCargaCompletada = true;

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      final mostrarAdvertencia = _intentoGuardar;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No hay tipos de calzado disponibles.',
                              style: TextStyle(
                                color: mostrarAdvertencia
                                    ? Colors.red
                                    : Colors.black87,
                                fontSize: 16,
                                fontWeight: mostrarAdvertencia
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Text(
                                '(Debe agregar uno primero)',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final tipos = snapshot.data!;
                    // 💡 1. Convertir el ID seleccionado a String para evitar errores int vs String
                    final idSeleccionadoStr =
                        _selectedTipoCalzadoId?.toString();

                    // 💡 2. Validar que el ID exista dentro de la lista traída de la API
                    final existeEnLista = tipos.any((data) =>
                        data['id_tipo_calzado']?.toString() ==
                        idSeleccionadoStr);

                    return IgnorePointer(
                        ignoring: isEditing,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Tipo de Calzado',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor:
                                isEditing ? Colors.grey.shade200 : Colors.white,
                          ),
                          value: existeEnLista ? idSeleccionadoStr : null,
                          items: tipos.map((data) {
                            final idTipo =
                                data['id_tipo_calzado']?.toString() ?? '';
                            final icono = data['icono'] ?? '';
                            final nombre = data['nombre'] ?? '';
                            return DropdownMenuItem<String>(
                              value: idTipo,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (icono.toString().endsWith('.png') ||
                                      icono.toString().endsWith('.jpg'))
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Image.asset(
                                        icono,
                                        width: 28,
                                        height: 28,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.image, size: 24),
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        icono.toString(),
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  Text(
                                    nombre,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) async {
                            setState(() => _selectedTipoCalzadoId = val);
                            if (val != null) {
                              final tipoData =
                                  await TipoCalzadoService.obtenerPorId(val);
                              if (tipoData != null) {
                                setState(() {
                                  _iconoSeleccionado = tipoData['icono'] ?? '';
                                  _taco = tipoData['taco'] ?? false;
                                  _plataforma = tipoData['plataforma'] ?? false;
                                  _colores = tipoData['colores'] ?? false;

                                  if (!_taco) _tacoCheckbox = false;
                                  if (!_plataforma) _plataformaCheckbox = false;
                                  if (!_colores) _coloresCheckbox = false;
                                });
                              }
                            }
                            _validarFormulario();
                          },
                          validator: (v) => v == null
                              ? 'Seleccione un tipo de calzado'
                              : null,
                        ));
                  },
                ),

                const SizedBox(height: 16),

                // Nombre
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

                // Precio
                if (widget.isAlmacenero != true)
                  TextFormField(
                    controller: _precioController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}$')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Precio proveedor',
                      prefixText: 'S/ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: validarPrecio,
                  ),
                if (widget.isAlmacenero != true) const SizedBox(height: 16),

                // Taco / Plataforma / Colores
                if (_selectedTipoCalzadoId != null &&
                    (_taco || _plataforma || _colores))
                  Column(
                    children: [
                      if (_taco)
                        Row(
                          children: [
                            const Text('¿Tiene Taco?',
                                style: TextStyle(fontSize: 16)),
                            Checkbox(
                              value: _tacoCheckbox,
                              onChanged: (val) =>
                                  setState(() => _tacoCheckbox = val ?? false),
                            ),
                          ],
                        ),
                      if (_plataforma)
                        Row(
                          children: [
                            const Text('¿Tiene Plataforma?',
                                style: TextStyle(fontSize: 16)),
                            Checkbox(
                              value: _plataformaCheckbox,
                              onChanged: (val) => setState(
                                  () => _plataformaCheckbox = val ?? false),
                            ),
                          ],
                        ),
                      if (_colores)
                        Row(
                          children: [
                            const Text('¿Tiene Colores?',
                                style: TextStyle(fontSize: 16)),
                            Checkbox(
                              value: _coloresCheckbox,
                              onChanged: (val) => setState(
                                  () => _coloresCheckbox = val ?? false),
                            ),
                          ],
                        ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Botón Guardar / Actualizar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isFormValid ? _guardarCalzado : null,
                    icon: Icon(isEditing ? Icons.save_as : Icons.save),
                    label: Text(
                        isEditing ? 'Actualizar Código' : 'Guardar Código'),
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

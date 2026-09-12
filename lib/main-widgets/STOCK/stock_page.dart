import 'package:flutter/material.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/stock.dart';

class StockPage extends StatefulWidget {
  final String? inventarioId;

  const StockPage({
    super.key,
    required this.inventarioId,
  });

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tallaController = TextEditingController();
  final TextEditingController _tacoController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _plataformaController = TextEditingController();

  final List<int> _listaTallasDisponibles = List.generate(22, (i) => i + 22);
  final List<int> _listaTacosDisponibles = List.generate(15, (i) => i + 1);
  final List<String> _listaPlataformasDisponibles = ['Bajo', 'Mediano', 'Alto'];

  bool _cargando = false;

  List<Map<String, dynamic>> _cabecera = [];
  List<Map<String, dynamic>> _detalle = [];

  String _searchQuery = '';
  String _filtroTalla = '';
  String _filtroTaco = '';
  String _filtroColor = '';
  String _filtroPlataforma = '';

  @override
  void initState() {
    super.initState();
    _escucharControladores();
    _ejecutarBusqueda();
  }

  void _escucharControladores() {
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _tallaController.addListener(() {
      setState(() => _filtroTalla = _tallaController.text);
      _ejecutarBusqueda();
    });
    _tacoController.addListener(() {
      setState(() => _filtroTaco = _tacoController.text);
      _ejecutarBusqueda();
    });
    _colorController.addListener(() {
      setState(() => _filtroColor = _colorController.text);
      _ejecutarBusqueda();
    });
    _plataformaController.addListener(() {
      setState(() => _filtroPlataforma = _plataformaController.text);
      _ejecutarBusqueda();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tallaController.dispose();
    _tacoController.dispose();
    _colorController.dispose();
    _plataformaController.dispose();
    super.dispose();
  }

  Future<void> _ejecutarBusqueda() async {
    if (widget.inventarioId == null) return;

    setState(() => _cargando = true);

    try {
      final List<int> tallas = _tallaController.text.isNotEmpty
          ? _tallaController.text
              .split(',')
              .map((e) => int.tryParse(e.trim()) ?? 0)
              .where((e) => e > 0)
              .toList()
          : [];

      final List<int> tacos = _tacoController.text.isNotEmpty
          ? _tacoController.text
              .split(',')
              .map((e) => int.tryParse(e.trim()) ?? 0)
              .where((e) => e > 0)
              .toList()
          : [];

      final List<int> colores = _colorController.text.isNotEmpty
          ? _colorController.text
              .split(',')
              .map((e) => int.tryParse(e.trim()) ?? 0)
              .where((e) => e > 0)
              .toList()
          : [];

      final String plataforma = _plataformaController.text.trim().isEmpty
          ? '0'
          : _plataformaController.text.trim();

      final resultados = await StockService.filtrarInventario(
        idsCalzado: [],
        idsColor: colores,
        tallas: tallas,
        plataforma: plataforma,
        tacos: tacos,
        idInventario: int.parse(widget.inventarioId.toString()),
      );

      if (mounted) {
        setState(() {
          _cabecera = (resultados['cabecera'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];

          _detalle = (resultados['detalle'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
        });
      }
    } catch (e) {
      print('Error al procesar el filtro: $e');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _searchController.clear();
      _tallaController.clear();
      _tacoController.clear();
      _colorController.clear();
      _plataformaController.clear();
      _searchQuery = '';
      _filtroTalla = '';
      _filtroTaco = '';
      _filtroColor = '';
      _filtroPlataforma = '';
    });
    _ejecutarBusqueda();
  }

  bool _tieneFiltrosActivos() {
    return _filtroTalla.isNotEmpty ||
        _filtroTaco.isNotEmpty ||
        _filtroColor.isNotEmpty ||
        _filtroPlataforma.isNotEmpty;
  }

  void _mostrarSelectorOpciones({
    required String titulo,
    required TextEditingController controller,
    required List<String> opciones,
  }) {
    List<String> seleccionadosTemp = controller.text.isNotEmpty
        ? controller.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : [];

    String buscadorDialogo = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final opcionesFiltradas = opciones.where((opcion) {
              if (buscadorDialogo.isEmpty) return true;
              return opcion.toLowerCase().contains(buscadorDialogo.toLowerCase());
            }).toList();

            return AlertDialog(
              title: Text('Seleccionar $titulo', style: const TextStyle(fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar opción...',
                        prefixIcon: Icon(Icons.search, size: 16),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setStateDialog(() {
                          buscadorDialogo = val;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: opcionesFiltradas.length,
                        itemBuilder: (context, index) {
                          final opcion = opcionesFiltradas[index];
                          final isSelected = seleccionadosTemp.contains(opcion);

                          return CheckboxListTile(
                            title: Text(opcion),
                            value: isSelected,
                            dense: true,
                            onChanged: (bool? value) {
                              setStateDialog(() {
                                if (value == true) {
                                  seleccionadosTemp.add(opcion);
                                } else {
                                  seleccionadosTemp.remove(opcion);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Actualizamos el texto y forzamos el listener cerrando el diálogo
                    controller.text = seleccionadosTemp.join(', ');
                    Navigator.pop(context);
                  },
                  child: const Text('Aceptar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInputFiltroConPopup({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> opciones,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 16, color: Colors.blueAccent),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 16, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => controller.clear(),
              ),
            if (opciones.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.arrow_drop_down_circle_outlined, size: 18, color: Colors.blueAccent),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(),
                onPressed: () => _mostrarSelectorOpciones(
                  titulo: label,
                  controller: controller,
                  opciones: opciones,
                ),
              ),
          ],
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildIcon(String? icono) {
    if (icono == null || icono.isEmpty) {
      return const Icon(
        Icons.shopping_bag_outlined,
        size: 40,
        color: Colors.blueAccent,
      );
    }

    final lower = icono.toLowerCase();

    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return Image.network(
        icono,
        width: 40,
        height: 40,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, size: 40),
      );
    }

    return Image.asset(
      icono,
      width: 40,
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.image_not_supported, size: 40),
    );
  }

  Widget _buildInfoChip(String text, {bool isColor = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isColor ? Colors.indigo[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isColor ? Colors.indigo[100]! : Colors.grey[300]!,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isColor ? Colors.indigo[900] : Colors.black87,
          fontWeight: isColor ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.inventarioId == null) {
      return Scaffold(
        appBar: Designwidgets().appBarMain("Stock de Inventario"),
        body: const Center(
          child: Text(
            'No se proporcionó un ID de inventario válido.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final query = _searchQuery.trim().toLowerCase();
    final cabeceraFiltrada = _cabecera.where((item) {
      if (query.isEmpty) return true;
      final nombre =
          (item['nombre_calzado'] ?? item['nombre'] ?? '').toString().toLowerCase();
      return nombre.contains(query);
    }).toList();

    return Scaffold(
      appBar: Designwidgets().appBarMain("Stock de Inventario"),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // PANEL DE FILTROS GRANDES FIJOS ARRIBA
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar calzado...',
                            prefixIcon: const Icon(Icons.search, color: Colors.blueAccent, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey, size: 16),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputFiltroConPopup(
                          controller: _tallaController,
                          label: 'Tallas',
                          icon: Icons.straighten,
                          opciones: _listaTallasDisponibles.map((e) => e.toString()).toList(),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInputFiltroConPopup(
                          controller: _tacoController,
                          label: 'Tacos',
                          icon: Icons.height,
                          opciones: _listaTacosDisponibles.map((e) => e.toString()).toList(),
                          keyboardType: TextInputType.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputFiltroConPopup(
                          controller: _plataformaController,
                          label: 'Plataforma',
                          icon: Icons.layers,
                          opciones: _listaPlataformasDisponibles,
                          keyboardType: TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInputFiltroConPopup(
                          controller: _colorController,
                          label: 'ID Color',
                          icon: Icons.palette_outlined,
                          opciones: [],
                          keyboardType: TextInputType.text,
                        ),
                      ),
                    ],
                  ),
                  if (_tieneFiltrosActivos()) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _limpiarFiltros,
                        icon: const Icon(
                          Icons.cleaning_services_rounded,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          'Limpiar Filtros',
                          style: TextStyle(color: Colors.redAccent, fontSize: 12),
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),

            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(minHeight: 2),
              ),

            const SizedBox(height: 10),

            // LISTA DE RESULTADOS
            Expanded(
              child: cabeceraFiltrada.isEmpty
                  ? Center(
                      child: Text(
                        query.isEmpty && !_tieneFiltrosActivos()
                            ? 'No hay registros de stock disponibles.'
                            : 'No se encontraron coincidencias con los filtros aplicados.',
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _ejecutarBusqueda,
                      child: ListView.builder(
                        itemCount: cabeceraFiltrada.length,
                        itemBuilder: (context, index) {
                          final item = cabeceraFiltrada[index];
                          final idCalzadoStr = item['id_calzado']?.toString() ?? '';
                          final nombreCalzado = item['nombre_calzado'] == null || item['nombre_calzado'].toString().trim().isEmpty
                              ? (item['nombre'] ?? 'Sin nombre')
                              : item['nombre_calzado'];
                          final icono = item['icono'] as String?;
                          final cantidadTotal = item['total_stock'] ??
                              item['cantidad'] ??
                              '0';

                          final subdetalles = _detalle.where((d) {
                            return (d['id_calzado']?.toString() ?? '') ==
                                idCalzadoStr;
                          }).toList();

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 0),
                            elevation: 3,
                            child: ExpansionTile(
                              leading: _buildIcon(icono),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      nombreCalzado,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.blue[200]!),
                                    ),
                                    child: Text(
                                      'ID: $idCalzadoStr',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text('Cantidad total: $cantidadTotal'),
                              children: subdetalles.isEmpty
                                  ? const [
                                      Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Text(
                                          'Sin detalles de stock registrados.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ]
                                  : subdetalles.map((sub) {
                                      final cantSub = sub['stock_detalle'] ?? '0';
                                      final talla = sub['talla'] ?? 'N/A';
                                      final taco = sub['taco'];
                                      final plataforma = sub['plataforma'];
                                      final nombreColor = sub['nombre_color'] ??
                                          sub['color'];

                                      return ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.inventory_2_outlined,
                                            color: Color(0xFF4E4E4E),
                                          ),
                                        ),
                                        title: Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Row(
                                            children: [
                                              Text(
                                                'Talla: $talla',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                'Cant: $cantSub',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        subtitle: Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            if (taco != null)
                                              _buildInfoChip('Taco: $taco'),
                                            if (plataforma != null && plataforma != null &&
                                                plataforma.toString() != '0')
                                              _buildInfoChip(
                                                  'Plataforma: $plataforma'),
                                            if (nombreColor != null &&
                                                nombreColor
                                                    .toString()
                                                    .isNotEmpty)
                                              _buildInfoChip(
                                                'Color: $nombreColor',
                                                isColor: true,
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
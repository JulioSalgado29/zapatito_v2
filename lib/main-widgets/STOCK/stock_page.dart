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
  final TextEditingController _plataformaController =
      TextEditingController(text: '0');

  bool _mostrarFiltros = false;
  bool _cargando = false;

  List<Map<String, dynamic>> _cabecera = [];
  List<Map<String, dynamic>> _detalle = [];

  String _searchQuery = '';
  String _filtroTalla = '';
  String _filtroTaco = '';
  String _filtroColor = '';
  String _filtroPlataforma = '0';

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
    });
    _tacoController.addListener(() {
      setState(() => _filtroTaco = _tacoController.text);
    });
    _colorController.addListener(() {
      setState(() => _filtroColor = _colorController.text);
    });
    _plataformaController.addListener(() {
      setState(() => _filtroPlataforma = _plataformaController.text);
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

      // INVOCACIÓN CORREGIDA Y SEGURA
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
      _plataformaController.text = '0';
      _searchQuery = '';
      _filtroTalla = '';
      _filtroTaco = '';
      _filtroColor = '';
      _filtroPlataforma = '0';
    });
    _ejecutarBusqueda();
  }

  bool _tieneFiltrosActivos() {
    return _filtroTalla.isNotEmpty ||
        _filtroTaco.isNotEmpty ||
        _filtroColor.isNotEmpty ||
        (_filtroPlataforma.isNotEmpty && _filtroPlataforma != '0');
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

  Widget _buildInputFiltro({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => _ejecutarBusqueda(),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 16, color: Colors.blueAccent),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por calzado...',
                      prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: _tieneFiltrosActivos()
                        ? Colors.blueAccent
                        : Colors.grey.shade200,
                    foregroundColor:
                        _tieneFiltrosActivos() ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: Icon(_mostrarFiltros ? Icons.filter_alt_off : Icons.filter_alt),
                  onPressed: () {
                    setState(() {
                      _mostrarFiltros = !_mostrarFiltros;
                    });
                  },
                ),
              ],
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _mostrarFiltros ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _mostrarFiltros ? 1.0 : 0.0,
                child: SingleChildScrollView(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
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
                              child: _buildInputFiltro(
                                controller: _tallaController,
                                label: 'Talla',
                                icon: Icons.straighten,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInputFiltro(
                                controller: _tacoController,
                                label: 'Taco',
                                icon: Icons.height,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildInputFiltro(
                                controller: _colorController,
                                label: 'ID Color',
                                icon: Icons.palette_outlined,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputFiltro(
                                controller: _plataformaController,
                                label: 'Plataforma',
                                icon: Icons.layers,
                                keyboardType: TextInputType.number,
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
                ),
              ),
            ),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            const SizedBox(height: 10),
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
                          final nombreCalzado = item['nombre_calzado'] ??
                              item['nombre'] ??
                              'Sin nombre';
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
                                vertical: 8, horizontal: 12),
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
                                            if (plataforma != null &&
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
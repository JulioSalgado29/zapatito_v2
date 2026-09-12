import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:zapatito_v2/components/SplashScreen/splash_screen.dart';
import 'package:zapatito_v2/components/widgets.dart';
import 'package:zapatito_v2/services/API/colores.dart';
import 'package:zapatito_v2/services/API/stock.dart';

class StockPage extends StatefulWidget {
  final String? inventarioId;
  final bool isVendedor;

  const StockPage({
    super.key,
    required this.inventarioId,
    required this.isVendedor,
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

  List<Map<String, dynamic>> _listaColores = [];

  bool _cargando = false;

  List<Map<String, dynamic>> _cabecera = [];
  List<Map<String, dynamic>> _detalle = [];

  String _searchQuery = '';
  String _filtroTalla = '';
  String _filtroTaco = '';
  String _filtroColor = '';
  String _filtroPlataforma = '';

  // Conjunto para gestionar IDs seleccionados en la multiselección
  final Set<String> _seleccionadosIds = {};
  bool get _estaEnModoSeleccion =>
      !widget.isVendedor && _seleccionadosIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _escucharControladores();
    _cargarColores();
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

  String _obtenerIdCalzado(Map<String, dynamic> item) {
    final id = item['id_calzado'] ?? item['id'] ?? item['_id'];
    return id?.toString() ?? '';
  }

  void _toggleSeleccion(String id) {
    if (widget.isVendedor || id.isEmpty) return;
    setState(() {
      if (_seleccionadosIds.contains(id)) {
        _seleccionadosIds.remove(id);
      } else {
        _seleccionadosIds.add(id);
      }
    });
  }

  void _limpiarSeleccion() {
    if (widget.isVendedor) return;
    setState(() {
      _seleccionadosIds.clear();
    });
  }

  void _seleccionarTodos(List<Map<String, dynamic>> cabeceraVisibles) {
    if (widget.isVendedor) return;
    setState(() {
      if (_seleccionadosIds.length == cabeceraVisibles.length) {
        _seleccionadosIds.clear();
      } else {
        _seleccionadosIds.clear();
        for (var c in cabeceraVisibles) {
          final id = _obtenerIdCalzado(c);
          if (id.isNotEmpty) {
            _seleccionadosIds.add(id);
          }
        }
      }
    });
  }

  void _mostrarOpcionesEnvio() {
    if (widget.isVendedor) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blueAccent),
                title: const Text('Enviar como Imágenes'),
                onTap: () {
                  Navigator.pop(context);
                  _enviarImagenesPorWhatsApp(comoPdf: false);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                title: const Text('Enviar como PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _enviarImagenesPorWhatsApp(comoPdf: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _enviarImagenesPorWhatsApp({required bool comoPdf}) async {
    if (widget.isVendedor || _seleccionadosIds.isEmpty) return;

    _mostrarSplashScreen();

    try {
      final List<int> idsCalzadoSeleccionados = _seleccionadosIds
          .map((id) => int.tryParse(id) ?? 0)
          .where((id) => id > 0)
          .toList();

      final List<int> idsColorFiltro = _colorController.text.isNotEmpty
          ? _colorController.text
              .split(',')
              .map((e) => int.tryParse(e.trim()) ?? 0)
              .where((e) => e > 0)
              .toList()
          : [];

      final int idInventario =
          int.tryParse(widget.inventarioId.toString()) ?? 0;

      final List<Map<String, dynamic>> imagenesDesdeApi =
          await StockService.obtenerCalzadoImagenesFiltradas(
        idInventario: idInventario,
        idsColor: idsColorFiltro,
        idsCalzado: idsCalzadoSeleccionados,
      );

      final StringBuffer sbLeyenda = StringBuffer();
      sbLeyenda.writeln('📋 *Catálogo de Stock Seleccionado* 👟✨\n');

      for (var idStr in _seleccionadosIds) {
        final itemCabecera = _cabecera.firstWhere(
          (c) => _obtenerIdCalzado(c) == idStr,
          orElse: () => {},
        );

        if (itemCabecera.isNotEmpty) {
          final nombre = itemCabecera['nombre_calzado'] ??
              itemCabecera['nombre'] ??
              'Sin nombre';
          final totalStock =
              itemCabecera['total_stock'] ?? itemCabecera['cantidad'] ?? '0';

          sbLeyenda.writeln('🔹 *${nombre.toString().trim()}*');
          sbLeyenda.writeln('   📦 Cantidad total: $totalStock');

          final subdetallesItem = _detalle.where((d) {
            return (d['id_calzado']?.toString() ?? '') == idStr;
          }).toList();

          if (subdetallesItem.isNotEmpty) {
            for (var sub in subdetallesItem) {
              final talla = sub['talla'] ?? 'N/A';
              final cantSub = sub['stock_detalle'] ?? '0';
              final taco = sub['taco'];
              final plataforma = sub['plataforma'];
              final color = sub['nombre_color'] ?? sub['color'] ?? 'Estándar';

              // Aplicando el formato solicitado también en la leyenda de WhatsApp si lo deseas
              sbLeyenda.writeln('   👟 *${nombre.toString().trim()} - $color*');
              String detalleLinea = '      - Talla: $talla | Cant: $cantSub';
              if (taco != null) detalleLinea += ' | Taco: $taco';
              if (plataforma != null && plataforma.toString() != '0') {
                detalleLinea += ' | Plat: $plataforma';
              }

              sbLeyenda.writeln(detalleLinea);
            }
          }
          sbLeyenda.writeln('');
        }
      }

      // Estructuramos la recolección de imágenes uniendo nombre de calzado y color
      List<Map<String, dynamic>> itemsConDatos = [];

      for (var item in imagenesDesdeApi) {
        final idCalzadoItem = item['id_calzado']?.toString() ?? '';

        final itemCabecera = _cabecera.firstWhere(
          (c) => _obtenerIdCalzado(c) == idCalzadoItem,
          orElse: () => {},
        );
        final nombreCalzado = itemCabecera['nombre_calzado'] ??
            itemCabecera['nombre'] ??
            'Sin nombre';

        final rawImagenes = item['imagenes_filtradas'] ??
            item['imagen_url'] ??
            item['url'] ??
            item['icono'];

        List<String> urlsItem = [];
        if (rawImagenes is List) {
          for (var img in rawImagenes) {
            if (img is String && img.trim().isNotEmpty) {
              urlsItem.add(img.trim());
            } else if (img is Map && img['url'] != null) {
              urlsItem.add(img['url'].toString().trim());
            }
          }
        } else if (rawImagenes is String && rawImagenes.trim().isNotEmpty) {
          urlsItem.add(rawImagenes.trim());
        }

        for (var url in urlsItem) {
          try {
            print('Descargando imagen desde: $url');

            // Extraer el color de la URL usando split
            final uri = Uri.parse(url);
            final colorExtraido = uri.pathSegments[uri.pathSegments.length - 2];
            // O simplemente: final colorExtraido = url.split('/')[7];

            final response = await http.get(uri);
            if (response.statusCode == 200) {
              itemsConDatos.add({
                'bytes': response.bodyBytes,
                'nombre_calzado': nombreCalzado.toString().trim(),
                'nombre_color':
                    colorExtraido, // Usamos el color extraído de la URL
                'url': url,
              });
            }
          } catch (e) {
            print('Error al procesar la URL: $e');
          }
        }
      }

      if (itemsConDatos.isEmpty) {
        _ocultarSplashScreen();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Los elementos seleccionados no contienen imágenes ⚠️'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();

      if (comoPdf) {
        final pdf = pw.Document();

        // 1. Página inicial con el reporte de stock resumido
        pdf.addPage(
          pw.Page(
            pageFormat: pw.PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              List<pw.Widget> widgetsPdf = [];

              widgetsPdf.add(
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(
                    color: pw.PdfColors.blue800,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'REPORTE DE STOCK SELECCIONADO',
                        style: pw.TextStyle(
                          color: pw.PdfColors.white,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Zapatito v2',
                        style: const pw.TextStyle(
                          color: pw.PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              widgetsPdf.add(pw.SizedBox(height: 16));

              for (var idStr in _seleccionadosIds) {
                final itemCabecera = _cabecera.firstWhere(
                  (c) => _obtenerIdCalzado(c) == idStr,
                  orElse: () => {},
                );

                if (itemCabecera.isNotEmpty) {
                  final nombre = itemCabecera['nombre_calzado'] ??
                      itemCabecera['nombre'] ??
                      'Sin nombre';
                  final totalStock = itemCabecera['total_stock'] ??
                      itemCabecera['cantidad'] ??
                      '0';

                  final subdetallesItem = _detalle.where((d) {
                    return (d['id_calzado']?.toString() ?? '') == idStr;
                  }).toList();

                  widgetsPdf.add(
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: pw.PdfColors.grey100,
                        border: pw.Border.all(
                            color: pw.PdfColors.blue200, width: 1),
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                nombre.toString().trim(),
                                style: pw.TextStyle(
                                  fontSize: 13,
                                  fontWeight: pw.FontWeight.bold,
                                  color: pw.PdfColors.blue900,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: const pw.BoxDecoration(
                                  color: pw.PdfColors.blue50,
                                  borderRadius: pw.BorderRadius.all(
                                      pw.Radius.circular(4)),
                                ),
                                child: pw.Text(
                                  'Total: $totalStock',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    color: pw.PdfColors.blue700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (subdetallesItem.isNotEmpty) ...[
                            pw.SizedBox(height: 6),
                            pw.Divider(color: pw.PdfColors.grey300, height: 1),
                            pw.SizedBox(height: 6),
                            ...subdetallesItem.map((sub) {
                              final talla = sub['talla'] ?? 'N/A';
                              final cantSub = sub['stock_detalle'] ?? '0';
                              final taco = sub['taco'];
                              final plataforma = sub['plataforma'];
                              final color = sub['nombre_color'] ?? sub['color'];

                              String detalles =
                                  'Talla: $talla  |  Cant: $cantSub';
                              if (taco != null) detalles += '  |  Taco: $taco';
                              if (plataforma != null &&
                                  plataforma.toString() != '0') {
                                detalles += '  |  Plat: $plataforma';
                              }
                              if (color != null && color.toString().isNotEmpty) {
                                detalles += '  |  Color: $color';
                              }

                              return pw.Padding(
                                padding: const pw.EdgeInsets.only(bottom: 3),
                                child: pw.Text(
                                  '• $detalles',
                                  style: const pw.TextStyle(
                                      fontSize: 10,
                                      color: pw.PdfColors.grey800),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  );
                }
              }

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: widgetsPdf,
              );
            },
          ),
        );

        // 2. Páginas individuales de imágenes con formato "$nombre_calzado - $nombre_color" debajo
        for (var elemento in itemsConDatos) {
          final image = pw.MemoryImage(elemento['bytes'] as Uint8List);
          final String nombreCalzado = elemento['nombre_calzado'];
          final String nombreColor = elemento['nombre_color'];
          final textoEtiqueta = '$nombreCalzado - $nombreColor';

          pdf.addPage(
            pw.Page(
              pageFormat: pw.PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(32),
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Expanded(
                        child: pw.Image(image, fit: pw.BoxFit.contain),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        textoEtiqueta,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: pw.PdfColors.blue900,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        final pdfPath =
            '${tempDir.path}/catalogo_stock_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final pdfFile = File(pdfPath);
        await pdfFile.writeAsBytes(await pdf.save());

        _ocultarSplashScreen();

        if (!mounted) return;
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        final Rect? sharePositionOrigin =
            box != null ? box.localToGlobal(Offset.zero) & box.size : null;

        await Share.shareXFiles(
          [XFile(pdfPath)],
          text: 'Catálogo de stock en PDF con diseño profesional 👟📄',
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        // FLUJO DE WHATSAPP (Imágenes individuales + Texto descriptivo mejorado)
        final List<XFile> xFiles = [];

        for (int i = 0; i < itemsConDatos.length; i++) {
          final elemento = itemsConDatos[i];
          final Uint8List bytes = elemento['bytes'];
          final String url = elemento['url'];

          try {
            String extension = '.jpg';
            final urlLower = url.toLowerCase();
            if (urlLower.contains('.png')) {
              extension = '.png';
            } else if (urlLower.contains('.webp')) {
              extension = '.webp';
            }

            final filePath =
                '${tempDir.path}/stock_img_${DateTime.now().millisecondsSinceEpoch}_$i$extension';
            final file = File(filePath);
            await file.writeAsBytes(bytes);

            xFiles.add(XFile(filePath));
          } catch (_) {}
        }

        _ocultarSplashScreen();

        if (xFiles.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudieron descargar las imágenes ❌'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        if (!mounted) return;
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        final Rect? sharePositionOrigin =
            box != null ? box.localToGlobal(Offset.zero) & box.size : null;

        // Al compartir por WhatsApp, enviamos las imágenes junto con el texto enriquecido
        await Share.shareXFiles(
          xFiles,
          text: sbLeyenda.toString(),
          sharePositionOrigin: sharePositionOrigin,
        );
      }

      _limpiarSeleccion();
    } catch (e) {
      _ocultarSplashScreen();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el envío: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _cargarColores() async {
    if (widget.inventarioId == null) return;
    try {
      final colores = await ColoresService.obtenerPorInventario(
          widget.inventarioId.toString());
      if (mounted) {
        setState(() {
          _listaColores = colores;
        });
      }
    } catch (e) {
      print('Error al cargar la lista de colores: $e');
    }
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
        ? controller.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : [];

    String buscadorDialogo = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final opcionesFiltradas = opciones.where((opcion) {
              if (buscadorDialogo.isEmpty) return true;
              return opcion
                  .toLowerCase()
                  .contains(buscadorDialogo.toLowerCase());
            }).toList();

            return AlertDialog(
              title: Text('Seleccionar $titulo',
                  style: const TextStyle(fontSize: 16)),
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
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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

  void _mostrarSelectorColores() {
    List<String> seleccionadosTemp = _colorController.text.isNotEmpty
        ? _colorController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : [];

    String buscadorDialogo = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final coloresFiltrados = _listaColores.where((color) {
              if (buscadorDialogo.isEmpty) return true;
              final nombre =
                  (color['nombre'] ?? color['nombre_color'] ?? '').toString();
              return nombre
                  .toLowerCase()
                  .contains(buscadorDialogo.toLowerCase());
            }).toList();

            return AlertDialog(
              title: const Text('Seleccionar Colores',
                  style: TextStyle(fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar color...',
                        prefixIcon: Icon(Icons.search, size: 16),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                        itemCount: coloresFiltrados.length,
                        itemBuilder: (context, index) {
                          final colorItem = coloresFiltrados[index];
                          final idColor =
                              colorItem['id_color']?.toString() ?? '';
                          final nombreColor = colorItem['nombre'] ??
                              colorItem['nombre_color'] ??
                              'Sin nombre';
                          final isSelected =
                              seleccionadosTemp.contains(idColor);

                          return CheckboxListTile(
                            title: Text(nombreColor.toString()),
                            value: isSelected,
                            dense: true,
                            onChanged: (bool? value) {
                              setStateDialog(() {
                                if (value == true) {
                                  seleccionadosTemp.add(idColor);
                                } else {
                                  seleccionadosTemp.remove(idColor);
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
                    setState(() {
                      _colorController.text = seleccionadosTemp.join(', ');
                      _filtroColor = _colorController.text;
                    });
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
    VoidCallback? onTapCustom,
  }) {
    return GestureDetector(
      onTap: onTapCustom ??
          (opciones.isNotEmpty
              ? () => _mostrarSelectorOpciones(
                    titulo: label,
                    controller: controller,
                    opciones: opciones,
                  )
              : null),
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          readOnly: true,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 12),
            prefixIcon: Icon(icon, size: 16, color: Colors.blueAccent),
            suffixIcon: (opciones.isNotEmpty || onTapCustom != null)
                ? const Icon(Icons.arrow_drop_down_circle_outlined,
                    size: 18, color: Colors.blueAccent)
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
              borderSide:
                  const BorderSide(color: Colors.blueAccent, width: 1.5),
            ),
          ),
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

  PreferredSizeWidget _buildAppBar(
      List<Map<String, dynamic>> cabeceraFiltrada) {
    if (_estaEnModoSeleccion) {
      return AppBar(
        backgroundColor: const Color.fromARGB(255, 33, 47, 243),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _limpiarSeleccion,
        ),
        title: Text(
          '${_seleccionadosIds.length} seleccionados',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _seleccionadosIds.length == cabeceraFiltrada.length
                  ? Icons.deselect
                  : Icons.select_all,
              color: Colors.white,
            ),
            tooltip: 'Seleccionar todos',
            onPressed: () => _seleccionarTodos(cabeceraFiltrada),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.greenAccent),
            tooltip: 'Enviar imágenes o PDF',
            onPressed: _mostrarOpcionesEnvio,
          ),
        ],
      );
    }
    return Designwidgets().appBarMain("Stock de Inventario");
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
      final nombre = (item['nombre_calzado'] ?? item['nombre'] ?? '')
          .toString()
          .toLowerCase();
      return nombre.contains(query);
    }).toList();

    return Scaffold(
      appBar: _buildAppBar(cabeceraFiltrada),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
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
                            prefixIcon: const Icon(Icons.search,
                                color: Colors.blueAccent, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.grey, size: 16),
                                    onPressed: () => _searchController.clear(),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Colors.blueAccent, width: 1.5),
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
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildInputFiltroConPopup(
                                controller: _tallaController,
                                label: 'Tallas',
                                icon: Icons.straighten,
                                opciones: _listaTallasDisponibles
                                    .map((e) => e.toString())
                                    .toList(),
                              ),
                            ),
                            if (_tallaController.text.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    size: 16, color: Colors.redAccent),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Limpiar Tallas',
                                onPressed: () {
                                  _tallaController.clear();
                                  setState(() => _filtroTalla = '');
                                  _ejecutarBusqueda();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildInputFiltroConPopup(
                                controller: _tacoController,
                                label: 'Tacos',
                                icon: Icons.height,
                                opciones: _listaTacosDisponibles
                                    .map((e) => e.toString())
                                    .toList(),
                              ),
                            ),
                            if (_tacoController.text.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    size: 16, color: Colors.redAccent),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Limpiar Tacos',
                                onPressed: () {
                                  _tacoController.clear();
                                  setState(() => _filtroTaco = '');
                                  _ejecutarBusqueda();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildInputFiltroConPopup(
                                controller: _plataformaController,
                                label: 'Plataforma',
                                icon: Icons.layers,
                                opciones: _listaPlataformasDisponibles,
                              ),
                            ),
                            if (_plataformaController.text.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    size: 16, color: Colors.redAccent),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Limpiar Plataforma',
                                onPressed: () {
                                  _plataformaController.clear();
                                  setState(() => _filtroPlataforma = '');
                                  _ejecutarBusqueda();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  String textoVisual = '';
                                  if (_colorController.text.isNotEmpty) {
                                    List<String> ids = _colorController.text
                                        .split(',')
                                        .map((e) => e.trim())
                                        .toList();
                                    List<String> nombres = [];
                                    for (var id in ids) {
                                      final match = _listaColores.firstWhere(
                                        (c) => c['id_color']?.toString() == id,
                                        orElse: () => {},
                                      );
                                      if (match.isNotEmpty) {
                                        nombres.add(match['nombre'] ??
                                            match['nombre_color'] ??
                                            id);
                                      }
                                    }
                                    textoVisual = nombres.join(', ');
                                  }

                                  final controllerVisual =
                                      TextEditingController(text: textoVisual);

                                  return _buildInputFiltroConPopup(
                                    controller: controllerVisual,
                                    label: 'Colores',
                                    icon: Icons.palette_outlined,
                                    opciones: [],
                                    onTapCustom: _mostrarSelectorColores,
                                  );
                                },
                              ),
                            ),
                            if (_colorController.text.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    size: 16, color: Colors.redAccent),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Limpiar Color',
                                onPressed: () {
                                  _colorController.clear();
                                  setState(() => _filtroColor = '');
                                  _ejecutarBusqueda();
                                },
                              ),
                            ],
                          ],
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
                          style:
                              TextStyle(color: Colors.redAccent, fontSize: 12),
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
                          final idCalzadoStr = _obtenerIdCalzado(item);
                          final nombreCalzado =
                              item['nombre_calzado'] == null ||
                                      item['nombre_calzado']
                                          .toString()
                                          .trim()
                                          .isEmpty
                                  ? (item['nombre'] ?? 'Sin nombre')
                                  : item['nombre_calzado'];
                          final icono = item['icono'] as String?;
                          final cantidadTotal =
                              item['total_stock'] ?? item['cantidad'] ?? '0';

                          final bool estaSeleccionado =
                              _seleccionadosIds.contains(idCalzadoStr);

                          final subdetalles = _detalle.where((d) {
                            return (d['id_calzado']?.toString() ?? '') ==
                                idCalzadoStr;
                          }).toList();

                          return Card(
                            elevation: estaSeleccionado ? 6 : 3,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 0),
                            color: estaSeleccionado
                                ? Colors.blue.shade50
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: estaSeleccionado
                                  ? const BorderSide(
                                      color: Colors.blueAccent, width: 2)
                                  : BorderSide.none,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onLongPress: !widget.isVendedor
                                  ? () => _toggleSeleccion(idCalzadoStr)
                                  : null,
                              onTap: () {
                                if (_estaEnModoSeleccion) {
                                  _toggleSeleccion(idCalzadoStr);
                                }
                              },
                              child: ExpansionTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_estaEnModoSeleccion)
                                      Checkbox(
                                        value: estaSeleccionado,
                                        activeColor: Colors.blueAccent,
                                        onChanged: !widget.isVendedor
                                            ? (_) =>
                                                _toggleSeleccion(idCalzadoStr)
                                            : null,
                                      ),
                                    _buildIcon(icono),
                                  ],
                                ),
                                title: Text(
                                  nombreCalzado,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle:
                                    Text('Cantidad total: $cantidadTotal'),
                                children: subdetalles.isEmpty
                                    ? const [
                                        Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: Text(
                                            'Sin detalles de stock registrados.',
                                            style:
                                                TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      ]
                                    : subdetalles.map((sub) {
                                        final cantSub =
                                            sub['stock_detalle'] ?? '0';
                                        final talla = sub['talla'] ?? 'N/A';
                                        final taco = sub['taco'];
                                        final plataforma = sub['plataforma'];
                                        final nombreColor =
                                            sub['nombre_color'] ?? sub['color'];

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
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
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
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    border: Border.all(
                                                        color:
                                                            Colors.grey[300]!),
                                                  ),
                                                  child: Text(
                                                    'Taco: $taco',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              if (plataforma != null &&
                                                  plataforma.toString() != '0')
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    border: Border.all(
                                                        color:
                                                            Colors.grey[300]!),
                                                  ),
                                                  child: Text(
                                                    'Plataforma: $plataforma',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              if (nombreColor != null &&
                                                  nombreColor
                                                      .toString()
                                                      .isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.indigo[50],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    border: Border.all(
                                                        color: Colors
                                                            .indigo[100]!),
                                                  ),
                                                  child: Text(
                                                    'Color: $nombreColor',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.indigo[900],
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                              ),
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

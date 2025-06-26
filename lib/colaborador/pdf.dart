// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'folio_service.dart'; // Asegúrate de tener este archivo en el mismo folder

class FormularioPDF extends StatefulWidget {
  const FormularioPDF({super.key});

  @override
  State<FormularioPDF> createState() => _FormularioPDFState();
}

class _FormularioPDFState extends State<FormularioPDF> {
  // Controladores de texto para los campos principales
  final TextEditingController campoNombreCliente = TextEditingController();
  final TextEditingController hablarcon = TextEditingController();
  final TextEditingController identificacion = TextEditingController();
  final TextEditingController actividadParaController = TextEditingController();
  final TextEditingController actividadTipoTareaController =
      TextEditingController();
  final TextEditingController descripcionTareaController =
      TextEditingController();
  final TextEditingController tipoSistemaController = TextEditingController();
  final TextEditingController tecnologiaController = TextEditingController();
  final TextEditingController modeloEvaporadorController =
      TextEditingController();
  final TextEditingController serieEvaporadorController =
      TextEditingController();
  final TextEditingController capacidadEvaporadorController =
      TextEditingController();
  final TextEditingController descripcionTrabajoRealizadoController =
      TextEditingController();

  // Listas para fotos de inicio, proceso y fin del servicio
  final List<FotoDescripcionItem> fotosMantenimientoInicio = [];
  final List<FotoDescripcionItem> fotosMantenimientoProceso = [];
  final List<FotoDescripcionItem> fotosMantenimientoFin = [];
  final List<Uint8List> imagenesEvaporadores = [];

  // Controladores y datos para firmas y nombres
  final SignatureController firmaTecnicoController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );
  final SignatureController firmaRecibeController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );
  Uint8List? firmaTecnico;
  Uint8List? firmaRecibe;
  String? nombreTecnico;
  String? nombreRecibe;
  final TextEditingController nombreTecnicoDialogController =
      TextEditingController();
  final TextEditingController nombreRecibeDialogController =
      TextEditingController();

  int? folioActual;
  bool cargandoFolio = true;

  @override
  void initState() {
    super.initState();
    _cargarFolio();
  }

  Future<void> _cargarFolio() async {
    final folio = await FolioService.getNextFolio();
    setState(() {
      folioActual = folio;
      cargandoFolio = false;
    });
  }

  // Diálogo para firmar y capturar nombre
  Future<void> _firmar(
    SignatureController controller,
    String titulo,
    TextEditingController nombreController,
    bool esTecnico,
  ) async {
    if (esTecnico && nombreTecnico != null) {
      nombreController.text = nombreTecnico!;
    } else if (!esTecnico && nombreRecibe != null) {
      nombreController.text = nombreRecibe!;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: Signature(
                    controller: controller,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => controller.clear(),
              child: const Text('Limpiar'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.isNotEmpty &&
                    nombreController.text.trim().isNotEmpty) {
                  final signature = await controller.toPngBytes();
                  Navigator.of(context).pop({
                    'firma': signature,
                    'nombre': nombreController.text.trim(),
                  });
                }
              },
              child: const Text('Guardar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        if (esTecnico) {
          firmaTecnico = result['firma'];
          nombreTecnico = result['nombre'];
        } else {
          firmaRecibe = result['firma'];
          nombreRecibe = result['nombre'];
        }
      });
    }
  }

  void _eliminarFirma(bool esTecnico) {
    setState(() {
      if (esTecnico) {
        firmaTecnico = null;
        nombreTecnico = null;
        firmaTecnicoController.clear();
        nombreTecnicoDialogController.clear();
      } else {
        firmaRecibe = null;
        nombreRecibe = null;
        firmaRecibeController.clear();
        nombreRecibeDialogController.clear();
      }
    });
  }

  // Encabezado con logo y datos empresariales
  Widget _encabezadoCafri() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              "lib/assets/cafrilogo.jpg",
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'HOJA DE SERVICIO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'COMPAÑÍA DE AIRE ACONDICIONADO Y FRIGORIFICOS DEL SURESTE S.A. DE C.V.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text('Teléfono: (999) 102 1232'),
                Text('Número de identificación empresarial: AAF2306305G0'),
                Text('Email: contacto@cafrimx.com'),
                Text(
                  'Dirección: C. 59K N°537 POR 112 Y 114 COL. BOJORQUEZ C.P 97230',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagenesEvaporadoresWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imágenes de evaporadores/condensadores',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...imagenesEvaporadores.map(
              (imgBytes) => Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      imgBytes,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        imagenesEvaporadores.remove(imgBytes);
                      });
                    },
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final XFile? picked = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  setState(() {
                    imagenesEvaporadores.add(bytes);
                  });
                }
              },
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  size: 32,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _firmaWidget({
    required String titulo,
    required Uint8List? firma,
    required String? nombre,
    required VoidCallback onFirmar,
    required VoidCallback onEliminar,
  }) {
    return Column(
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        if (firma != null)
          Column(
            children: [
              Image.memory(firma, height: 150),
              if (nombre != null) Text(nombre),
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Eliminar firma',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: onEliminar,
              ),
            ],
          )
        else
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: const Text('Firmar'),
            onPressed: onFirmar,
          ),
      ],
    );
  }

  Widget _seccionConTitulo(String titulo, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFE0E0E0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(12.0), child: child),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fechaActual = DateTime.now();
    final fechaFormateada =
        '${fechaActual.day.toString().padLeft(2, '0')}/'
        '${fechaActual.month.toString().padLeft(2, '0')}/'
        '${fechaActual.year} '
        '${fechaActual.hour.toString().padLeft(2, '0')}:'
        '${fechaActual.minute.toString().padLeft(2, '0')}';

    if (cargandoFolio || folioActual == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ejemplo PDF Tabla')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _encabezadoCafri(),
              // Folio autoincremental (solo lectura)
              Row(
                children: [
                  const Text(
                    'Folio (Tarea): ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    folioActual.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: campoNombreCliente,
                decoration: const InputDecoration(
                  labelText: 'Nombre del cliente',
                ),
              ),
              TextField(
                controller: hablarcon,
                decoration: const InputDecoration(labelText: 'Hablar con'),
              ),
              TextField(
                controller: identificacion,
                decoration: const InputDecoration(labelText: 'Identificación'),
              ),
              const SizedBox(height: 16),
              _seccionConTitulo(
                'Información de las actividades',
                Column(
                  children: [
                    TextField(
                      controller: actividadParaController,
                      decoration: const InputDecoration(labelText: 'Para'),
                    ),
                    TextField(
                      controller: actividadTipoTareaController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de tarea',
                      ),
                    ),
                    TextField(
                      controller: descripcionTareaController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción de la tarea',
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _seccionConTitulo(
                'MODELO, SERIE, CAPACIDAD DE CONDENSADORES',
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: modeloEvaporadorController,
                        decoration: const InputDecoration(labelText: 'Modelo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: serieEvaporadorController,
                        decoration: const InputDecoration(labelText: 'Serie'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: capacidadEvaporadorController,
                        decoration: const InputDecoration(
                          labelText: 'Capacidad',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _imagenesEvaporadoresWidget(),
              const SizedBox(height: 16),
              _seccionConTitulo(
                'Fotos de inicio del servicio',
                FotoDescripcionLista(
                  encabezadoFoto: 'Foto',
                  encabezadoDescripcion: 'Descripción',
                  items: fotosMantenimientoInicio,
                  onAdd: (item) =>
                      setState(() => fotosMantenimientoInicio.add(item)),
                  onRemove: (idx) =>
                      setState(() => fotosMantenimientoInicio.removeAt(idx)),
                ),
              ),
              const SizedBox(height: 16),
              _seccionConTitulo(
                'Fotos de proceso del servicio',
                FotoDescripcionLista(
                  encabezadoFoto: 'Foto',
                  encabezadoDescripcion: 'Descripción',
                  items: fotosMantenimientoProceso,
                  onAdd: (item) =>
                      setState(() => fotosMantenimientoProceso.add(item)),
                  onRemove: (idx) =>
                      setState(() => fotosMantenimientoProceso.removeAt(idx)),
                ),
              ),
              const SizedBox(height: 16),
              _seccionConTitulo(
                'Fotos de fin del servicio',
                FotoDescripcionLista(
                  encabezadoFoto: 'Foto',
                  encabezadoDescripcion: 'Descripción',
                  items: fotosMantenimientoFin,
                  onAdd: (item) =>
                      setState(() => fotosMantenimientoFin.add(item)),
                  onRemove: (idx) =>
                      setState(() => fotosMantenimientoFin.removeAt(idx)),
                ),
              ),
              const SizedBox(height: 16),
              _seccionConTitulo(
                'Descripción del trabajo realizado',
                TextField(
                  controller: descripcionTrabajoRealizadoController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _firmaWidget(
                      titulo: 'Firma del técnico',
                      firma: firmaTecnico,
                      nombre: nombreTecnico,
                      onFirmar: () => _firmar(
                        firmaTecnicoController,
                        'Firma del técnico',
                        nombreTecnicoDialogController,
                        true,
                      ),
                      onEliminar: () => _eliminarFirma(true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _firmaWidget(
                      titulo: 'Firma de quien recibe',
                      firma: firmaRecibe,
                      nombre: nombreRecibe,
                      onFirmar: () => _firmar(
                        firmaRecibeController,
                        'Firma de quien recibe',
                        nombreRecibeDialogController,
                        false,
                      ),
                      onEliminar: () => _eliminarFirma(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Guardar como PDF'),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirmar generación de PDF'),
                      content: const Text(
                        'Estás a punto de generar el PDF. ¿Está todo correcto?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Sí, continuar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  // Carga el logo como bytes desde la ruta UNIFICADA
                  final logoBytes = await rootBundle.load(
                    'lib/assets/cafrilogo.jpg',
                  );
                  final logoUint8List = logoBytes.buffer.asUint8List();

                  List<Map<String, dynamic>> fotosInicio =
                      fotosMantenimientoInicio
                          .map(
                            (item) => {
                              'bytes': item.imageBytes,
                              'descripcion': item.descripcionController.text,
                            },
                          )
                          .toList();
                  List<Map<String, dynamic>> fotosProceso =
                      fotosMantenimientoProceso
                          .map(
                            (item) => {
                              'bytes': item.imageBytes,
                              'descripcion': item.descripcionController.text,
                            },
                          )
                          .toList();
                  List<Map<String, dynamic>> fotosFin = fotosMantenimientoFin
                      .map(
                        (item) => {
                          'bytes': item.imageBytes,
                          'descripcion': item.descripcionController.text,
                        },
                      )
                      .toList();

                  final pdfBytes = await PdfGenerator.generatePdf(
                    folio: folioActual!,
                    nombreCliente: campoNombreCliente.text,
                    hablarCon: hablarcon.text,
                    identificacion: identificacion.text,
                    actividadPara: actividadParaController.text,
                    actividadTipoTarea: actividadTipoTareaController.text,
                    descripcionTarea: descripcionTareaController.text,
                    modeloEvaporador: modeloEvaporadorController.text,
                    serieEvaporador: serieEvaporadorController.text,
                    capacidadEvaporador: capacidadEvaporadorController.text,
                    descripcionTrabajoRealizado:
                        descripcionTrabajoRealizadoController.text,
                    fotosInicio: fotosInicio,
                    fotosProceso: fotosProceso,
                    fotosFin: fotosFin,
                    imagenesEvaporadores: imagenesEvaporadores,
                    firmaTecnico: firmaTecnico,
                    nombreTecnico: nombreTecnico,
                    firmaRecibe: firmaRecibe,
                    nombreRecibe: nombreRecibe,
                    fechaFormateada: fechaFormateada,
                    logoBytes: logoUint8List,
                  );

                  // Actualiza el folio en Firestore y localmente
                  await FolioService.updateFolio(folioActual!);
                  setState(() {
                    folioActual = folioActual! + 1;
                  });

                  // El nombre del archivo PDF será Tarea(folio).pdf
                  await Printing.layoutPdf(
                    onLayout: (format) async => pdfBytes,
                    name: 'Tarea(${folioActual! - 1}).pdf',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para lista de fotos y descripciones dinámicas
class FotoDescripcionLista extends StatefulWidget {
  final String encabezadoFoto;
  final String encabezadoDescripcion;
  final List<FotoDescripcionItem> items;
  final void Function(FotoDescripcionItem) onAdd;
  final void Function(int) onRemove;

  const FotoDescripcionLista({
    super.key,
    required this.encabezadoFoto,
    required this.encabezadoDescripcion,
    required this.items,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<FotoDescripcionLista> createState() => _FotoDescripcionListaState();
}

class _FotoDescripcionListaState extends State<FotoDescripcionLista> {
  Future<void> _agregarFoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      widget.onAdd(
        FotoDescripcionItem(
          imageBytes: bytes,
          descripcionController: TextEditingController(),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.encabezadoFoto,
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Text(
                widget.encabezadoDescripcion,
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Agregar foto'),
            onPressed: _agregarFoto,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.items.isEmpty) const Text('No hay fotos agregadas.'),
        ...widget.items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    item.imageBytes,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: item.descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => widget.onRemove(idx),
                  tooltip: 'Eliminar foto',
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class FotoDescripcionItem {
  final Uint8List imageBytes;
  final TextEditingController descripcionController;

  FotoDescripcionItem({
    required this.imageBytes,
    required this.descripcionController,
  });
}

// Generador de PDF
class PdfGenerator {
  static Future<Uint8List> generatePdf({
    required int folio,
    required String nombreCliente,
    required String hablarCon,
    required String identificacion,
    required String actividadPara,
    required String actividadTipoTarea,
    required String descripcionTarea,
    required String modeloEvaporador,
    required String serieEvaporador,
    required String capacidadEvaporador,
    required String descripcionTrabajoRealizado,
    required List<Map<String, dynamic>> fotosInicio,
    required List<Map<String, dynamic>> fotosProceso,
    required List<Map<String, dynamic>> fotosFin,
    required List<Uint8List> imagenesEvaporadores,
    Uint8List? firmaTecnico,
    String? nombreTecnico,
    Uint8List? firmaRecibe,
    String? nombreRecibe,
    required String fechaFormateada,
    required Uint8List logoBytes,
  }) async {
    final pdf = pw.Document();

    pw.Widget buildFotoDescripcion(
      List<Map<String, dynamic>> fotos,
      String titulo,
    ) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          ...fotos.map(
            (foto) => pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (foto['bytes'] != null)
                  pw.Container(
                    width: 150,
                    height: 150,
                    child: pw.Image(
                      pw.MemoryImage(foto['bytes']),
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                pw.SizedBox(width: 8),
                pw.Expanded(child: pw.Text(foto['descripcion'] ?? '')),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
        ],
      );
    }

    pw.Widget buildImagenesEvaporadores(List<Uint8List> imagenes) {
      if (imagenes.isEmpty) return pw.Text('No hay imágenes agregadas.');
      return pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: imagenes
            .map(
              (imgBytes) => pw.Container(
                width: 150,
                height: 150,
                child: pw.Image(pw.MemoryImage(imgBytes), fit: pw.BoxFit.cover),
              ),
            )
            .toList(),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          // Encabezado con logo y datos empresariales
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 80,
                height: 80,
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'HOJA DE SERVICIO',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'COMPAÑÍA DE AIRE ACONDICIONADO Y FRIGORIFICOS DEL SURESTE S.A. DE C.V.',
                    ),
                    pw.Text('Teléfono: (999) 102 1232'),
                    pw.Text(
                      'Número de identificación empresarial: AAF2306305G0',
                    ),
                    pw.Text('Email: contacto@cafrimx.com'),
                    pw.Text(
                      'Dirección: C. 59K N°537 POR 112 Y 114 COL. BOJORQUEZ C.P 97230',
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Fecha: $fechaFormateada'),
          pw.Text(
            'Folio (Tarea): $folio',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(),

          pw.Text(
            'Información del cliente',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Nombre del cliente: $nombreCliente'),
          pw.Text('Hablar con: $hablarCon'),
          pw.Text('Identificación: $identificacion'),
          pw.SizedBox(height: 8),

          pw.Text(
            'Información de las actividades',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Para: $actividadPara'),
          pw.Text('Tipo de tarea: $actividadTipoTarea'),
          pw.Text('Descripción de la tarea: $descripcionTarea'),
          pw.SizedBox(height: 8),

          pw.Text(
            'MODELO, SERIE, CAPACIDAD DE CONDENSADORES',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Modelo',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Serie',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(
                      'Capacidad',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(modeloEvaporador),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(serieEvaporador),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(capacidadEvaporador),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          pw.Text(
            'Imágenes de evaporadores/condensadores',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          buildImagenesEvaporadores(imagenesEvaporadores),
          pw.SizedBox(height: 8),

          buildFotoDescripcion(fotosInicio, 'Fotos de inicio del servicio'),
          buildFotoDescripcion(fotosProceso, 'Fotos de proceso del servicio'),
          buildFotoDescripcion(fotosFin, 'Fotos de fin del servicio'),

          pw.Text(
            'Descripción del trabajo realizado',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(descripcionTrabajoRealizado),
          pw.SizedBox(height: 12),

          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Firma del técnico',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    if (firmaTecnico != null)
                      pw.Image(pw.MemoryImage(firmaTecnico), height: 150),
                    if (nombreTecnico != null) pw.Text(nombreTecnico),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Firma de quien recibe',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    if (firmaRecibe != null)
                      pw.Image(pw.MemoryImage(firmaRecibe), height: 150),
                    if (nombreRecibe != null) pw.Text(nombreRecibe),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'En CAFRI, estamos comprometidos con la reducción del uso de papel y trabajamos continuamente para ser más amigables con el medio ambiente. '
            'Nos esforzamos en la mejora constante y la actualización de nuestros sistemas para minimizar nuestro impacto ecológico.\n\n'
            '(999) 102 1232 / (999) 490 1637   cafrimx.com\n\n'
            'Este documento es propiedad de la empresa CAFRI COMPAÑÍA DE AIRE ACONDICIONADO Y FRIGORIFICOS DEL SURESTE S.A. DE C.V. con domicilio en Calle 59 K, 537 Cp. 97230 en la ciudad de Mérida, Yucatán, '
            'por lo que queda prohibida la reproducción parcial o total de este documento y se tomarán acciones legales.',
            style: pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    return pdf.save();
  }
}

// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'folio_service.dart';

// Modelo para una hoja/formulario individual (excepto datos de cliente)
class HojaServicioData {
  final TextEditingController actividadParaController = TextEditingController();
  final TextEditingController actividadTipoTareaController =
      TextEditingController();
  final TextEditingController descripcionTareaController =
      TextEditingController();
  final TextEditingController modeloEvaporadorController =
      TextEditingController();
  final TextEditingController serieEvaporadorController =
      TextEditingController();
  final TextEditingController capacidadEvaporadorController =
      TextEditingController();
  final TextEditingController descripcionTrabajoRealizadoController =
      TextEditingController();

  // Cambios aquí: ahora son listas de imágenes y un solo controlador de descripción por sección
  final List<Uint8List> fotosMantenimientoInicio = [];
  final List<Uint8List> fotosMantenimientoProceso = [];
  final List<Uint8List> fotosMantenimientoFin = [];
  final TextEditingController descripcionInicioController =
      TextEditingController();
  final TextEditingController descripcionProcesoController =
      TextEditingController();
  final TextEditingController descripcionFinController =
      TextEditingController();

  final List<Uint8List> imagenesEvaporadores = [];

  Uint8List? firmaTecnico;
  Uint8List? firmaRecibe;
  String? nombreTecnico;
  String? nombreRecibe;

  final SignatureController firmaTecnicoController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );
  final SignatureController firmaRecibeController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
  );
  final TextEditingController nombreTecnicoDialogController =
      TextEditingController();
  final TextEditingController nombreRecibeDialogController =
      TextEditingController();

  void dispose() {
    actividadParaController.dispose();
    actividadTipoTareaController.dispose();
    descripcionTareaController.dispose();
    modeloEvaporadorController.dispose();
    serieEvaporadorController.dispose();
    capacidadEvaporadorController.dispose();
    descripcionTrabajoRealizadoController.dispose();
    firmaTecnicoController.dispose();
    firmaRecibeController.dispose();
    nombreTecnicoDialogController.dispose();
    nombreRecibeDialogController.dispose();
    descripcionInicioController.dispose();
    descripcionProcesoController.dispose();
    descripcionFinController.dispose();
  }

  void clear() {
    actividadParaController.clear();
    actividadTipoTareaController.clear();
    descripcionTareaController.clear();
    modeloEvaporadorController.clear();
    serieEvaporadorController.clear();
    capacidadEvaporadorController.clear();
    descripcionTrabajoRealizadoController.clear();
    firmaTecnico = null;
    firmaRecibe = null;
    nombreTecnico = null;
    nombreRecibe = null;
    firmaTecnicoController.clear();
    firmaRecibeController.clear();
    nombreTecnicoDialogController.clear();
    nombreRecibeDialogController.clear();
    fotosMantenimientoInicio.clear();
    fotosMantenimientoProceso.clear();
    fotosMantenimientoFin.clear();
    descripcionInicioController.clear();
    descripcionProcesoController.clear();
    descripcionFinController.clear();
    imagenesEvaporadores.clear();
  }

  Map<String, dynamic> toMap() => {
    'para': actividadParaController.text,
    'tipoTarea': actividadTipoTareaController.text,
    'descripcionTarea': descripcionTareaController.text,
    'modeloEvaporador': modeloEvaporadorController.text,
    'serieEvaporador': serieEvaporadorController.text,
    'capacidadEvaporador': capacidadEvaporadorController.text,
    'descripcionTrabajoRealizado': descripcionTrabajoRealizadoController.text,
    'fotosInicio': fotosMantenimientoInicio,
    'descripcionInicio': descripcionInicioController.text,
    'fotosProceso': fotosMantenimientoProceso,
    'descripcionProceso': descripcionProcesoController.text,
    'fotosFin': fotosMantenimientoFin,
    'descripcionFin': descripcionFinController.text,
    'imagenesEvaporadores': imagenesEvaporadores,
    'firmaTecnico': firmaTecnico,
    'nombreTecnico': nombreTecnico,
    'firmaRecibe': firmaRecibe,
    'nombreRecibe': nombreRecibe,
  };
}

class FormularioPDF extends StatefulWidget {
  const FormularioPDF({super.key});

  @override
  State<FormularioPDF> createState() => _FormularioPDFState();
}

class _FormularioPDFState extends State<FormularioPDF> {
  // Campos de cliente (únicos)
  final TextEditingController campoNombreCliente = TextEditingController();
  final TextEditingController hablarcon = TextEditingController();
  final TextEditingController identificacion = TextEditingController();

  // Lista dinámica de hojas (formularios)
  final List<HojaServicioData> hojas = [HojaServicioData()];

  int? folioActual;
  bool cargandoFolio = true;

  @override
  void initState() {
    super.initState();
    _cargarFolio();
  }

  @override
  void dispose() {
    for (final hoja in hojas) {
      hoja.dispose();
    }
    campoNombreCliente.dispose();
    hablarcon.dispose();
    identificacion.dispose();
    super.dispose();
  }

  Future<void> _cargarFolio() async {
    final folio = await FolioService.getNextFolio();
    setState(() {
      folioActual = folio;
      cargandoFolio = false;
    });
  }

  void _limpiarFormulario() {
    campoNombreCliente.clear();
    hablarcon.clear();
    identificacion.clear();
    for (final hoja in hojas) {
      hoja.dispose();
    }
    hojas
      ..clear()
      ..add(HojaServicioData());
  }

  Widget _hojasWidget() {
    return Column(
      children: [
        ...hojas.asMap().entries.map((entry) {
          final idx = entry.key;
          final hoja = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Hoja ${idx + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      if (hojas.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              hoja.dispose();
                              hojas.removeAt(idx);
                            });
                          },
                        ),
                    ],
                  ),
                  // Actividades
                  TextField(
                    controller: hoja.actividadParaController,
                    decoration: const InputDecoration(labelText: 'Para'),
                  ),
                  TextField(
                    controller: hoja.actividadTipoTareaController,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de tarea',
                    ),
                  ),
                  TextField(
                    controller: hoja.descripcionTareaController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción de la tarea',
                    ),
                    maxLines: 2,
                  ),
                  // Modelo, serie, capacidad
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: hoja.modeloEvaporadorController,
                          decoration: const InputDecoration(
                            labelText: 'Modelo',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: hoja.serieEvaporadorController,
                          decoration: const InputDecoration(labelText: 'Serie'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: hoja.capacidadEvaporadorController,
                          decoration: const InputDecoration(
                            labelText: 'Capacidad',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Imágenes de evaporadores
                  _imagenesEvaporadoresWidget(hoja),
                  const SizedBox(height: 8),
                  // Fotos inicio/proceso/fin (nuevo widget)
                  FotosFilaDescripcion(
                    titulo: 'Fotos de inicio',
                    fotos: hoja.fotosMantenimientoInicio,
                    descripcionController: hoja.descripcionInicioController,
                    onAdd: (img) =>
                        setState(() => hoja.fotosMantenimientoInicio.add(img)),
                    onRemove: (idx) => setState(
                      () => hoja.fotosMantenimientoInicio.removeAt(idx),
                    ),
                  ),
                  FotosFilaDescripcion(
                    titulo: 'Fotos de proceso',
                    fotos: hoja.fotosMantenimientoProceso,
                    descripcionController: hoja.descripcionProcesoController,
                    onAdd: (img) =>
                        setState(() => hoja.fotosMantenimientoProceso.add(img)),
                    onRemove: (idx) => setState(
                      () => hoja.fotosMantenimientoProceso.removeAt(idx),
                    ),
                  ),
                  FotosFilaDescripcion(
                    titulo: 'Fotos de fin',
                    fotos: hoja.fotosMantenimientoFin,
                    descripcionController: hoja.descripcionFinController,
                    onAdd: (img) =>
                        setState(() => hoja.fotosMantenimientoFin.add(img)),
                    onRemove: (idx) => setState(
                      () => hoja.fotosMantenimientoFin.removeAt(idx),
                    ),
                  ),
                  // Descripción trabajo realizado
                  TextField(
                    controller: hoja.descripcionTrabajoRealizadoController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción del trabajo realizado',
                    ),
                    maxLines: 3,
                  ),
                  // Firmas
                  Row(
                    children: [
                      Expanded(
                        child: _firmaWidget(
                          titulo: 'Firma del técnico',
                          firma: hoja.firmaTecnico,
                          nombre: hoja.nombreTecnico,
                          onFirmar: () => _firmar(
                            hoja.firmaTecnicoController,
                            'Firma del técnico',
                            hoja.nombreTecnicoDialogController,
                            true,
                            hoja,
                          ),
                          onEliminar: () => _eliminarFirma(true, hoja),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _firmaWidget(
                          titulo: 'Firma de quien recibe',
                          firma: hoja.firmaRecibe,
                          nombre: hoja.nombreRecibe,
                          onFirmar: () => _firmar(
                            hoja.firmaRecibeController,
                            'Firma de quien recibe',
                            hoja.nombreRecibeDialogController,
                            false,
                            hoja,
                          ),
                          onEliminar: () => _eliminarFirma(false, hoja),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar otra hoja'),
            onPressed: () {
              setState(() {
                hojas.add(HojaServicioData());
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _imagenesEvaporadoresWidget(HojaServicioData hoja) {
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
            ...hoja.imagenesEvaporadores.map(
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
                        hoja.imagenesEvaporadores.remove(imgBytes);
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
                  source: ImageSource.gallery, // CAMBIO: galería
                );
                if (picked != null) {
                  final bytes = await picked.readAsBytes();
                  setState(() {
                    hoja.imagenesEvaporadores.add(bytes);
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
              Image.memory(firma, height: 100),
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

  Future<void> _firmar(
    SignatureController controller,
    String titulo,
    TextEditingController nombreController,
    bool esTecnico,
    HojaServicioData hoja,
  ) async {
    if (esTecnico && hoja.nombreTecnico != null) {
      nombreController.text = hoja.nombreTecnico!;
    } else if (!esTecnico && hoja.nombreRecibe != null) {
      nombreController.text = hoja.nombreRecibe!;
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
          hoja.firmaTecnico = result['firma'];
          hoja.nombreTecnico = result['nombre'];
        } else {
          hoja.firmaRecibe = result['firma'];
          hoja.nombreRecibe = result['nombre'];
        }
      });
    }
  }

  void _eliminarFirma(bool esTecnico, HojaServicioData hoja) {
    setState(() {
      if (esTecnico) {
        hoja.firmaTecnico = null;
        hoja.nombreTecnico = null;
        hoja.firmaTecnicoController.clear();
        hoja.nombreTecnicoDialogController.clear();
      } else {
        hoja.firmaRecibe = null;
        hoja.nombreRecibe = null;
        hoja.firmaRecibeController.clear();
        hoja.nombreRecibeDialogController.clear();
      }
    });
  }

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
              _seccionConTitulo('Hojas de servicio', _hojasWidget()),
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

                  final logoBytes = await rootBundle.load(
                    'lib/assets/cafrilogo.jpg',
                  );
                  final logoUint8List = logoBytes.buffer.asUint8List();

                  final hojasList = hojas.map((h) => h.toMap()).toList();

                  // --- CAMBIO CLAVE: Guarda el folio actual en una variable local ---
                  final folioParaPDF = folioActual!;

                  final pdfBytes = await PdfGenerator.generatePdf(
                    folio: folioParaPDF,
                    nombreCliente: campoNombreCliente.text,
                    hablarCon: hablarcon.text,
                    identificacion: identificacion.text,
                    hojas: hojasList,
                    fechaFormateada: fechaFormateada,
                    logoBytes: logoUint8List,
                  );

                  await FolioService.updateFolio(folioParaPDF);
                  setState(() {
                    folioActual = folioParaPDF + 1;
                    _limpiarFormulario();
                  });

                  await Printing.layoutPdf(
                    onLayout: (format) async => pdfBytes,
                    name:
                        'Tarea($folioParaPDF).pdf', // Usa el folio correcto aquí
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

// Widget para lista de fotos en fila y una sola descripción
class FotosFilaDescripcion extends StatefulWidget {
  final String titulo;
  final List<Uint8List> fotos;
  final TextEditingController descripcionController;
  final void Function(Uint8List) onAdd;
  final void Function(int) onRemove;

  const FotosFilaDescripcion({
    super.key,
    required this.titulo,
    required this.fotos,
    required this.descripcionController,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<FotosFilaDescripcion> createState() => _FotosFilaDescripcionState();
}

class _FotosFilaDescripcionState extends State<FotosFilaDescripcion> {
  Future<void> _agregarFoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
    ); // CAMBIO: galería
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      widget.onAdd(bytes);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.fotos.asMap().entries.map((entry) {
              final idx = entry.key;
              final imgBytes = entry.value;
              return Stack(
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
                      widget.onRemove(idx);
                      setState(() {});
                    },
                  ),
                ],
              );
            }),
            GestureDetector(
              onTap: _agregarFoto,
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
        const SizedBox(height: 8),
        TextField(
          controller: widget.descripcionController,
          decoration: const InputDecoration(labelText: 'Descripción'),
          maxLines: 2,
        ),
      ],
    );
  }
}

// Generador de PDF multipágina
class PdfGenerator {
  static Future<Uint8List> generatePdf({
    required int folio,
    required String nombreCliente,
    required String hablarCon,
    required String identificacion,
    required List<Map<String, dynamic>> hojas,
    required String fechaFormateada,
    required Uint8List logoBytes,
  }) async {
    final pdf = pw.Document();

    // Fotos en fila y una sola descripción por sección
    pw.Widget buildFotoFila(List fotos, String descripcion, String titulo) {
      if (fotos.isEmpty) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              titulo,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('No hay fotos agregadas.'),
            pw.SizedBox(height: 8),
            if (descripcion.isNotEmpty)
              pw.Text(descripcion, style: pw.TextStyle(fontSize: 10)),
          ],
        );
      }
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(titulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fotos.map<pw.Widget>((imgBytes) {
              return pw.Container(
                width: 90,
                height: 90,
                child: pw.Image(pw.MemoryImage(imgBytes), fit: pw.BoxFit.cover),
              );
            }).toList(),
          ),
          pw.SizedBox(height: 4),
          if (descripcion.isNotEmpty)
            pw.Text(descripcion, style: pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 8),
        ],
      );
    }

    pw.Widget buildImagenesEvaporadores(List imagenes) {
      if (imagenes.isEmpty) return pw.Text('No hay imágenes agregadas.');
      return pw.Wrap(
        spacing: 8,
        runSpacing: 8,
        children: imagenes
            .map<pw.Widget>(
              (imgBytes) => pw.Container(
                width: 90,
                height: 90,
                child: pw.Image(pw.MemoryImage(imgBytes), fit: pw.BoxFit.cover),
              ),
            )
            .toList(),
      );
    }

    for (final hoja in hojas) {
      pdf.addPage(
        pw.MultiPage(
          build: (context) => [
            // Encabezado con logo y datos empresariales (NO MODIFICADO)
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
            pw.Text('Para: ${hoja['para'] ?? ''}'),
            pw.Text('Tipo de tarea: ${hoja['tipoTarea'] ?? ''}'),
            pw.Text(
              'Descripción de la tarea: ${hoja['descripcionTarea'] ?? ''}',
            ),
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
                      child: pw.Text(hoja['modeloEvaporador'] ?? ''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(hoja['serieEvaporador'] ?? ''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(hoja['capacidadEvaporador'] ?? ''),
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
            buildImagenesEvaporadores(hoja['imagenesEvaporadores'] ?? []),
            pw.SizedBox(height: 8),

            buildFotoFila(
              (hoja['fotosInicio'] ?? []) as List,
              hoja['descripcionInicio'] ?? '',
              'Fotos de inicio del servicio',
            ),
            pw.SizedBox(height: 20),
            buildFotoFila(
              (hoja['fotosProceso'] ?? []) as List,
              hoja['descripcionProceso'] ?? '',
              'Fotos de proceso del servicio',
            ),
            pw.SizedBox(height: 20),
            buildFotoFila(
              (hoja['fotosFin'] ?? []) as List,
              hoja['descripcionFin'] ?? '',
              'Fotos de fin del servicio',
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              'Descripción del trabajo realizado',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(hoja['descripcionTrabajoRealizado'] ?? ''),
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
                      if (hoja['firmaTecnico'] != null)
                        pw.Image(
                          pw.MemoryImage(hoja['firmaTecnico']),
                          height: 100,
                        ),
                      if (hoja['nombreTecnico'] != null)
                        pw.Text(hoja['nombreTecnico']),
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
                      if (hoja['firmaRecibe'] != null)
                        pw.Image(
                          pw.MemoryImage(hoja['firmaRecibe']),
                          height: 100,
                        ),
                      if (hoja['nombreRecibe'] != null)
                        pw.Text(hoja['nombreRecibe']),
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
    }

    return pdf.save();
  }
}

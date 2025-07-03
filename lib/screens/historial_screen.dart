import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';

class HistorialScreen extends StatefulWidget {
  final String nombre;
  final String ruc;

  const HistorialScreen({
    super.key,
    required this.nombre,
    required this.ruc,
  });

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<dynamic> historial = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final response = await SupabaseService.client
        .from('solicitudes')
        .select()
        .eq('estado', 'resuelto')
        .eq('ruc_clinica', widget.ruc)
        .order('fecha_creacion', ascending: false);

    setState(() {
      historial = response;
      cargando = false;
    });
  }

  String _fmtFecha(String iso) {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _mostrarDetalle(Map<String, dynamic> s) async {
    await showGeneralDialog(
      context: context,
      barrierLabel: 'DetalleSolicitud',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, _) {
        final curved = Curves.easeOut.transform(anim1.value);
        return Opacity(
          opacity: curved,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8 * curved, sigmaY: 8 * curved),
            child: Center(
              child: _DetailCard(solicitud: s, parentContext: context),
            ),
          ),
        );
      },
    );
  }

  Future<pw.Document> _generarPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('HISTORIAL DE SOLICITUDES RESUELTAS',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Clínica: ${widget.nombre}', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('RUC: ${widget.ruc}', style: const pw.TextStyle(fontSize: 12)),
            pw.Text('Fecha de generación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', 
                style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: ['ID', 'Fecha', 'Descripción', 'Estado', 'Prioridad'],
              data: historial.map((s) => [
                '#${s['id']}',
                _fmtFecha(s['fecha_creacion']),
                (s['descripcion'] ?? '').toString().length > 30 
                    ? '${(s['descripcion'] ?? '').toString().substring(0, 30)}...'
                    : (s['descripcion'] ?? '').toString(),
                s['estado']?.toString().toUpperCase() ?? '',
                s['prioridad']?.toString() ?? '',
              ]).toList(),
            ),
          ],
        ),
      ),
    );
    return pdf;
  }

  Future<void> _mostrarPDFPreview() async {
    if (historial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay solicitudes resueltas para exportar.')),
      );
      return;
    }

    final pdf = await _generarPDF();

    // Mostrar preview del PDF
    await showGeneralDialog(
      context: context,
      barrierLabel: 'PDFPreview',
      barrierDismissible: true,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, _) {
        final curved = Curves.easeOut.transform(anim1.value);
        return Opacity(
          opacity: curved,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8 * curved, sigmaY: 8 * curved),
            child: Center(
              child: _PDFPreviewCard(
                historial: historial, 
                clinicaNombre: widget.nombre,
                clinicaRuc: widget.ruc,
                pdf: pdf,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF233550),
      child: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E3B53),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Image.asset('assets/empresa.png', width: 32, height: 32),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Portal Clínica',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        Text(widget.nombre.toUpperCase(),
                            style: const TextStyle(
                                color: Color(0xFFee763d), fontSize: 12)),
                      ],
                    ),
                  ),
                  InkWell(onTap: _logout,
                      child: Image.asset('assets/logout.png', width:24, height:24)),
                ],
              ),
            ),
            // TÍTULO y botón PDF
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('HISTORIAL RESUELTOS',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    onPressed: _mostrarPDFPreview,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4))),
                    child: const Text('Exportar PDF',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Encabezados tabla
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Expanded(
                      flex: 2,
                      child: Text('ID',
                          style:
                              TextStyle(color: Colors.white70, fontSize:12))),
                  Expanded(
                      flex: 3,
                      child: Text('Fecha',
                          style:
                              TextStyle(color: Colors.white70, fontSize:12))),
                  Expanded(
                      flex: 5,
                      child: Text('Descripción',
                          style:
                              TextStyle(color: Colors.white70, fontSize:12))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Lista historial
            Expanded(
              child: cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(Color(0xFFee763d))))
                  : historial.isEmpty
                      ? const Center(
                          child: Text('No hay resueltos aún',
                              style:
                                  TextStyle(color: Colors.white70)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: historial.length,
                          itemBuilder: (_, i) {
                            final s = historial[i];
                            return GestureDetector(
                              onTap: () => _mostrarDetalle(s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text('#${s['id']}',
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(_fmtFecha(
                                          s['fecha_creacion']),
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize:12)),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        s['descripcion'] ?? '',
                                        style: const TextStyle(color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  final BuildContext parentContext;
  
  const _DetailCard({
    required this.solicitud,
    required this.parentContext,
  });

  String _formatFecha(String iso) {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF15212c).withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOLICITUD #${solicitud['id']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Clínica:', '${solicitud['clinicas']?['nombre'] ?? ''} (${solicitud['ruc_clinica']})'),
              const SizedBox(height: 8),
              _buildInfoRow('Fecha:', _formatFecha(solicitud['fecha_creacion'])),
              const SizedBox(height: 12),
              const Text(
                'DESCRIPCIÓN:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                solicitud['descripcion'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Estado:', solicitud['estado'].toString().toUpperCase()),
              const SizedBox(height: 8),
              _buildInfoRow('Prioridad:', solicitud['prioridad']),
              const SizedBox(height: 12),
              
              // Comentario del administrador
              if (solicitud['comentario'] != null && solicitud['comentario'].toString().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3B53).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFee763d).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COMENTARIO DEL ADMINISTRADOR:',
                        style: TextStyle(color: Color(0xFFee763d), fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        solicitud['comentario'],
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFee763d)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: const Text('Cerrar', style: TextStyle(color: Color(0xFFee763d))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PDFPreviewCard extends StatelessWidget {
  final List<dynamic> historial;
  final String clinicaNombre;
  final String clinicaRuc;
  final pw.Document pdf;

  const _PDFPreviewCard({
    required this.historial,
    required this.clinicaNombre,
    required this.clinicaRuc,
    required this.pdf,
  });

  String _fmtFecha(String iso) {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
  }

  Future<void> _descargarPDF(BuildContext context) async {
    try {
      // Obtener el directorio de descargas
      Directory? downloadsDirectory;
      
      if (Platform.isAndroid) {
        downloadsDirectory = Directory('/storage/emulated/0/Download');
        if (!await downloadsDirectory.exists()) {
          downloadsDirectory = await getExternalStorageDirectory();
        }
      } else {
        downloadsDirectory = await getApplicationDocumentsDirectory();
      }

      if (downloadsDirectory != null) {
        final fileName = 'historial_solicitudes_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${downloadsDirectory.path}/$fileName');
        
        final pdfBytes = await pdf.save();
        await file.writeAsBytes(pdfBytes);

        // Mostrar diálogo de confirmación
        _mostrarDialogoDescarga(context, file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar PDF: $e')),
      );
    }
  }

  void _mostrarDialogoDescarga(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF15212c),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Descarga Exitosa',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'El PDF se ha descargado correctamente.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(); // Cerrar preview
                await OpenFile.open(filePath); // Abrir PDF
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Abrir', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF15212c).withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            const Text(
              'PREVIEW DEL PDF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado del PDF
                      const Text(
                        'HISTORIAL DE SOLICITUDES RESUELTAS',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clínica: $clinicaNombre',
                        style: const TextStyle(color: Colors.black87, fontSize: 12),
                      ),
                      Text(
                        'RUC: $clinicaRuc',
                        style: const TextStyle(color: Colors.black87, fontSize: 12),
                      ),
                      Text(
                        'Fecha de generación: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                        style: const TextStyle(color: Colors.black87, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tabla de datos
                      Table(
                        border: TableBorder.all(color: const Color.fromARGB(255, 0, 0, 0)),
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(3),
                          3: FlexColumnWidth(1.5),
                          4: FlexColumnWidth(1.5),
                        },
                        children: [
                          // Encabezados
                          const TableRow(
                            decoration: BoxDecoration(color: Colors.grey),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Prioridad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                              ),
                            ],
                          ),
                          // Datos
                          ...historial.map((s) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text('#${s['id']}', style: const TextStyle(fontSize: 9)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(_fmtFecha(s['fecha_creacion']), style: const TextStyle(fontSize: 9)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  (s['descripcion'] ?? '').toString().length > 30 
                                      ? '${(s['descripcion'] ?? '').toString().substring(0, 30)}...'
                                      : (s['descripcion'] ?? '').toString(),
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(s['estado']?.toString().toUpperCase() ?? '', style: const TextStyle(fontSize: 9)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(s['prioridad']?.toString() ?? '', style: const TextStyle(fontSize: 9)),
                              ),
                            ],
                          )).toList(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white70),
                    label: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _descargarPDF(context),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text('Descargar', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
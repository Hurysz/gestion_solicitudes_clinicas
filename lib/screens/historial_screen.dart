import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'order_detail_overlay.dart';

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
    await OrderDetailOverlay.show(
      context,
      solicitud: s,
      onClose: () {},
    );
  }

  Future<void> _exportarPDF() async {
    if (historial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay solicitudes resueltas para exportar.')),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Historial de Solicitudes Resueltas',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 12),
              headers: ['ID', 'Fecha', 'Descripción'],
              data: historial.map((s) {
                return [
                  s['id'].toString(),
                  _fmtFecha(s['fecha_creacion']),
                  s['descripcion'] ?? '',
                ];
              }).toList(),
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/Historial_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF233550),
        title: const Text('PDF Exportado',
            style: TextStyle(color: Color(0xFFee763d))),
        content: Text('Guardado en:\n$filePath',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri.file(file.path);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            child: const Text('Abrir',
                style: TextStyle(color: Color(0xFFee763d))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar',
                style: TextStyle(color: Color(0xFFee763d))),
          ),
        ],
      ),
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
                    onPressed: _exportarPDF,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFee763d),
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


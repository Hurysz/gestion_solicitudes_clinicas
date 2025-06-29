import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart'; // 👈 Asegúrate de agregar en pubspec.yaml
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
    cargarHistorial();
  }

  Future<void> cargarHistorial() async {
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

  String formatFecha(String fechaISO) {
    final date = DateTime.parse(fechaISO);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void mostrarDetalle(Map<String, dynamic> solicitud) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A38),
        title: Text(
          'Solicitud #${solicitud['id']}',
          style: const TextStyle(color: Colors.orange),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fecha resuelta: ${formatFecha(solicitud['fecha_creacion'])}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                'Descripción:',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                solicitud['descripcion'] ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                'Comentario del Administrador:',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                solicitud['comentario'] ?? 'Sin comentario',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> exportarPDF() async {
    if (historial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay solicitudes resueltas para exportar.')),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Historial de Solicitudes Resueltas',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12),
                headers: ['ID', 'Fecha', 'Descripción', 'Estado'],
                data: historial.map((s) {
                  return [
                    s['id'].toString(),
                    formatFecha(s['fecha_creacion']),
                    s['descripcion'] ?? '',
                    s['estado'] ?? '',
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getExternalStorageDirectory();
    final path = '${directory!.path}/Historial_Clinica_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF guardado en: $path')),
    );

    // Abre el archivo
    await OpenFile.open(file.path);

    // Y opcional: compartir
    Share.shareXFiles([XFile(file.path)], text: 'Historial de Solicitudes PDF');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2A38),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                backgroundColor: Colors.orange,
                radius: 20,
                child: Icon(Icons.local_hospital,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Portal Clínica',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.nombre,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: logout,
                icon: const Icon(Icons.logout, color: Colors.orange),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // TITLE + EXPORT BUTTON
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HISTORIAL DE SOLICITUDES',
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: exportarPDF,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'Exportar PDF',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: Colors.white10,
            child: Row(
              children: const [
                Expanded(
                    flex: 2,
                    child: Text(
                      'ID',
                      style: TextStyle(color: Colors.white70),
                    )),
                Expanded(
                    flex: 3,
                    child: Text(
                      'Fecha',
                      style: TextStyle(color: Colors.white70),
                    )),
                Expanded(
                    flex: 3,
                    child: Text(
                      'Estado',
                      style: TextStyle(color: Colors.white70),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: cargando
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange))
                : historial.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay solicitudes resueltas aún',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: historial.length,
                        itemBuilder: (context, index) {
                          final solicitud = historial[index];
                          return InkWell(
                            onTap: () => mostrarDetalle(solicitud),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '#${solicitud['id']}',
                                      style: const TextStyle(
                                          color: Colors.white),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      formatFecha(
                                          solicitud['fecha_creacion']),
                                      style: const TextStyle(
                                          color: Colors.white70),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 3,
                                    child: Text(
                                      'resuelto',
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold),
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
    );
  }
}

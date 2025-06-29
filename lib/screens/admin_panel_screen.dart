import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String? clinicaSeleccionada = 'Todos';
  String? estadoSeleccionado = 'Todos';
  String? fechaSeleccionada = 'Todos';

  List<dynamic> listaClinicas = [];
  List<dynamic> solicitudes = [];

  int total = 0;
  int resueltas = 0;
  int enProceso = 0;
  int pendientes = 0;

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarClinicas();
    cargarSolicitudes();
  }

  Future<void> cargarClinicas() async {
    final response = await SupabaseService.client
        .from('clinicas')
        .select('ruc, nombre');
    setState(() {
      listaClinicas = response;
    });
  }

  Future<void> cargarSolicitudes() async {
    setState(() => cargando = true);

    var query = SupabaseService.client
        .from('solicitudes')
        .select('*, clinicas(nombre)');

    if (clinicaSeleccionada != null && clinicaSeleccionada != 'Todos') {
      query = query.eq('ruc_clinica', clinicaSeleccionada);
    }
    if (estadoSeleccionado != null && estadoSeleccionado != 'Todos') {
      query = query.eq('estado', estadoSeleccionado);
    } else {
      // Si NO se filtra por resuelto, NO muestres resueltos
      query = query.neq('estado', 'resuelto');
    }
    if (fechaSeleccionada != null && fechaSeleccionada != 'Todos') {
      final now = DateTime.now();
      DateTime desde;
      if (fechaSeleccionada == 'hoy') {
        desde = DateTime(now.year, now.month, now.day);
      } else if (fechaSeleccionada == 'últimos 7 días') {
        desde = now.subtract(const Duration(days: 7));
      } else {
        desde = DateTime(now.year, now.month, 1);
      }
      query = query.gte('fecha_creacion', desde.toIso8601String());
    }

    final response = await query.order('fecha_creacion', ascending: false);

    int totalCount = response.length;
    int resueltasCount =
        response.where((s) => s['estado'] == 'resuelto').length;
    int procesoCount =
        response.where((s) => s['estado'] == 'en proceso').length;
    int pendientesCount =
        response.where((s) => s['estado'] == 'pendiente').length;

    setState(() {
      solicitudes = response;
      total = totalCount;
      resueltas = resueltasCount;
      enProceso = procesoCount;
      pendientes = pendientesCount;
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

  Future<void> _abrirArchivo(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el archivo.')),
      );
    }
  }

  void mostrarDetalle(Map<String, dynamic> solicitud) {
    final comentarioController =
        TextEditingController(text: solicitud['comentario'] ?? '');
    String estadoActual = solicitud['estado'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E2A38),
            title: Text(
              'Detalle #${solicitud['id']}',
              style: const TextStyle(color: Colors.orange),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Clínica: ${solicitud['clinicas']?['nombre'] ?? ''} (${solicitud['ruc_clinica']})',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  Text('Fecha: ${formatFecha(solicitud['fecha_creacion'])}',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  const Text(
                    'Descripción:',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text('${solicitud['descripcion'] ?? ''}',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  const Text('Estado:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: estadoActual,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(color: Colors.white),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                          value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(
                          value: 'en proceso', child: Text('En proceso')),
                      DropdownMenuItem(
                          value: 'resuelto', child: Text('Resuelto')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => estadoActual = value);
                      }
                    },
                  ),
                  Text('Prioridad: ${solicitud['prioridad']}',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 6),
                  if (solicitud['archivo_url'] != null)
                    InkWell(
                      onTap: () {
                        _abrirArchivo(solicitud['archivo_url']);
                      },
                      child: const Text('Descargar archivo',
                          style: TextStyle(
                              color: Colors.orange,
                              decoration: TextDecoration.underline)),
                    ),
                  const SizedBox(height: 10),
                  const Text('Comentario:',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  TextField(
                    controller: comentarioController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  if (estadoActual == 'resuelto' &&
                      comentarioController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Debes escribir un comentario para marcar como resuelto.')),
                    );
                    return;
                  }
                  await SupabaseService.client
                      .from('solicitudes')
                      .update({
                        'estado': estadoActual,
                        'comentario': comentarioController.text.trim(),
                      })
                      .eq('id', solicitud['id']);
                  Navigator.pop(context);
                  cargarSolicitudes();
                },
                child: const Text('Guardar',
                    style: TextStyle(color: Colors.orange)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar',
                    style: TextStyle(color: Colors.orange)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A38),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ENCABEZADO
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.orange,
                  radius: 20,
                  child: Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Portal Administrador TI',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text('Gestión de solicitudes',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
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
            const Text('SOLICITUDES',
                style: TextStyle(
                    color: Colors.orange,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text('Total: $total')),
                Chip(label: Text('Resueltas: $resueltas')),
                Chip(label: Text('En proceso: $enProceso')),
                Chip(label: Text('Pendientes: $pendientes')),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: clinicaSeleccionada,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Clínica',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: 'Todos', child: Text('Todas')),
                      ...listaClinicas.map((c) => DropdownMenuItem(
                          value: c['ruc'], child: Text(c['nombre']))),
                    ],
                    onChanged: (value) {
                      setState(() => clinicaSeleccionada = value);
                      cargarSolicitudes();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: estadoSeleccionado,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(
                          value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(
                          value: 'en proceso', child: Text('En proceso')),
                      DropdownMenuItem(value: 'resuelto', child: Text('Resuelto')),
                    ],
                    onChanged: (value) {
                      setState(() => estadoSeleccionado = value);
                      cargarSolicitudes();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: fechaSeleccionada,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'hoy', child: Text('Hoy')),
                      DropdownMenuItem(
                          value: 'últimos 7 días', child: Text('Últimos 7 días')),
                      DropdownMenuItem(
                          value: 'este mes', child: Text('Este mes')),
                    ],
                    onChanged: (value) {
                      setState(() => fechaSeleccionada = value);
                      cargarSolicitudes();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: cargando
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange))
                  : ListView.builder(
                      itemCount: solicitudes.length,
                      itemBuilder: (context, index) {
                        final solicitud = solicitudes[index];
                        return Card(
                          color: Colors.white10,
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: InkWell(
                            onTap: () => mostrarDetalle(solicitud),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    solicitud['clinicas']?['nombre'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('#${solicitud['id']}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatFecha(solicitud['fecha_creacion']),
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(solicitud['descripcion'] ?? '',
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Prioridad: ${solicitud['prioridad'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.white70)),
                                ],
                              ),
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

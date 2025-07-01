import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestListScreen extends StatefulWidget {
  final String ruc;
  final String nombre;

  const RequestListScreen({
    super.key,
    required this.ruc,
    required this.nombre,
  });

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  String estadoSeleccionado = 'Todos';
  String prioridadSeleccionada = 'Todos';
  String fechaSeleccionada = 'Todos';

  List<dynamic> solicitudes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarSolicitudes();
  }

  Future<void> cargarSolicitudes() async {
    setState(() => cargando = true);

    var query = SupabaseService.client
        .from('solicitudes')
        .select()
        .eq('ruc_clinica', widget.ruc);

    if (estadoSeleccionado != 'Todos') {
      query = query.eq('estado', estadoSeleccionado);
    }
    if (prioridadSeleccionada != 'Todos') {
      query = query.eq('prioridad', prioridadSeleccionada);
    }
    if (fechaSeleccionada != 'Todos') {
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

    setState(() {
      solicitudes = response;
      cargando = false;
    });
  }

  void reiniciarFiltros() {
    setState(() {
      estadoSeleccionado = 'Todos';
      prioridadSeleccionada = 'Todos';
      fechaSeleccionada = 'Todos';
    });
    cargarSolicitudes();
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
                'Fecha: ${formatFecha(solicitud['fecha_creacion'])}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                'Descripción:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                solicitud['descripcion'] ?? '',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                'Estado: ${solicitud['estado']}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Prioridad: ${solicitud['prioridad']}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              if (solicitud['archivo_url'] != null &&
                  solicitud['archivo_url'].toString().isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    final url = solicitud['archivo_url'] as String;

                    // ✅ Abre visor interno (WebView) en Android
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VisorArchivoScreen(url: url),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download, color: Colors.orange),
                  label: const Text(
                    'Abrir archivo adjunto',
                    style: TextStyle(
                      color: Colors.orange,
                      decoration: TextDecoration.underline,
                    ),
                  ),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2A38),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.orange,
                radius: 20,
                child: Icon(Icons.local_hospital, color: Colors.white, size: 20),
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
          const Text(
            'MIS SOLICITUDES',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
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
                    DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                    DropdownMenuItem(value: 'en proceso', child: Text('En proceso')),
                    DropdownMenuItem(value: 'resuelto', child: Text('Resuelto')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => estadoSeleccionado = value);
                      cargarSolicitudes();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: prioridadSeleccionada,
                  dropdownColor: Colors.black87,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Prioridad',
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'Alta', child: Text('Alta')),
                    DropdownMenuItem(value: 'Media', child: Text('Media')),
                    DropdownMenuItem(value: 'Baja', child: Text('Baja')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => prioridadSeleccionada = value);
                      cargarSolicitudes();
                    }
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
                    DropdownMenuItem(value: 'este mes', child: Text('Este mes')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => fechaSeleccionada = value);
                      cargarSolicitudes();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: reiniciarFiltros,
              icon: const Icon(Icons.refresh, color: Colors.orange),
              label: const Text(
                'Reiniciar filtros',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: cargando
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : solicitudes.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay solicitudes aún',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: solicitudes.length,
                        itemBuilder: (context, index) {
                          final solicitud = solicitudes[index];
                          return Card(
                            color: Colors.white10,
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                '#${solicitud['id']}',
                                style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fecha: ${formatFecha(solicitud['fecha_creacion'])}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    solicitud['descripcion'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    solicitud['estado'],
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Prioridad: ${solicitud['prioridad']}',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              onTap: () => mostrarDetalle(solicitud),
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

/// ✅ Pantalla visor WebView interna
class VisorArchivoScreen extends StatefulWidget {
  final String url;

  const VisorArchivoScreen({super.key, required this.url});

  @override
  State<VisorArchivoScreen> createState() => _VisorArchivoScreenState();
}

class _VisorArchivoScreenState extends State<VisorArchivoScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ver archivo'),
        backgroundColor: Colors.orange,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

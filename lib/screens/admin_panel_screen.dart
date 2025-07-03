import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:ui';
import '../services/supabase_service.dart';
import 'login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String clinicaSeleccionada = 'Todos';
  String estadoSeleccionado = 'Todos';
  String fechaSeleccionada = 'Todos';

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
    final response =
        await SupabaseService.client.from('clinicas').select('ruc, nombre');
    setState(() {
      listaClinicas = response;
    });
  }

  Future<void> cargarSolicitudes() async {
    setState(() => cargando = true);

    var query = SupabaseService.client
        .from('solicitudes')
        .select('*, clinicas(nombre)');

    if (clinicaSeleccionada != 'Todos') {
      query = query.eq('ruc_clinica', clinicaSeleccionada);
    }
    if (estadoSeleccionado != 'Todos') {
      query = query.eq('estado', estadoSeleccionado);
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

  void mostrarDetalle(Map<String, dynamic> solicitud) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'DetalleSolicitud',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, _) {
        final curved = Curves.easeOut.transform(anim1.value);
        return Opacity(
          opacity: curved,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10 * curved, sigmaY: 10 * curved),
            child: Center(
              child: _DetalleModal(solicitud: solicitud, onUpdate: cargarSolicitudes),
            ),
          ),
        );
      },
    );
  }

  Widget buildStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15212c),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2c4a6b).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFee763d),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        'assets/admin1.png',
                        width: 20,
                        height: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Portal Administrador TI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: logout,
                      child: Image.asset(
                        'assets/logout.png',
                        width: 20,
                        height: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildStatCard('Total', total, const Color(0xFF7c3aed)),
                  buildStatCard('Proceso', enProceso, const Color(0xFFf59e0b)),
                  buildStatCard('Resueltas', resueltas, const Color(0xFF10b981)),
                  buildStatCard('Pendientes', pendientes, const Color(0xFFef4444)),
                ],
              ),
              const SizedBox(height: 16),

              // Filters
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Clínica',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildDropdown(
                              value: clinicaSeleccionada,
                              label: 'Clínicas',
                              items: [
                                const DropdownMenuItem(value: 'Todos', child: Text('Todas')),
                                ...listaClinicas.map((c) => DropdownMenuItem(
                                    value: c['ruc'], child: Text(c['nombre']))),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => clinicaSeleccionada = value);
                                  cargarSolicitudes();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildDropdown(
                              value: estadoSeleccionado,
                              label: 'Estados',
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fecha',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildDropdown(
                              value: fechaSeleccionada,
                              label: 'Fecha',
                              items: const [
                                DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                                DropdownMenuItem(value: 'hoy', child: Text('Hoy')),
                                DropdownMenuItem(value: 'últimos 7 días', child: Text('Últimos 7 días')),
                                DropdownMenuItem(value: 'este mes', child: Text('Este mes')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => fechaSeleccionada = value);
                                  cargarSolicitudes();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Reset Filters Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      clinicaSeleccionada = 'Todos';
                      estadoSeleccionado = 'Todos';
                      fechaSeleccionada = 'Todos';
                    });
                    cargarSolicitudes();
                  },
                  icon: const Icon(Icons.refresh, color: Color(0xFFee763d), size: 16),
                  label: const Text(
                    'REINICIAR FILTROS',
                    style: TextStyle(color: Color(0xFFee763d), fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Solicitudes Header
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SOLICITUDES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: cargando
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFee763d)))
                    : solicitudes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/gato.png', height: 120),
                                const SizedBox(height: 16),
                                const Text(
                                  'Todo tranquilo por ahora',
                                  style: TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: solicitudes.length,
                            itemBuilder: (context, index) {
                              final solicitud = solicitudes[index];
                              return _buildSolicitudCard(solicitud);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF15212c),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          hint: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSolicitudCard(Map<String, dynamic> solicitud) {
    Color estadoColor;
    switch (solicitud['estado']) {
      case 'resuelto':
        estadoColor = const Color(0xFF10b981);
        break;
      case 'en proceso':
        estadoColor = const Color(0xFFf59e0b);
        break;
      default:
        estadoColor = const Color(0xFFef4444);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2c4a6b).withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => mostrarDetalle(solicitud),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    solicitud['clinicas']?['nombre'] ?? '',
                    style: const TextStyle(
                      color: Color(0xFFee763d),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: estadoColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      solicitud['estado'].toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '#${solicitud['id']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatFecha(solicitud['fecha_creacion']),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                solicitud['descripcion'] ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      solicitud['prioridad'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalleModal extends StatefulWidget {
  final Map<String, dynamic> solicitud;
  final VoidCallback onUpdate;

  const _DetalleModal({required this.solicitud, required this.onUpdate});

  @override
  State<_DetalleModal> createState() => _DetalleModalState();
}

class _DetalleModalState extends State<_DetalleModal> {
  late TextEditingController comentarioController;
  late String estadoActual;

  @override
  void initState() {
    super.initState();
    comentarioController = TextEditingController(text: widget.solicitud['comentario'] ?? '');
    estadoActual = widget.solicitud['estado'];
  }

  String formatFecha(String fechaISO) {
    final date = DateTime.parse(fechaISO);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
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
                'SOLICITUD #${widget.solicitud['id']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildInfoRow('Clínica:', '${widget.solicitud['clinicas']?['nombre'] ?? ''} (${widget.solicitud['ruc_clinica']})'),
              const SizedBox(height: 8),
              _buildInfoRow('Fecha:', formatFecha(widget.solicitud['fecha_creacion'])),
              const SizedBox(height: 12),
              
              const Text(
                'DESCRIPCIÓN:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                widget.solicitud['descripcion'] ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              
              const Text(
                'ESTADO:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: estadoActual,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF15212c),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'en proceso', child: Text('En proceso')),
                      DropdownMenuItem(value: 'resuelto', child: Text('Resuelto')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => estadoActual = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Prioridad:', widget.solicitud['prioridad']),
              const SizedBox(height: 12),
              
              if (widget.solicitud['archivo_url'] != null && widget.solicitud['archivo_url'].toString().isNotEmpty)
                Container(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      final url = widget.solicitud['archivo_url'] as String;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VisorArchivoScreen(url: url)),
                      );
                    },
                    icon: const Icon(Icons.download, color: Color(0xFFee763d), size: 16),
                    label: const Text(
                      'DESCARGAR ARCHIVO ADJUNTO',
                      style: TextStyle(color: Color(0xFFee763d), fontSize: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              
              const Text(
                'COMENTARIO:',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: TextField(
                  controller: comentarioController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Deja un comentario cómo administrador...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (estadoActual == 'resuelto' && comentarioController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Debes escribir un comentario para marcar como resuelto.'),
                            ),
                          );
                          return;
                        }
                        await SupabaseService.client.from('solicitudes').update({
                          'estado': estadoActual,
                          'comentario': comentarioController.text.trim(),
                        }).eq('id', widget.solicitud['id']);
                        
                        Navigator.pop(context);
                        widget.onUpdate();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFee763d),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFee763d)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cerrar', style: TextStyle(color: Color(0xFFee763d))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

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
        backgroundColor: const Color(0xFFee763d),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';

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
  String estado = 'Todos';
  String prioridad = 'Todos';
  String fecha = 'Todos';
  List<dynamic> solicitudes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => cargando = true);
    var query = SupabaseService.client
        .from('solicitudes')
        .select()
        .eq('ruc_clinica', widget.ruc);

    if (estado != 'Todos') query = query.eq('estado', estado);
    if (prioridad != 'Todos') query = query.eq('prioridad', prioridad);
    if (fecha != 'Todos') {
      final now = DateTime.now();
      DateTime desde;
      if (fecha == 'Hoy') {
        desde = DateTime(now.year, now.month, now.day);
      } else if (fecha == 'Últimos 7 días') {
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

  void _resetFiltros() {
    setState(() {
      estado = 'Todos';
      prioridad = 'Todos';
      fecha = 'Todos';
    });
    _cargarSolicitudes();
  }

  String _formatFecha(String iso) {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _selectFiltro(String title, List<String> opciones, String seleccionado, void Function(String) onSelect) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF233550),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: opciones.map((opt) {
          final isSel = opt == seleccionado;
          return ListTile(
            title: Text(
              opt,
              style: TextStyle(
                color: isSel ? const Color(0xFFee763d) : Colors.white,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () {
              onSelect(opt);
              Navigator.pop(context);
              _cargarSolicitudes();
            },
          );
        }).toList(),
      ),
    );
  }

  void _showDetalle(Map<String, dynamic> solicitud) {
    showGeneralDialog(
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
              child: _DetailCard(solicitud: solicitud),
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
                        const Text(
                          'Portal Clínica',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.nombre.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFee763d),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _logout,
                    child: Image.asset('assets/logout.png', width: 24, height: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // TÍTULO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: const Text(
                  'MIS SOLICITUDES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // FILTROS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterButtonWithLabel(
                    title: 'Estado',
                    label: estado,
                    onTap: () => _selectFiltro(
                      'Estado',
                      ['Todos', 'pendiente', 'en proceso', 'resuelto'],
                      estado,
                      (v) => setState(() => estado = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterButtonWithLabel(
                    title: 'Prioridad',
                    label: prioridad,
                    onTap: () => _selectFiltro(
                      'Prioridad',
                      ['Todos', 'Alta', 'Media', 'Baja'],
                      prioridad,
                      (v) => setState(() => prioridad = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterButtonWithLabel(
                    title: 'Fecha',
                    label: fecha,
                    onTap: () => _selectFiltro(
                      'Fecha',
                      ['Todos', 'Hoy', 'Últimos 7 días', 'Este mes'],
                      fecha,
                      (v) => setState(() => fecha = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    alignment: Alignment.bottomCenter,
                    height: 60,
                    child: GestureDetector(
                      onTap: _resetFiltros,
                      child: const Icon(Icons.refresh, color: Color(0xFFee763d), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // LISTADO
            Expanded(
              child: cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFFee763d)),
                      ),
                    )
                  : solicitudes.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay solicitudes aún',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: solicitudes.length,
                          itemBuilder: (_, i) {
                            final s = solicitudes[i];
                            return GestureDetector(
                              onTap: () => _showDetalle(s),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E3B53),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  title: Text(
                                    '#${s['id']}',
                                    style: const TextStyle(
                                      color: Color(0xFFee763d),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s['descripcion'] != null 
                                          ? (s['descripcion'].length > 50 
                                              ? '${s['descripcion'].substring(0, 50)}...' 
                                              : s['descripcion'])
                                          : 'Sin descripción',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatFecha(s['fecha_creacion']),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _estadoColor(s['estado']),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          s['estado'].toUpperCase(),
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 10),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        s['prioridad'],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
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

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.yellow.shade700;
      case 'en proceso':
        return Colors.blue.shade600;
      default:
        return Colors.green.shade600;
    }
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2E3B53),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              const Icon(Icons.keyboard_arrow_down,
                  size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButtonWithLabel extends StatelessWidget {
  final String title;
  final String label;
  final VoidCallback onTap;
  const _FilterButtonWithLabel({
    required this.title,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2E3B53),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  const _DetailCard({required this.solicitud});

  String _formatFecha(String iso) {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
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
              if (solicitud['archivo_url'] != null && solicitud['archivo_url'].toString().isNotEmpty)
                Container(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      final url = solicitud['archivo_url'] as String;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => VisorArchivoScreen(url: url)),
                      );
                    },
                    icon: const Icon(Icons.visibility, color: Color(0xFFee763d), size: 16),
                    label: const Text(
                      'VER ARCHIVO ADJUNTO',
                      style: TextStyle(color: Color(0xFFee763d), fontSize: 12),
                    ),
                  ),
                ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(width: 6),
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

// Nueva clase para visualizar archivos
class VisorArchivoScreen extends StatefulWidget {
  final String url;
  
  const VisorArchivoScreen({super.key, required this.url});

  @override
  State<VisorArchivoScreen> createState() => _VisorArchivoScreenState();
}

class _VisorArchivoScreenState extends State<VisorArchivoScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF233550),
      appBar: AppBar(
        backgroundColor: const Color(0xFF233550),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Archivo Adjunto',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFee763d)),
              ),
            ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'order_detail_overlay.dart';

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

  Future<void> _selectFiltro(
    String title,
    List<String> opciones,
    String seleccionado,
    void Function(String) onSelect,
  ) {
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
                  _FilterButton(
                    label: estado,
                    onTap: () => _selectFiltro(
                      'Estado',
                      ['Todos', 'pendiente', 'en proceso', 'resuelto'],
                      estado,
                      (v) => setState(() => estado = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    label: prioridad,
                    onTap: () => _selectFiltro(
                      'Prioridad',
                      ['Todos', 'Alta', 'Media', 'Baja'],
                      prioridad,
                      (v) => setState(() => prioridad = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    label: fecha,
                    onTap: () => _selectFiltro(
                      'Fecha',
                      ['Todos', 'Hoy', 'Últimos 7 días', 'Este mes'],
                      fecha,
                      (v) => setState(() => fecha = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _resetFiltros,
                    child: const Icon(Icons.refresh, color: Color(0xFFee763d)),
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
                              onTap: () {
                                OrderDetailOverlay.show(
                                  context,
                                  solicitud: s,
                                  onClose: () {},
                                );
                              },
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
                                  subtitle: Text(
                                    _formatFecha(s['fecha_creacion']),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
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

class _VisorArchivoScreen extends StatefulWidget {
  final String url;
  const _VisorArchivoScreen({required this.url, super.key});

  @override
  State<_VisorArchivoScreen> createState() => _VisorArchivoScreenState();
}

class _VisorArchivoScreenState extends State<_VisorArchivoScreen> {
  late final WebViewController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF233550),
      appBar: AppBar(
        backgroundColor: const Color(0xFFee763d),
        title: const Text('Ver archivo'),
      ),
      body: WebViewWidget(controller: _ctrl),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../services/supabase_service.dart';
import 'login_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  final String ruc;
  final String nombre;

  const CreateRequestScreen({
    super.key,
    required this.ruc,
    required this.nombre,
  });

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final descripcionController = TextEditingController();
  String prioridad = 'Media';
  PlatformFile? archivoSeleccionado;
  bool enviando = false;

  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> seleccionarArchivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null && result.files.single.size <= 10 * 1024 * 1024) {
      setState(() => archivoSeleccionado = result.files.single);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Archivo inválido o demasiado grande (>10MB)')),
      );
    }
  }

  Future<void> enviarSolicitud() async {
    if (descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, describe tu solicitud')),
      );
      return;
    }
    setState(() => enviando = true);

    String? archivoUrl;
    try {
      if (archivoSeleccionado != null && archivoSeleccionado!.bytes != null) {
        final ext = path.extension(archivoSeleccionado!.name);
        final filePath =
            'archivos/${DateTime.now().millisecondsSinceEpoch}$ext';
        await SupabaseService.client.storage
            .from('solicitudesarchivos')
            .uploadBinary(filePath, archivoSeleccionado!.bytes!);
        archivoUrl = SupabaseService.client.storage
            .from('solicitudesarchivos')
            .getPublicUrl(filePath);
      }

      await SupabaseService.client.from('solicitudes').insert({
        'ruc_clinica': widget.ruc,
        'descripcion': descripcionController.text.trim(),
        'prioridad': prioridad,
        'estado': 'pendiente',
        'fecha_creacion': DateTime.now().toIso8601String(),
        'archivo_url': archivoUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada con éxito')),
      );
      descripcionController.clear();
      archivoSeleccionado = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => enviando = false);
    }
  }

  void _mostrarSelectorPrioridad() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF233550),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Alta', 'Media', 'Baja'].map((opcion) {
          final seleccionado = opcion == prioridad;
          return ListTile(
            title: Text(
              opcion,
              style: TextStyle(
                color: seleccionado
                    ? const Color(0xFFee763d)
                    : const Color(0xFF919aa8),
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            onTap: () {
              setState(() => prioridad = opcion);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF233550), // fondo #233550
      child: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    onTap: logout,
                    child:
                        Image.asset('assets/logout.png', width: 24, height: 24),
                  ),
                ],
              ),
            ),

            // --- FORMULARIO ---
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'CREAR SOLICITUD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextField(
                      controller: descripcionController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            const Color(0xFF919aa8).withOpacity(0.2),
                        hintText:
                            'Describe detalladamente el problema o solicitud...',
                        hintStyle:
                            const TextStyle(color: Color.fromARGB(171, 255, 255, 255)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Prioridad (custom)
                    GestureDetector(
                      onTap: _mostrarSelectorPrioridad,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF919aa8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              prioridad,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                            Icon(Icons.keyboard_arrow_down,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selección de archivo
                    GestureDetector(
                      onTap: seleccionarArchivo,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF919aa8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            Image.asset('assets/upload.png',
                                width: 40, height: 40, color: Colors.black54),
                            const SizedBox(height: 8),
                            Text(
                              archivoSeleccionado != null
                                  ? archivoSeleccionado!.name
                                  : 'Arrastra archivos aquí o haz clic para seleccionar PDF, DOC, IMG hasta 10MB',
                              style: const TextStyle(
                                  color:
                                      Color.fromARGB(176, 255, 255, 255),
                                  fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón enviar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: enviando ? null : enviarSolicitud,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFee763d),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          enviando ? 'ENVIANDO...' : 'ENVIAR SOLICITUD',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

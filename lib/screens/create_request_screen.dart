import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../services/supabase_service.dart';
import 'login_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  final String ruc;
  final String nombre;

  const CreateRequestScreen({
    required this.ruc,
    required this.nombre,
    super.key,
  });

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  String? prioridad = 'Media';
  final descripcionController = TextEditingController();
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
      setState(() {
        archivoSeleccionado = result.files.single;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Archivo inválido o muy pesado (>10MB)')),
      );
    }
  }

  Future<void> enviarSolicitud() async {
    final descripcion = descripcionController.text.trim();
    if (descripcion.isEmpty || prioridad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa la descripción y prioridad')),
      );
      return;
    }

    setState(() => enviando = true);
    String? archivoUrl;

    try {
      // Subida del archivo
      if (archivoSeleccionado != null && archivoSeleccionado!.bytes != null) {
        final fileExt = path.extension(archivoSeleccionado!.name);
        final filePath =
            'archivos/${DateTime.now().millisecondsSinceEpoch}$fileExt';

        await SupabaseService.client.storage
            .from('solicitudesarchivos')
            .uploadBinary(
              filePath,
              archivoSeleccionado!.bytes!,
            );

        archivoUrl = SupabaseService.client.storage
            .from('solicitudesarchivos')
            .getPublicUrl(filePath);
      }

      // Inserción en la tabla solicitudes
      final data = {
        'ruc_clinica': widget.ruc,
        'descripcion': descripcion,
        'prioridad': prioridad,
        'estado': 'pendiente',
        'fecha_creacion': DateTime.now().toIso8601String(),
        'archivo_url': archivoUrl,
      };

      await SupabaseService.client.from('solicitudes').insert(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Solicitud enviada con éxito')),
      );

      descripcionController.clear();
      archivoSeleccionado = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: ${e.toString()}')),
      );
    } finally {
      setState(() => enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2A38),
      padding: const EdgeInsets.all(20.0),
      child: ListView(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                    const Text('Portal Clínica',
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text(widget.nombre,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
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
          const Text('CREAR SOLICITUD',
              style: TextStyle(
                  color: Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          TextField(
            controller: descripcionController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              filled: true,
              fillColor: Colors.white10,
              hintText: 'Describa el problema...',
              hintStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: prioridad,
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
              DropdownMenuItem(value: 'Alta', child: Text('Alta')),
              DropdownMenuItem(value: 'Media', child: Text('Media')),
              DropdownMenuItem(value: 'Baja', child: Text('Baja')),
            ],
            onChanged: (value) => setState(() => prioridad = value),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: seleccionarArchivo,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white10,
              ),
              child: Text(
                archivoSeleccionado != null
                    ? 'Archivo: ${archivoSeleccionado!.name}'
                    : 'Haz clic para seleccionar archivo (PDF, DOC, IMG)',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: enviando ? null : enviarSolicitud,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text(
              enviando ? 'Enviando...' : 'ENVIAR SOLICITUD',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}

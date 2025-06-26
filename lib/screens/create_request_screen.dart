import 'package:flutter/material.dart';
import 'login_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  final String ruc;
  final String nombre;

  const CreateRequestScreen({required this.ruc, required this.nombre, super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  String? prioridad = 'Media';
  final descripcionController = TextEditingController();

  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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
              hintText: 'Describa el problema...'
                  ,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white10,
            ),
            child: const Text(
              'Arrastra archivos o haz clic para seleccionar\nPDF, DOC, IMG hasta 10MB',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('ENVIAR SOLICITUD',
                style: TextStyle(fontSize: 16, color: Colors.white)),
          )
        ],
      ),
    );
  }
}

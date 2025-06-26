import 'package:flutter/material.dart';
import 'login_screen.dart';

class RequestListScreen extends StatefulWidget {
  final String ruc;
  final String nombre;

  const RequestListScreen({super.key, required this.ruc, required this.nombre});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  String? estadoSeleccionado;
  String? fechaSeleccionada;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const Text('MIS SOLICITUDES',
              style: TextStyle(
                  color: Colors.orange,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
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
                    DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                    DropdownMenuItem(value: 'en proceso', child: Text('En proceso')),
                    DropdownMenuItem(value: 'resuelto', child: Text('Resuelto')),
                  ],
                  onChanged: (value) {
                    setState(() => estadoSeleccionado = value);
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
                    DropdownMenuItem(value: 'hoy', child: Text('Hoy')),
                    DropdownMenuItem(value: 'últimos 7 días', child: Text('Últimos 7 días')),
                    DropdownMenuItem(value: 'este mes', child: Text('Este mes')),
                  ],
                  onChanged: (value) {
                    setState(() => fechaSeleccionada = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Expanded(
            child: Column(
              children: [
                Card(
                  color: Colors.white10,
                  margin: EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    title: Text('Error en sistema de ventas',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text('Prioridad: Alta\nEstado: pendiente',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
                Card(
                  color: Colors.white10,
                  margin: EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    title: Text('No imprime reporte médico',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text('Prioridad: Media\nEstado: en proceso',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

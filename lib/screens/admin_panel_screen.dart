import 'package:flutter/material.dart';
import 'login_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  void logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.orange,
                  radius: 20,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
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
                  onPressed: () => logout(context),
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text('Total: 4')),
                Chip(label: Text('Resueltas: 1')),
                Chip(label: Text('En proceso: 1')),
                Chip(label: Text('Pendientes: 2')),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: null,
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
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: null,
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
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.white10,
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF1E2A38),
                            title: const Text('Detalle de solicitud', style: TextStyle(color: Colors.white)),
                            content: const Text(
                              'Sistema de facturación no responde.\nPrioridad: Alta\nEstado: Pendiente\nFecha: 2025-06-25 10:24',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar', style: TextStyle(color: Colors.orange)),
                              )
                            ],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('#001', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 5),
                                  Text('2025-06-25 10:24', style: TextStyle(color: Colors.white70)),
                                  SizedBox(height: 5),
                                  Text('Sistema de facturación no responde.', style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  DropdownButton<String>(
                                    value: 'pendiente',
                                    dropdownColor: Colors.black87,
                                    style: const TextStyle(color: Colors.white),
                                    underline: const SizedBox(),
                                    items: const [
                                      DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                                      DropdownMenuItem(value: 'en proceso', child: Text('En proceso')),
                                      DropdownMenuItem(value: 'resuelto', child: Text('Resuelto')),
                                    ],
                                    onChanged: (value) {},
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Prioridad: Alta', style: TextStyle(color: Colors.white70)),
                                ],
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
}
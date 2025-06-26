import 'package:flutter/material.dart';
import 'login_screen.dart';

class HistorialScreen extends StatelessWidget {
  final String nombre;

  const HistorialScreen({super.key, required this.nombre});

  void logout(BuildContext context) {
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
                    Text(nombre,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('HISTORIAL DE SOLICITUDES',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Exportar PDF',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: Colors.white10,
            child: Row(
              children: const [
                Expanded(
                    flex: 2,
                    child: Text('ID',
                        style: TextStyle(color: Colors.white70))),
                Expanded(
                    flex: 3,
                    child: Text('Fecha',
                        style: TextStyle(color: Colors.white70))),
                Expanded(
                    flex: 3,
                    child: Text('Estado',
                        style: TextStyle(color: Colors.white70))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              children: const [
                Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text('#001',
                              style: TextStyle(color: Colors.white))),
                      Expanded(
                          flex: 3,
                          child: Text('2025-06-24',
                              style: TextStyle(color: Colors.white70))),
                      Expanded(
                          flex: 3,
                          child: Text('resuelto',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text('#002',
                              style: TextStyle(color: Colors.white))),
                      Expanded(
                          flex: 3,
                          child: Text('2025-06-23',
                              style: TextStyle(color: Colors.white70))),
                      Expanded(
                          flex: 3,
                          child: Text('resuelto',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold))),
                    ],
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
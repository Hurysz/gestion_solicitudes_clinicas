// main_tab_screen.dart
import 'package:flutter/material.dart';
import 'create_request_screen.dart';
import 'request_list_screen.dart';
import 'historial_screen.dart';

class MainTabScreen extends StatefulWidget {
  final String ruc;
  final String nombre;

  const MainTabScreen({super.key, required this.ruc, required this.nombre});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CreateRequestScreen(ruc: widget.ruc, nombre: widget.nombre),
      RequestListScreen(ruc: widget.ruc, nombre: widget.nombre),
      HistorialScreen(nombre: widget.nombre),

    ];
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A38),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text('PORTAL CLÍNICA'),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.orange,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.create),
            label: 'Crear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Solicitudes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}

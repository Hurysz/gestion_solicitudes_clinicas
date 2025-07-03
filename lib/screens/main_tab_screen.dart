import 'package:flutter/material.dart';
import 'create_request_screen.dart';
import 'request_list_screen.dart';
import 'historial_screen.dart';

class MainTabScreen extends StatefulWidget {
  final String ruc;
  final String nombre;

  const MainTabScreen({
    super.key,
    required this.ruc,
    required this.nombre,
  });

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
      HistorialScreen(ruc: widget.ruc, nombre: widget.nombre),
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
      // Fondo uniforme igual a tu prototipo izquierdo
      backgroundColor: const Color(0xFF233550),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // fondo blanco
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, -1),
            )
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabItem(
                index: 0,
                icon: Icons.create,
                label: 'Crear',
              ),
              _buildTabItem(
                index: 1,
                icon: Icons.list,
                label: 'Solicitudes',
              ),
              _buildTabItem(
                index: 2,
                icon: Icons.history,
                label: 'Historial',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFee763d) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF919aa8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF919aa8),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

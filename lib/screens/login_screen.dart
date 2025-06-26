import 'dart:async';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'main_tab_screen.dart';
import 'admin_panel_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? rucInicial;
  final String? nombreInicial;

  const LoginScreen({super.key, this.rucInicial, this.nombreInicial});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final rucController = TextEditingController();
  final passwordController = TextEditingController();
  String nombreClinica = '';
  bool esAdmin = false;
  bool _obscurePassword = true;
  Timer? debounceTimer;

  final String rucAdmin = '12345678901';

  @override
  void initState() {
    super.initState();

    if (widget.rucInicial != null) {
      rucController.text = widget.rucInicial!;
      nombreClinica = widget.nombreInicial ?? '';
    }

    rucController.addListener(() {
      debounce(() {
        if (rucController.text.trim().isEmpty) {
          setState(() => nombreClinica = '');
        } else {
          consultarNombre(rucController.text.trim());
        }
      });
    });
  }

  void debounce(VoidCallback callback, {Duration duration = const Duration(milliseconds: 500)}) {
    debounceTimer?.cancel();
    debounceTimer = Timer(duration, callback);
  }

  Future<void> consultarNombre(String ruc) async {
    try {
      final response = await SupabaseService.client
          .from('clinicas')
          .select('nombre')
          .eq('ruc', ruc)
          .maybeSingle();

      setState(() {
        nombreClinica = response?['nombre'] ?? '';
      });
    } catch (e) {
      setState(() => nombreClinica = '');
    }
  }

  Future<void> login() async {
    final ruc = rucController.text.trim();
    final pass = passwordController.text.trim();

    if (ruc.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RUC y contraseña son obligatorios')),
      );
      return;
    }

    try {
      final response = await SupabaseService.client
          .from('clinicas')
          .select('nombre, password')
          .eq('ruc', ruc)
          .maybeSingle();

      if (response == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RUC no encontrado')),
        );
        return;
      }

      final nombre = response['nombre'];
      final passwordCorrecta = response['password'] == pass;

      // Reglas para login ADMIN
      if (esAdmin) {
        if (ruc != rucAdmin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Este RUC no tiene permisos de administrador')),
          );
          return;
        }

        if (!passwordCorrecta) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contraseña incorrecta')),
          );
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
        );
        return;
      }

      // Reglas para login CLÍNICA
      if (ruc == rucAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este RUC pertenece al administrador TI')),
        );
        return;
      }

      if (!passwordCorrecta) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña incorrecta')),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainTabScreen(ruc: ruc, nombre: nombre),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: ${e.toString()}')),
      );
    }
  }

  void toggleAdmin() {
    setState(() {
      esAdmin = !esAdmin;
      nombreClinica = '';
      passwordController.clear();
    });
  }

  @override
  void dispose() {
    debounceTimer?.cancel();
    rucController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color fondo = esAdmin ? const Color(0xFF111922) : const Color(0xFF1E2A38);
    final String titulo = esAdmin ? 'MODO ADMINISTRADOR' : 'INICIO DE SESIÓN';
    final Icon icono = esAdmin
        ? const Icon(Icons.admin_panel_settings, color: Colors.orange, size: 70)
        : const Icon(Icons.handshake, color: Colors.orange, size: 70);

    return Scaffold(
      backgroundColor: fondo,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                icono,
                const SizedBox(height: 30),
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: rucController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'RUC',
                    labelStyle: TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: Colors.white10,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(
                      esAdmin ? Icons.admin_panel_settings : Icons.local_hospital,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rucController.text.trim().isEmpty
                            ? ''
                            : nombreClinica.isNotEmpty
                                ? '${esAdmin ? "Cuenta:" : "Clínica:"} $nombreClinica'
                                : '${esAdmin ? "Cuenta" : "Clínica"} no encontrada',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: login,
                  child: const Text(
                    'INGRESAR',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: toggleAdmin,
                  child: Text(
                    esAdmin ? '← Volver a modo clínica' : '¿Eres administrador?',
                    style: const TextStyle(color: Colors.orange, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

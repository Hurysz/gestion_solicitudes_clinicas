import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool mantenerSesion = false;
  Timer? debounceTimer;

  final String rucAdmin = '12345678901';

  @override
  void initState() {
    super.initState();
    _cargarDatosGuardados();

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

  Future<void> _cargarDatosGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    final rucGuardado = prefs.getString('ruc_guardado');
    final mantenerGuardado = prefs.getBool('mantener_sesion') ?? false;
    
    if (mantenerGuardado && rucGuardado != null && rucGuardado.isNotEmpty) {
      setState(() {
        rucController.text = rucGuardado;
        mantenerSesion = true;
      });
      consultarNombre(rucGuardado);
    }
  }

  Future<void> _guardarDatos(String ruc) async {
    final prefs = await SharedPreferences.getInstance();
    if (mantenerSesion) {
      await prefs.setString('ruc_guardado', ruc);
      await prefs.setBool('mantener_sesion', true);
    } else {
      await prefs.remove('ruc_guardado');
      await prefs.setBool('mantener_sesion', false);
    }
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

        await _guardarDatos(ruc);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
        );
        return;
      }

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

      await _guardarDatos(ruc);
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
    final fondo1 = const Color(0xFF2e1b40);
    final fondo2 = esAdmin ? const Color(0xFF1f1a2c) : const Color(0xFF193b3f);
    final botonColor = const Color(0xFFEE763D);
    final textoColor = Colors.white;

    final icono = esAdmin ? 'assets/adminlogo.png' : 'assets/handhello.png';
    final titulo = esAdmin ? 'PORTAL ADMINISTRADOR' : 'PORTAL CLÍNICA';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [fondo1, fondo2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: SingleChildScrollView(
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 600,
            borderRadius: 25,
            blur: 20,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.05),
              ],
            ),
            padding: const EdgeInsets.all(30),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(icono, height: 90),
                  const SizedBox(height: 20),
                  Text(
                    titulo,
                    style: GoogleFonts.poppins(
                      color: textoColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 300,
                    child: Center(
                      child: TextField(
                        controller: rucController,
                        style: TextStyle(color: textoColor),
                        decoration: InputDecoration(
                          labelText: 'RUC',
                          labelStyle: TextStyle(color: textoColor),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    child: Center(
                      child: TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: textoColor),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          labelStyle: TextStyle(color: textoColor),
                          filled: true,
                          fillColor: Colors.white12,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: botonColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: 300,
                    child: Row(
                      children: [
                        Checkbox(
                          value: mantenerSesion,
                          onChanged: (value) {
                            setState(() {
                              mantenerSesion = value ?? false;
                            });
                          },
                          activeColor: botonColor,
                          checkColor: Colors.white,
                        ),
                        Expanded(
                          child: Text(
                            'Mantener la sesión iniciada',
                            style: GoogleFonts.poppins(
                              color: textoColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 300,
                    child: Center(
                      child: rucController.text.isNotEmpty
                          ? Text(
                              nombreClinica.isNotEmpty
                                  ? '${esAdmin ? "Cuenta:" : "Clínica:"} $nombreClinica'
                                  : '${esAdmin ? "Cuenta" : "Clínica"} no encontrada',
                              style: TextStyle(color: textoColor.withOpacity(0.7)),
                              textAlign: TextAlign.center,
                            )
                          : const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: botonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: login,
                      child: Text(
                        'INGRESAR',
                        style: GoogleFonts.poppins(
                          color: textoColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: toggleAdmin,
                    child: Text(
                      esAdmin ? 'Volver a modo clínica' : '¿Eres administrador?',
                      style: GoogleFonts.poppins(
                        color: botonColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
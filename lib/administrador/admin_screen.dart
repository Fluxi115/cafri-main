// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cafri/autentificacion/auth_service.dart';
import 'package:cafri/autentificacion/login_screen.dart';
import 'package:cafri/administrador/registeruser_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cafri/administrador/calendaradmin_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cafri/administrador/historial_screen.dart';
import 'package:cafri/administrador/calendarioacti_screen.dart'; // Importa el calendario global

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String userEmail = '';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userEmail = user?.email ?? '';
  }

  void _handleDrawerSelection(String value) async {
    Navigator.pop(context);

    if (value == 'salir') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _authService.logout();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else if (value == 'agregar_nuevo_usuario') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisteruserScreen()),
      );
    } else if (value == 'historial') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistorialActividadesScreen()),
      );
    } else if (value == 'agendar') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CalendarPage()),
      );
    } else if (value == 'calendario') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CalendarAdminScreen()), // calendarioacti_screen.dart
      );
    }
  }

  /// Ejemplo de función para crear una nueva actividad con 'estado':'pendiente'
  Future<void> crearNuevaActividad({
    required String colaborador,
    required DateTime fecha,
    required String descripcion,
    required String tipo,
    String? direccionManual,
    String? ubicacion,
    double? lat,
    double? lng,
  }) async {
    await FirebaseFirestore.instance.collection('actividades').add({
      'colaborador': colaborador,
      'fecha': fecha,
      'descripcion': descripcion,
      'tipo': tipo,
      'direccion_manual': direccionManual ?? '',
      'ubicacion': ubicacion ?? '',
      'lat': lat,
      'lng': lng,
      'estado': 'pendiente', // <-- SIEMPRE incluir este campo al crear
      'creado': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.indigo,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.indigo,
              ),
              accountName: const Text('Administrador'),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, color: Colors.indigo, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('menu'),
              onTap: () => _handleDrawerSelection('menu'),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Agendar'),
              onTap: () => _handleDrawerSelection('agendar'),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Agregar nuevo usuario'),
              onTap: () => _handleDrawerSelection('agregar_nuevo_usuario'),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial de Actividades'),
              onTap: () => _handleDrawerSelection('historial'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Calendario'),
              onTap: () => _handleDrawerSelection('calendario'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Salir', style: TextStyle(color: Colors.red)),
              onTap: () => _handleDrawerSelection('salir'),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE3E6F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 8,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.admin_panel_settings, size: 64, color: Colors.indigo),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Bienvenido, Administrador!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gestiona clientes, agenda y más desde este panel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
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
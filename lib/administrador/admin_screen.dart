// ignore_for_file: use_build_context_synchronously

import 'package:cafri/administrador/geolo.dart';
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
    } else if (value == 'usuario') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Se seleccionó "usuario"')));
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
        MaterialPageRoute(builder: (_) => const CalendarAdminScreen()),
      );
    } else if (value == 'Mapa de usuario') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UserGeo()),
      );
    } else if (value == 'Seguir') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UserGeo()),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              accountName: const Text('Administrador'),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.admin_panel_settings,
                  color: Colors.indigo,
                  size: 40,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Agregar nuevo usuario'),
              onTap: () => _handleDrawerSelection('agregar_nuevo_usuario'),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Agendar'),
              onTap: () => _handleDrawerSelection('agendar'),
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
            ListTile(
              leading: const Icon(Icons.spatial_tracking),
              title: const Text('Seguir'),
              onTap: () => _handleDrawerSelection('Seguir'),
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
            colors: [
              Color.fromARGB(255, 29, 77, 235),
              Color.fromARGB(255, 0, 0, 0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 12,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.indigo.withAlpha(220),
                          Colors.blue.withAlpha(180),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Bienvenido, Administrador!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Gestiona clientes, agenda y más desde este panel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(
                    color: Colors.indigo.withAlpha(80),
                    thickness: 1.2,
                    indent: 30,
                    endIndent: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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

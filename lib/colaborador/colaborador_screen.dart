// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cafri/autentificacion/auth_service.dart';
import 'package:cafri/autentificacion/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cafri/colaborador/calendarcolab_screen.dart';
import 'package:cafri/colaborador/pdf.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

enum ColaboradorSection { actividades, calendario, documento }

class ColaboradorScreen extends StatefulWidget {
  const ColaboradorScreen({super.key});

  @override
  State<ColaboradorScreen> createState() => _ColaboradorScreenState();
}

class _ColaboradorScreenState extends State<ColaboradorScreen> {
  late String userEmail;
  late String userId;
  ColaboradorSection selectedSection = ColaboradorSection.actividades;
  final AuthService _authService = AuthService();

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userEmail = user?.email ?? '';
    userId = user?.uid ?? '';
    _ensureLocationPermissionAndStartUpdates();
  }

  Future<void> _ensureLocationPermissionAndStartUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permiso de ubicación denegado permanentemente. Actívalo en ajustes.',
            ),
          ),
        );
      }
      return;
    }
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _positionStream?.cancel();
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) async {
          await FirebaseFirestore.instance
              .collection('ubicaciones')
              .doc(userId)
              .set({
                'lat': position.latitude,
                'lng': position.longitude,
                'timestamp': FieldValue.serverTimestamp(),
                'nombre': userEmail,
              });
        });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _handleDrawerSelection(ColaboradorSection section) async {
    Navigator.pop(context);
    setState(() {
      selectedSection = section;
    });
  }

  Future<void> _logout() async {
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
  }

  Stream<QuerySnapshot> getActividadesColaborador(String email) {
    return FirebaseFirestore.instance
        .collection('actividades')
        .where('colaborador', isEqualTo: userEmail)
        .where('estado', isNotEqualTo: 'terminada')
        .orderBy('estado')
        .orderBy('fecha')
        .snapshots();
  }

  Widget _buildActividades() {
    return StreamBuilder<QuerySnapshot>(
      stream: getActividadesColaborador(userEmail),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final actividades = snapshot.data?.docs ?? [];
        if (actividades.isEmpty) {
          return const Center(
            child: Text(
              'No tienes actividades asignadas.',
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: actividades.length,
          itemBuilder: (context, index) {
            final actividad = actividades[index].data() as Map<String, dynamic>;
            final docId = actividades[index].id;
            final fecha = (actividad['fecha'] as Timestamp).toDate();
            final estado = actividad['estado'] ?? 'pendiente';
            final esColaboradorAsignado = actividad['colaborador'] == userEmail;

            Color estadoColor;
            switch (estado) {
              case 'aceptada':
                estadoColor = Colors.blue;
                break;
              case 'en_proceso':
                estadoColor = Colors.amber;
                break;
              case 'pausada':
                estadoColor = Colors.deepOrange;
                break;
              case 'terminada':
                estadoColor = Colors.green;
                break;
              default:
                estadoColor = Colors.orange;
            }

            return Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo[100],
                  child: Icon(
                    actividad['tipo'] == 'levantamiento'
                        ? Icons.assignment
                        : actividad['tipo'] == 'mantenimiento'
                        ? Icons.build
                        : Icons.settings_input_component,
                    color: Colors.indigo,
                  ),
                ),
                title: Text(
                  actividad['titulo'] ?? 'Actividad sin título',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fecha.day}/${fecha.month}/${fecha.year} – ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      actividad['descripcion'] ?? '',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if ((actividad['direccion_manual'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.home,
                              color: Colors.indigo,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                actividad['direccion_manual'],
                                style: const TextStyle(color: Colors.indigo),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if ((actividad['ubicacion'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: GestureDetector(
                          onTap: () async {
                            final url = actividad['ubicacion'];
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url));
                            }
                          },
                          child: Row(
                            children: const [
                              Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Ver ubicación',
                                style: TextStyle(
                                  color: Colors.red,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info,
                            size: 18,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Estado: ${estado[0].toUpperCase()}${estado.substring(1).replaceAll('_', ' ')}',
                            style: TextStyle(
                              color: estadoColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (esColaboradorAsignado)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (estado == 'pendiente')
                              ElevatedButton.icon(
                                icon: const Icon(Icons.check),
                                label: const Text('Aceptar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('actividades')
                                      .doc(docId)
                                      .update({'estado': 'aceptada'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Actividad aceptada'),
                                    ),
                                  );
                                },
                              ),
                            if (estado == 'aceptada')
                              ElevatedButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Iniciar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('actividades')
                                      .doc(docId)
                                      .update({'estado': 'en_proceso'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Actividad en proceso'),
                                    ),
                                  );
                                },
                              ),
                            if (estado == 'en_proceso') ...[
                              ElevatedButton.icon(
                                icon: const Icon(Icons.pause),
                                label: const Text('Pausar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('actividades')
                                      .doc(docId)
                                      .update({'estado': 'pausada'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Actividad pausada'),
                                    ),
                                  );
                                },
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.done_all),
                                label: const Text('Terminar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('actividades')
                                      .doc(docId)
                                      .update({'estado': 'terminada'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Actividad terminada'),
                                    ),
                                  );
                                },
                              ),
                            ],
                            if (estado == 'pausada')
                              ElevatedButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Reanudar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('actividades')
                                      .doc(docId)
                                      .update({'estado': 'en_proceso'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Actividad reanudada'),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendario() {
    return ColaboradorCalendario(userEmail: userEmail);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Colaborador'),
        backgroundColor: Colors.indigo,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              accountName: null,
              accountEmail: null,
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.indigo, size: 40),
              ),
            ),
            // Perfil eliminado
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Actividades'),
              selected: selectedSection == ColaboradorSection.actividades,
              onTap: () =>
                  _handleDrawerSelection(ColaboradorSection.actividades),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendario de actividades'),
              selected: selectedSection == ColaboradorSection.calendario,
              onTap: () =>
                  _handleDrawerSelection(ColaboradorSection.calendario),
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Generar documento'),
              selected: selectedSection == ColaboradorSection.documento,
              onTap: () => _handleDrawerSelection(ColaboradorSection.documento),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Salir', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Builder(
        builder: (context) {
          switch (selectedSection) {
            case ColaboradorSection.actividades:
              return _buildActividades();
            case ColaboradorSection.calendario:
              return _buildCalendario();
            case ColaboradorSection.documento:
              return const FormularioPDF();
          }
        },
      ),
    );
  }
}

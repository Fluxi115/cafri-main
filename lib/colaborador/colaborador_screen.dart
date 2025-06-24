// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cafri/autentificacion/auth_service.dart';
import 'package:cafri/autentificacion/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cafri/colaborador/calendarcolab_screen.dart';
import 'package:cafri/colaborador/pdf.dart'; // Importa el widget PDF
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// 1. Cambia el valor pdf a documento en el enum
enum ColaboradorSection { informacion, actividades, calendario, documento }

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

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userEmail = user?.email ?? '';
    userId = user?.uid ?? '';
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
  }

  /// Solo muestra actividades que NO están terminadas
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${fecha.day}/${fecha.month}/${fecha.year} – ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
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
                            const Icon(Icons.home, color: Colors.indigo, size: 18),
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
                              Icon(Icons.location_on, color: Colors.red, size: 18),
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
                    // Estado visual
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.info, size: 18, color: Colors.blueGrey),
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
                    // Botones de acción según estado y colaborador
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
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('actividades')
                                      .doc(docId)
                                      .update({'estado': 'aceptada'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Actividad aceptada')),
                                  );
                                },
                              ),
                            if (estado == 'aceptada')
                              ElevatedButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Iniciar'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('actividades')
                                      .doc(docId)
                                      .update({'estado': 'en_proceso'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Actividad en proceso')),
                                  );
                                },
                              ),
                            if (estado == 'en_proceso') ...[
                              ElevatedButton.icon(
                                icon: const Icon(Icons.pause),
                                label: const Text('Pausar'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('actividades')
                                      .doc(docId)
                                      .update({'estado': 'pausada'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Actividad pausada')),
                                  );
                                },
                              ),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.done_all),
                                label: const Text('Terminar'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('actividades')
                                      .doc(docId)
                                      .update({'estado': 'terminada'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Actividad terminada')),
                                  );
                                },
                              ),
                            ],
                            if (estado == 'pausada')
                              ElevatedButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Reanudar'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('actividades')
                                      .doc(docId)
                                      .update({'estado': 'en_proceso'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Actividad reanudada')),
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
    // Aquí mostramos el calendario real del colaborador
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
              decoration: const BoxDecoration(
                color: Colors.indigo,
              ),
              accountName: const Text('Colaborador'),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.indigo, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Perfil e Información'),
              selected: selectedSection == ColaboradorSection.informacion,
              onTap: () => _handleDrawerSelection(ColaboradorSection.informacion),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Actividades'),
              selected: selectedSection == ColaboradorSection.actividades,
              onTap: () => _handleDrawerSelection(ColaboradorSection.actividades),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendario de actividades'),
              selected: selectedSection == ColaboradorSection.calendario,
              onTap: () => _handleDrawerSelection(ColaboradorSection.calendario),
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
            case ColaboradorSection.informacion:
              return UserProfileScreen(userId: userId);
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

// Widget para mostrar el perfil del usuario desde Firestore y permitir cambiar la foto de perfil
class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  File? _avatarImageFile;
  String? _avatarUrl;
  late DateTime _now;
  bool _isUploading = false;

  // Campos del usuario
  String _fullName = '';
  String _role = '';
  String _status = '';
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _fetchUserData();
    // Actualiza la hora cada segundo
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _now = DateTime.now();
      });
      return true;
    });
  }

  Future<void> _fetchUserData() async {
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(widget.userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _fullName = data['fullName'] ?? '';
        _role = data['role'] ?? '';
        _status = data['status'] ?? '';
        _birthDate = (data['birthDate'] as Timestamp).toDate();
        _avatarUrl = data['avatarUrl'] ?? '';
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _isUploading = true;
      });
      File imageFile = File(pickedFile.path);

      // Sube la imagen a Firebase Storage
      String fileName = 'avatars/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Actualiza la URL en Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(widget.userId).update({
        'avatarUrl': downloadUrl,
      });

      setState(() {
        _avatarImageFile = imageFile;
        _avatarUrl = downloadUrl;
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

    return _fullName.isEmpty || _birthDate == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _avatarImageFile != null
                              ? FileImage(_avatarImageFile!)
                              : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                                  ? NetworkImage(_avatarUrl!)
                                  : const AssetImage('assets/avatar_placeholder.png')) as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: InkWell(
                            onTap: _isUploading ? null : _pickAndUploadImage,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blue,
                              child: _isUploading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Chip(
                          label: Text(_role),
                          avatar: const Icon(Icons.person_outline),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(_status),
                          avatar: Icon(
                            _status.toLowerCase() == 'activo'
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _status.toLowerCase() == 'activo'
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.cake),
                      title: const Text('Fecha de nacimiento'),
                      subtitle: Text(dateFormat.format(_birthDate!)),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Fecha y hora actual'),
                      subtitle: Text(dateTimeFormat.format(_now)),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
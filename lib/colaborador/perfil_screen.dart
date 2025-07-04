// ignore_for_file: use_build_context_synchronously

import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MenuAdminColab extends StatefulWidget {
  const MenuAdminColab({super.key});

  @override
  State<MenuAdminColab> createState() => _MenuAdminColabState();
}

class _MenuAdminColabState extends State<MenuAdminColab> {
  late Future<Map<String, dynamic>?> _userDataFuture;
  XFile? _pickedImage;
  Uint8List? _webImageBytes;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _getUserData();
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      return {
        'uid': doc.id,
        'nombre': doc['name'] ?? 'Sin nombre',
        'email': doc['email'] ?? 'Sin email',
        'rol': doc['rol'] ?? 'Sin rol',
        'fotoUrl': doc['photoUrl'] ?? '',
      };
    } else {
      return {
        'uid': user.uid,
        'nombre': user.displayName ?? 'Sin nombre',
        'email': user.email ?? 'Sin email',
        'rol': 'Sin rol',
        'fotoUrl': user.photoURL ?? '',
      };
    }
  }

  Future<void> _pickAndUploadImage(String userId) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (pickedFile == null) return;

    Uint8List? webBytes;
    if (kIsWeb) {
      webBytes = await pickedFile.readAsBytes();
    }

    setState(() {
      _isUploading = true;
      _pickedImage = pickedFile;
      _webImageBytes = webBytes;
    });

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$userId.jpg');

      String? downloadUrl;
      if (kIsWeb) {
        await ref.putData(
          webBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        downloadUrl = await ref.getDownloadURL();
      } else {
        await ref.putFile(File(pickedFile.path));
        downloadUrl = await ref.getDownloadURL();
      }

      // Actualiza Firestore y Auth
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'photoUrl': downloadUrl,
      });
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == userId) {
        await user.updatePhotoURL(downloadUrl);
      }

      setState(() {
        _isUploading = false;
        _userDataFuture = _getUserData(); // Refresca los datos
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada')),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al subir la foto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil de Colaborador'),
        backgroundColor: const Color(0xFF6D5DF6),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6D5DF6), Color(0xFF3FC5F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FutureBuilder<Map<String, dynamic>?>(
            future: _userDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  _isUploading) {
                return const CircularProgressIndicator();
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return const Text(
                  'No se pudo cargar la información del usuario',
                  style: TextStyle(fontSize: 20),
                );
              }

              final data = snapshot.data!;
              final String nombre = data['nombre'] ?? 'Sin nombre';
              final String email = data['email'] ?? 'Sin email';
              final String rol = data['rol'] ?? 'Sin rol';
              final String fotoUrl = data['fotoUrl'] ?? '';
              final String userId = data['uid'];

              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 12,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundColor: const Color(0xFF6D5DF6),
                              backgroundImage: (_pickedImage != null)
                                  ? (kIsWeb
                                        ? (_webImageBytes != null
                                              ? MemoryImage(_webImageBytes!)
                                              : null)
                                        : FileImage(File(_pickedImage!.path))
                                              as ImageProvider)
                                  : (fotoUrl.isNotEmpty
                                        ? NetworkImage(fotoUrl)
                                        : null),
                              child: (fotoUrl.isEmpty && _pickedImage == null)
                                  ? const Icon(
                                      Icons.person,
                                      size: 80,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: FloatingActionButton(
                                mini: true,
                                backgroundColor: Colors.white,
                                onPressed: () => _pickAndUploadImage(userId),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFF6D5DF6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          nombre,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Chip(
                          label: Text(
                            rol,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: const Color(0xFF6D5DF6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
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
      ),
    );
  }
}

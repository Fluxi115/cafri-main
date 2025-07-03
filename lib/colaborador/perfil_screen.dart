// // ignore_for_file: use_build_context_synchronously

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:intl/intl.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class UserProfileScreen extends StatefulWidget {
//   final String userId;
//   const UserProfileScreen({super.key, required this.userId});

//   @override
//   State<UserProfileScreen> createState() => _UserProfileScreenState();
// }

// class _UserProfileScreenState extends State<UserProfileScreen> {
//   File? _avatarImageFile;
//   String? _avatarUrl;
//   late DateTime _now;
//   bool _isUploading = false;

//   // Campos del usuario
//   String _fullName = '';
//   String _role = '';
//   String _status = '';

//   bool _isLoading = true;
//   String? _errorMsg;

//   @override
//   void initState() {
//     super.initState();
//     _now = DateTime.now();
//     _fetchUserData();
//     // Actualiza la hora cada segundo
//     Future.doWhile(() async {
//       await Future.delayed(const Duration(seconds: 1));
//       if (!mounted) return false;
//       setState(() {
//         _now = DateTime.now();
//       });
//       return true;
//     });
//   }

//   Future<void> _fetchUserData() async {
//     try {
//       final doc = await FirebaseFirestore.instance.collection('usuarios').doc(widget.userId).get();
//       if (!doc.exists) {
//         setState(() {
//           _isLoading = false;
//           _errorMsg = 'No se encontró el usuario.';
//         });
//         return;
//       }
//       final data = doc.data()!;
//       setState(() {
//         // Soporta ambos nombres de campo
//         _fullName = data['fullName'] ?? data['name'] ?? '';
//         _role = data['role'] ?? data['rol'] ?? '';
//         _status = data['status'] ?? '';
//         _avatarUrl = data['avatarUrl'] ?? '';
//         _isLoading = false;
//         if (_fullName.isEmpty) {
//           _errorMsg = 'El nombre del usuario no está disponible.';
//         }
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMsg = 'Error al cargar el perfil: $e';
//       });
//     }
//   }

//   Future<void> _pickAndUploadImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _isUploading = true;
//       });
//       File imageFile = File(pickedFile.path);

//       try {
//         String fileName = 'avatars/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
//         Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
//         UploadTask uploadTask = storageRef.putFile(imageFile);

//         TaskSnapshot snapshot = await uploadTask;
//         String downloadUrl = await snapshot.ref.getDownloadURL();

//         await FirebaseFirestore.instance.collection('usuarios').doc(widget.userId).update({
//           'avatarUrl': downloadUrl,
//         });

//         setState(() {
//           _avatarImageFile = imageFile;
//           _avatarUrl = downloadUrl;
//           _isUploading = false;
//         });
//       } catch (e) {
//         setState(() {
//           _isUploading = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error al subir la imagen: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     if (_errorMsg != null) {
//       return Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Text(
//             _errorMsg!,
//             style: const TextStyle(color: Colors.red, fontSize: 18),
//             textAlign: TextAlign.center,
//           ),
//         ),
//       );
//     }

//     return SingleChildScrollView(
//       child: Card(
//         margin: const EdgeInsets.all(16.0),
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Stack(
//                 alignment: Alignment.bottomRight,
//                 children: [
//                   CircleAvatar(
//                     radius: 50,
//                     backgroundImage: _avatarImageFile != null
//                         ? FileImage(_avatarImageFile!)
//                         : (_avatarUrl != null && _avatarUrl!.isNotEmpty
//                             ? NetworkImage(_avatarUrl!)
//                             : const AssetImage('assets/avatar_placeholder.png')) as ImageProvider,
//                   ),
//                   Positioned(
//                     bottom: 0,
//                     right: 4,
//                     child: InkWell(
//                       onTap: _isUploading ? null : _pickAndUploadImage,
//                       child: CircleAvatar(
//                         radius: 18,
//                         backgroundColor: Colors.blue,
//                         child: _isUploading
//                             ? const SizedBox(
//                                 width: 18,
//                                 height: 18,
//                                 child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                               )
//                             : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 _fullName,
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Chip(
//                     label: Text(_role.isNotEmpty ? _role : 'Sin rol'),
//                     avatar: const Icon(Icons.person_outline),
//                   ),
//                   const SizedBox(width: 8),
//                   Chip(
//                     label: Text(_status.isNotEmpty ? _status : 'Sin estado'),
//                     avatar: Icon(
//                       _status.toLowerCase() == 'activo'
//                           ? Icons.check_circle
//                           : Icons.cancel,
//                       color: _status.toLowerCase() == 'activo'
//                           ? Colors.green
//                           : Colors.red,
//                     ),
//                   ),
//                 ],
//               ),
//               const Divider(),
//               ListTile(
//                 leading: const Icon(Icons.access_time),
//                 title: const Text('Fecha y hora actual'),
//                 subtitle: Text(dateTimeFormat.format(_now)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

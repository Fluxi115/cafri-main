// lib/colaborador/colaborador_actividades.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ColaboradorActividades extends StatelessWidget {
  final String userEmail;
  const ColaboradorActividades({super.key, required this.userEmail});

  Stream<QuerySnapshot> getActividadesColaborador(String email) {
    return FirebaseFirestore.instance
        .collection('actividades')
        .where('colaborador', isEqualTo: email)
        .where('estado', isNotEqualTo: 'terminada')
        .orderBy('estado')
        .orderBy('fecha')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
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
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';

class UserGeo extends StatefulWidget {
  const UserGeo({super.key});

  @override
  State<UserGeo> createState() => _UserGeoState();
}

class _UserGeoState extends State<UserGeo> {
  late final MapController _mapController;
  String? _selectedUserId;
  Map<String, dynamic>? _selectedUserData;
  latlng.LatLng? _lastFollowedUserPosition;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _centerMapOnUser(Map<String, dynamic> userData) {
    if (userData['lat'] != null && userData['lng'] != null) {
      final newPosition = latlng.LatLng(userData['lat'], userData['lng']);
      _mapController.move(newPosition, _mapController.camera.zoom);
      _lastFollowedUserPosition = newPosition;
    }
  }

  void _unfollowUser() {
    setState(() {
      _selectedUserId = null;
      _selectedUserData = null;
      _lastFollowedUserPosition = null;
    });
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Sin datos';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicaciones en tiempo real'),
        actions: [
          if (_selectedUserId != null)
            IconButton(
              icon: const Icon(Icons.cancel),
              tooltip: 'Dejar de seguir',
              onPressed: _unfollowUser,
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ubicaciones')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          List<Map<String, dynamic>> users = [];
          List<Marker> markers = [];
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.id;
            if (data['lat'] != null && data['lng'] != null) {
              users.add({
                'userId': userId,
                'nombre': data['nombre'] ?? userId,
                'lat': data['lat'],
                'lng': data['lng'],
                'timestamp': data['timestamp'],
                'avatarUrl': data['avatarUrl'], // Opcional: si tienes avatar
              });
              markers.add(
                Marker(
                  point: latlng.LatLng(data['lat'], data['lng']),
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: AnimatedScale(
                    scale: _selectedUserId == userId ? 1.3 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedUserId = userId;
                          _selectedUserData = data;
                          _lastFollowedUserPosition = null;
                        });
                        _centerMapOnUser(data);
                      },
                      child: Icon(
                        Icons.location_on,
                        color: _selectedUserId == userId
                            ? theme.colorScheme.primary
                            : Colors.red,
                        size: 40,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(
                              alpha: 51,
                            ), // 0.2 * 255 ≈ 51
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          }

          // Solo seguir automáticamente al usuario si está seleccionado
          if (_selectedUserId != null) {
            final user = users.firstWhere(
              (u) => u['userId'] == _selectedUserId,
              orElse: () => {},
            );
            if (user.isNotEmpty) {
              final currentPosition = latlng.LatLng(user['lat'], user['lng']);
              if (_lastFollowedUserPosition == null ||
                  _lastFollowedUserPosition != currentPosition) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Solo centrar si sigue seleccionado
                  if (_selectedUserId == user['userId']) {
                    _centerMapOnUser(user);
                  }
                });
              }
            }
          }

          // Default camera position
          final initialCenter = users.isNotEmpty
              ? latlng.LatLng(users[0]['lat'], users[0]['lng'])
              : const latlng.LatLng(0, 0);

          return Column(
            children: [
              // Card para el selector de usuario
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_search, color: Colors.blueGrey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: const Text(
                                'Selecciona un usuario para seguir',
                              ),
                              value: _selectedUserId,
                              items: users.map((user) {
                                return DropdownMenuItem<String>(
                                  value: user['userId'],
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue[100],
                                        backgroundImage:
                                            user['avatarUrl'] != null
                                            ? NetworkImage(user['avatarUrl'])
                                            : null,
                                        child: user['avatarUrl'] == null
                                            ? Text(
                                                user['nombre']
                                                    .toString()
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        user['nombre'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (userId) {
                                final user = users.firstWhere(
                                  (u) => u['userId'] == userId,
                                );
                                setState(() {
                                  _selectedUserId = userId;
                                  _selectedUserData = user;
                                  _lastFollowedUserPosition = null;
                                });
                                _centerMapOnUser(user);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedUserId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 16,
                  ),
                  child: Card(
                    // Reemplazo de withAlpha(20) por withValues(alpha: 20)
                    color: theme.colorScheme.primary.withValues(alpha: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        backgroundImage: _selectedUserData?['avatarUrl'] != null
                            ? NetworkImage(_selectedUserData!['avatarUrl'])
                            : null,
                        child: _selectedUserData?['avatarUrl'] == null
                            ? Text(
                                (_selectedUserData?['nombre'] ??
                                        _selectedUserId)
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        'Siguiendo a: ${_selectedUserData?['nombre'] ?? _selectedUserId}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      subtitle: Text(
                        'Última actualización: ${_formatTimestamp(_selectedUserData?['timestamp'])}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        tooltip: 'Dejar de seguir',
                        onPressed: _unfollowUser,
                      ),
                    ),
                  ),
                ),
              // Mapa
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: users.isNotEmpty ? 14 : 2,
                      crs: const Epsg3857(),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

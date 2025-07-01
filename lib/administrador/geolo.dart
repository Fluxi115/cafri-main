import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_map/flutter_map.dart';

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

  @override
  Widget build(BuildContext context) {
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
              });
              markers.add(
                Marker(
                  point: latlng.LatLng(data['lat'], data['lng']),
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedUserId = userId;
                        _selectedUserData = data;
                      });
                      _centerMapOnUser(data);
                    },
                    child: Icon(
                      Icons.location_on,
                      color: _selectedUserId == userId
                          ? Colors.blueAccent
                          : Colors.red,
                      size: 36,
                    ),
                  ),
                ),
              );
            }
          }

          // Seguir automáticamente al usuario seleccionado
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
                  _centerMapOnUser(user);
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
              // Lista de usuarios para seleccionar a quién seguir
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final isSelected = user['userId'] == _selectedUserId;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedUserId = user['userId'];
                          _selectedUserData = user;
                          _lastFollowedUserPosition = null;
                        });
                        _centerMapOnUser(user);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            user['nombre'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_selectedUserId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    'Siguiendo a: ${_selectedUserData?['nombre'] ?? _selectedUserId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              // Mapa
              Expanded(
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
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

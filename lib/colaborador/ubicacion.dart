/*import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

class ColaboradorUbicacionRealtime extends StatefulWidget {
  final String userId;
  final String nombre;

  const ColaboradorUbicacionRealtime({
    super.key,
    required this.userId,
    required this.nombre,
  });

  @override
  State<ColaboradorUbicacionRealtime> createState() =>
      _ColaboradorUbicacionRealtimeState();
}

class _ColaboradorUbicacionRealtimeState
    extends State<ColaboradorUbicacionRealtime> {
  Stream<Position>? _positionStream;
  String _status = "Esperando ubicación...";
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initLocationStream();
  }

  Future<void> _initLocationStream() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _status = "Activa el GPS";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _status = "Permiso de ubicación denegado";
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _status = "Permiso de ubicación denegado permanentemente";
      });
      return;
    }

    setState(() {
      _status = "Enviando ubicación...";
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // metros
        ),
      );
    });

    _positionStream!.listen((Position position) async {
      setState(() {
        _currentPosition = position;
      });
      await FirebaseFirestore.instance
          .collection('ubicaciones')
          .doc(widget.userId)
          .set({
            'lat': position.latitude,
            'lng': position.longitude,
            'nombre': widget.nombre,
            'timestamp': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mi ubicación')),
      body: Column(
        children: [
          if (_currentPosition != null)
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: latlng.LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latlng.LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.blue,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            const Expanded(child: Center(child: CircularProgressIndicator())),
          Padding(padding: const EdgeInsets.all(16.0), child: Text(_status)),
        ],
      ),
    );
  }
}
*/

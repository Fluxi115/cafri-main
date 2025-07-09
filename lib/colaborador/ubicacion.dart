import 'package:background_locator_2/background_locator.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/ios_settings.dart';
import 'package:background_locator_2/settings/locator_settings.dart';
import 'package:background_locator_2/location_dto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UbicacionService {
  static bool _isRunning = false;
  static const String _prefsUserIdKey = 'ubicacion_user_id';
  static const String _prefsNombreKey = 'ubicacion_nombre';
  static const String _prefsAvatarUrlKey = 'ubicacion_avatar_url';

  /// Inicia el envío de ubicación en segundo plano para el usuario dado.
  static Future<void> start(
    String userId, {
    String? nombre,
    String? avatarUrl,
  }) async {
    if (_isRunning) return;
    _isRunning = true;

    // Guarda los datos en SharedPreferences para acceso en el callback
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsUserIdKey, userId);
    if (nombre != null) {
      await prefs.setString(_prefsNombreKey, nombre);
    }
    if (avatarUrl != null) {
      await prefs.setString(_prefsAvatarUrlKey, avatarUrl);
    }

    await BackgroundLocator.initialize();

    BackgroundLocator.registerLocationUpdate(
      _callback,
      initCallback: _initCallback,
      disposeCallback: _disposeCallback,
      iosSettings: IOSSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        distanceFilter: 10,
      ),
      autoStop: false,
      androidSettings: AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 30, // segundos entre actualizaciones
        distanceFilter: 10,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Ubicación en segundo plano',
          notificationTitle: 'Enviando ubicación',
          notificationMsg: 'Tu ubicación se está compartiendo en segundo plano',
          notificationBigMsg:
              'Tu ubicación se está compartiendo en segundo plano para la app.',
          notificationIcon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  /// Detiene el envío de ubicación.
  static Future<void> stop() async {
    _isRunning = false;
    await BackgroundLocator.unRegisterLocationUpdate();
    // Limpia los datos guardados
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsUserIdKey);
    await prefs.remove(_prefsNombreKey);
    await prefs.remove(_prefsAvatarUrlKey);
  }

  // --- Callbacks para background_locator_2 ---

  static void _initCallback(Map<dynamic, dynamic> params) {
    // Se llama cuando inicia el servicio
  }

  static void _disposeCallback() {
    // Se llama cuando se detiene el servicio
  }

  static Future<void> _callback(LocationDto locationDto) async {
    // Recupera los datos guardados en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString(_prefsUserIdKey);
    final String? nombre = prefs.getString(_prefsNombreKey);
    final String? avatarUrl = prefs.getString(_prefsAvatarUrlKey);

    if (userId == null) return;

    await FirebaseFirestore.instance.collection('ubicaciones').doc(userId).set({
      'lat': locationDto.latitude,
      'lng': locationDto.longitude,
      'timestamp': FieldValue.serverTimestamp(),
      if (nombre != null) 'nombre': nombre,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    }, SetOptions(merge: true));
  }
}

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationInfo {
  final double latitude;
  final double longitude;
  final String? country;
  final String? state;
  final String? city;
  final String? locality;

  LocationInfo({
    required this.latitude,
    required this.longitude,
    this.country,
    this.state,
    this.city,
    this.locality,
  });

  String get locationContext {
    final parts = <String>[];
    if (locality != null) parts.add(locality!);
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    if (country != null) parts.add(country!);
    return parts.join(', ');
  }
}

class LocationService extends ChangeNotifier {
  LocationInfo? _currentLocation;
  bool _isLoading = false;
  String? _error;

  LocationInfo? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> requestLocationPermission() async {
    if (kIsWeb) return false;

    final status = await Permission.location.request();
    return status.isGranted;
  }

  Future<void> getCurrentLocation() async {
    if (!await requestLocationPermission()) {
      _error = 'Location permission denied';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _error = 'Location services are disabled';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentLocation = LocationInfo(
          latitude: position.latitude,
          longitude: position.longitude,
          country: place.country,
          state: place.administrativeArea,
          city: place.locality,
          locality: place.subLocality,
        );
      } else {
        _currentLocation = LocationInfo(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    } catch (e) {
      _error = 'Error getting location: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getLocationContextForPrompt(String userPrompt) {
    if (_currentLocation == null) return userPrompt;

    final locationContext = _currentLocation!.locationContext;
    return '''
You are a helpful AI assistant. The user is currently located in: $locationContext.
Please provide information relevant to their location when appropriate.
User's question: $userPrompt
''';
  }
} 
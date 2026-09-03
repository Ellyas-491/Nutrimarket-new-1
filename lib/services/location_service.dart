import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UserLocationResult {
  final double latitude;
  final double longitude;
  final String city;
  final String region;
  final String street;
  final String country;
  final String formattedAddress;

  const UserLocationResult({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.region,
    required this.street,
    required this.country,
    required this.formattedAddress,
  });
}

class PlaceSearchResult {
  final String displayName;
  final String shortName;
  final double latitude;
  final double longitude;

  const PlaceSearchResult({
    required this.displayName,
    required this.shortName,
    required this.latitude,
    required this.longitude,
  });
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  UserLocationResult? _cachedLocation;

  Future<UserLocationResult> getCurrentUserLocation({bool forceRefresh = true}) async {
    if (!forceRefresh && _cachedLocation != null) return _cachedLocation!;

    // 1. Try Hardware GPS via Geolocator
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services (GPS) are disabled on device.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        // Fast path: check last known position
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          debugPrint('Using last known GPS: ${lastKnown.latitude}, ${lastKnown.longitude}');
          final geocoded = await reverseGeocodeCoordinates(lastKnown.latitude, lastKnown.longitude);
          _cachedLocation = geocoded;
        }

        // Fresh accurate GPS fix with best accuracy
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 10),
          ),
        );

        debugPrint('Acquired fresh GPS fix: ${position.latitude}, ${position.longitude}');
        final geocoded = await reverseGeocodeCoordinates(position.latitude, position.longitude);
        _cachedLocation = geocoded;
        return _cachedLocation!;
      }
    } catch (e) {
      debugPrint('Geolocator GPS reading error: $e');
    }

    if (_cachedLocation != null) return _cachedLocation!;

    // 2. High-Accuracy IP Geolocation Fallback 1: ipapi.co
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['latitude'] != null && data['longitude'] != null) {
          final lat = (data['latitude'] as num).toDouble();
          final lon = (data['longitude'] as num).toDouble();
          debugPrint('IP fallback location: $lat, $lon');
          final geocoded = await reverseGeocodeCoordinates(lat, lon);
          _cachedLocation = geocoded;
          return _cachedLocation!;
        }
      }
    } catch (e) {
      debugPrint('ipapi.co fetch error: $e');
    }

    // 3. High-Accuracy IP Geolocation Fallback 2: ip-api.com
    try {
      final response = await http
          .get(Uri.parse('http://ip-api.com/json'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'success') {
          final lat = (data['lat'] as num).toDouble();
          final lon = (data['lon'] as num).toDouble();
          final geocoded = await reverseGeocodeCoordinates(lat, lon);
          _cachedLocation = geocoded;
          return _cachedLocation!;
        }
      }
    } catch (e) {
      debugPrint('ip-api.com fetch error: $e');
    }

    // Default fallback
    return const UserLocationResult(
      latitude: -7.9839, // Malang Center
      longitude: 112.6214,
      city: 'Malang',
      region: 'Jawa Timur',
      street: 'Titik Lokasi GPS',
      country: 'Indonesia',
      formattedAddress: 'Kota Malang, Jawa Timur',
    );
  }

  Stream<UserLocationResult> getLiveLocationStream() async* {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        yield* Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 2,
          ),
        ).asyncMap((pos) async {
          final geocoded = await reverseGeocodeCoordinates(pos.latitude, pos.longitude);
          _cachedLocation = geocoded;
          return geocoded;
        });
      }
    } catch (e) {
      debugPrint('Live location stream error: $e');
    }
  }

  Future<UserLocationResult> reverseGeocodeCoordinates(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'NutriMarketHealthApp/1.0 (contact: info@nutrimarket.id)',
        'Accept-Language': 'id-ID,id;q=0.9,en;q=0.8',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addressObj = data['address'] as Map<String, dynamic>? ?? {};
        final displayName = data['display_name'] as String? ?? '';

        // Extract precise alley / gang / road / building details
        final specificPlace = addressObj['building'] as String? ??
            addressObj['amenity'] as String? ??
            addressObj['shop'] as String? ??
            addressObj['house_name'] as String? ??
            '';

        final roadOrAlley = addressObj['road'] as String? ??
            addressObj['residential'] as String? ??
            addressObj['pedestrian'] as String? ??
            addressObj['alley'] as String? ??
            addressObj['footway'] as String? ??
            addressObj['path'] as String? ??
            addressObj['neighbourhood'] as String? ??
            '';

        final houseNumber = addressObj['house_number'] as String? ?? '';
        final neighbourhood = addressObj['neighbourhood'] as String? ??
            addressObj['quarter'] as String? ??
            addressObj['suburb'] as String? ??
            addressObj['village'] as String? ??
            addressObj['hamlet'] as String? ??
            '';
        final district = addressObj['city_district'] as String? ??
            addressObj['municipality'] as String? ??
            addressObj['subdistrict'] as String? ??
            '';
        final city = addressObj['city'] as String? ??
            addressObj['town'] as String? ??
            addressObj['county'] as String? ??
            '';
        final state = addressObj['state'] as String? ?? 'Jawa Timur';
        final postcode = addressObj['postcode'] as String? ?? '';

        // Build street / gang segment
        String streetFull = roadOrAlley;
        if (houseNumber.isNotEmpty) {
          streetFull = streetFull.isNotEmpty ? '$streetFull No. $houseNumber' : 'No. $houseNumber';
        }
        if (specificPlace.isNotEmpty && !streetFull.contains(specificPlace)) {
          streetFull = streetFull.isNotEmpty ? '$specificPlace, $streetFull' : specificPlace;
        }

        // If display_name is rich, format it cleanly by removing trailing postal/country if redundant
        String formattedAddress = '';
        if (displayName.isNotEmpty) {
          final parts = displayName.split(',').map((p) => p.trim()).toList();
          // Filter out country if at end
          if (parts.isNotEmpty && parts.last.toLowerCase() == 'indonesia') {
            parts.removeLast();
          }
          formattedAddress = parts.join(', ');
        }

        // Fallback to structured parts if formattedAddress is empty
        if (formattedAddress.isEmpty) {
          final components = <String>[
            if (streetFull.isNotEmpty) streetFull,
            if (neighbourhood.isNotEmpty && !streetFull.contains(neighbourhood)) neighbourhood,
            if (district.isNotEmpty) district,
            if (city.isNotEmpty) city,
            if (state.isNotEmpty) state,
            if (postcode.isNotEmpty) postcode,
          ];
          formattedAddress = components.join(', ');
        }

        if (formattedAddress.isEmpty) {
          formattedAddress = 'Titik Koordinat (${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)})';
        }

        return UserLocationResult(
          latitude: lat,
          longitude: lon,
          city: city.isNotEmpty ? city : (district.isNotEmpty ? district : state),
          region: state,
          street: streetFull.isNotEmpty ? streetFull : 'Titik Gang / Jalan',
          country: 'Indonesia',
          formattedAddress: formattedAddress,
        );
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }

    return UserLocationResult(
      latitude: lat,
      longitude: lon,
      city: 'Lokasi Terdeteksi',
      region: 'Indonesia',
      street: 'Titik GPS (${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)})',
      country: 'Indonesia',
      formattedAddress: 'Titik Koordinat (${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)})',
    );
  }

  Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final encoded = Uri.encodeComponent(cleanQuery);
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&addressdetails=1&limit=6&countrycodes=id',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'NutriMarketHealthApp/1.0',
      }).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body) as List;
        return list.map((item) {
          final lat = double.parse(item['lat'].toString());
          final lon = double.parse(item['lon'].toString());
          final displayName = item['display_name'] as String? ?? '';
          final parts = displayName.split(',');
          final short = parts.length > 2 ? '${parts[0]}, ${parts[1]}' : displayName;

          return PlaceSearchResult(
            displayName: displayName,
            shortName: short,
            latitude: lat,
            longitude: lon,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('Search places error: $e');
    }
    return [];
  }
}

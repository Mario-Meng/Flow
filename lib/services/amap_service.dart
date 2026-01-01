import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// Business area information
class BusinessArea {
  final String name;
  final String? location; // Longitude and latitude

  const BusinessArea({required this.name, this.location});
}

/// Amap service
class AmapService {
  // Amap Web Service Key (from config file)
  static const String _apiKey = AppConfig.amapApiKey;

  /// Get nearby business areas by coordinates
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [radius] 搜索半径（米），默认1000米
  static Future<List<BusinessArea>> getNearbyBusinessAreas(
    double latitude,
    double longitude, {
    int radius = 3000,
  }) async {
    // Amap reverse geocoding API URL
    // extensions=all is required, otherwise no POI and business info
    final String url =
        'https://restapi.amap.com/v3/geocode/regeo?'
        'output=json&'
        'location=$longitude,$latitude&'
        'key=$_apiKey&'
        'radius=$radius&'
        'extensions=all';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check API return status
        if (data['status'] == '1' && data['regeocode'] != null) {
          final addressComponent = data['regeocode']['addressComponent'];

          // Get formatted address
          final String formattedAddress =
              data['regeocode']['formatted_address'] ?? '';

          List<BusinessArea> areas = [];

          // Add current location as first option
          if (formattedAddress.isNotEmpty) {
            areas.add(
              BusinessArea(
                name: formattedAddress,
                location: '$longitude,$latitude',
              ),
            );
          }

          // Get businessAreas list
          if (addressComponent['businessAreas'] != null) {
            final List<dynamic> businessAreas =
                addressComponent['businessAreas'];

            // Extract business area names
            for (var area in businessAreas) {
              if (area['name'] != null && (area['name'] as String).isNotEmpty) {
                areas.add(
                  BusinessArea(
                    name: area['name'] as String,
                    location: area['location'],
                  ),
                );
              }
            }
          }

          // If has POI list, add some
          if (data['regeocode']['pois'] != null) {
            final List<dynamic> pois = data['regeocode']['pois'];
            for (var i = 0; i < pois.length && i < 5; i++) {
              final poi = pois[i];
              if (poi['name'] != null && (poi['name'] as String).isNotEmpty) {
                areas.add(
                  BusinessArea(
                    name: poi['name'] as String,
                    location: poi['location'],
                  ),
                );
              }
            }
          }

          return areas;
        }
      }
      return [];
    } catch (e) {
      print('Failed to fetch business areas: $e');
      return [];
    }
  }

  /// Get formatted address
  static Future<String?> getFormattedAddress(
    double latitude,
    double longitude,
  ) async {
    final String url =
        'https://restapi.amap.com/v3/geocode/regeo?'
        'output=json&'
        'location=$longitude,$latitude&'
        'key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == '1' && data['regeocode'] != null) {
          return data['regeocode']['formatted_address'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('Failed to fetch address: $e');
      return null;
    }
  }
}

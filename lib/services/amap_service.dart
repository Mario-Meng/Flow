import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// 商圈信息
class BusinessArea {
  final String name;
  final String? location; // 经纬度
  
  const BusinessArea({
    required this.name,
    this.location,
  });
}

/// 高德地图服务
class AmapService {
  // 高德 Web服务 Key（从配置文件读取）
  static const String _apiKey = AppConfig.amapApiKey;
  
  /// 根据经纬度获取附近商圈信息
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [radius] 搜索半径（米），默认1000米
  static Future<List<BusinessArea>> getNearbyBusinessAreas(
    double latitude,
    double longitude, {
    int radius = 3000,
  }) async {
    // 高德逆地理编码 API 地址
    // extensions=all 是必须的，否则不会返回 poi 和商圈信息
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

        // 检查 API 返回状态
        if (data['status'] == '1' && data['regeocode'] != null) {
          final addressComponent = data['regeocode']['addressComponent'];
          
          // 获取格式化地址
          final String formattedAddress = data['regeocode']['formatted_address'] ?? '';
          
          List<BusinessArea> areas = [];
          
          // 添加当前位置作为第一个选项
          if (formattedAddress.isNotEmpty) {
            areas.add(BusinessArea(
              name: formattedAddress,
              location: '$longitude,$latitude',
            ));
          }
          
          // 获取 businessAreas 列表
          if (addressComponent['businessAreas'] != null) {
            final List<dynamic> businessAreas = addressComponent['businessAreas'];
            
            // 提取商圈名称
            for (var area in businessAreas) {
              if (area['name'] != null && (area['name'] as String).isNotEmpty) {
                areas.add(BusinessArea(
                  name: area['name'] as String,
                  location: area['location'],
                ));
              }
            }
          }
          
          // 如果有POI列表，也添加一些
          if (data['regeocode']['pois'] != null) {
            final List<dynamic> pois = data['regeocode']['pois'];
            for (var i = 0; i < pois.length && i < 5; i++) {
              final poi = pois[i];
              if (poi['name'] != null && (poi['name'] as String).isNotEmpty) {
                areas.add(BusinessArea(
                  name: poi['name'] as String,
                  location: poi['location'],
                ));
              }
            }
          }
          
          return areas;
        }
      }
      return [];
    } catch (e) {
      print('获取商圈信息失败: $e');
      return [];
    }
  }
  
  /// 获取格式化的地址
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
      print('获取地址失败: $e');
      return null;
    }
  }
}


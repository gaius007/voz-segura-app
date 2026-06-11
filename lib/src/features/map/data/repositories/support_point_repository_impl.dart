import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/support_point.dart';
import '../../domain/repositories/support_point_repository.dart';

/// Busca pontos de apoio reais via API Overpass (OpenStreetMap). Gratuita, sem
/// chave de API. Retorna delegacias/polícia, hospitais e centros de apoio.
class SupportPointRepositoryImpl implements SupportPointRepository {
  static const String _endpoint = 'https://overpass-api.de/api/interpreter';

  @override
  Future<List<SupportPoint>> getNearbySupportPoints(
    double latitude,
    double longitude, {
    double radiusMeters = 5000,
  }) async {
    final r = radiusMeters.round();
    final query = '''
[out:json][timeout:25];
(
  node["amenity"="police"](around:$r,$latitude,$longitude);
  node["amenity"="hospital"](around:$r,$latitude,$longitude);
  node["amenity"="social_facility"](around:$r,$latitude,$longitude);
  node["amenity"="community_centre"](around:$r,$latitude,$longitude);
);
out body;
''';

    final response = await http
        .post(Uri.parse(_endpoint), body: {'data': query})
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Overpass API erro: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (data['elements'] as List?) ?? const [];

    return elements
        .map((e) {
          final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
          final amenity = tags['amenity'] as String?;
          final lat = e['lat'];
          final lon = e['lon'];
          if (lat == null || lon == null) return null;
          return SupportPoint(
            id: e['id'].toString(),
            name: tags['name'] as String? ?? _defaultName(amenity),
            type: _typeFromAmenity(amenity),
            latitude: (lat as num).toDouble(),
            longitude: (lon as num).toDouble(),
          );
        })
        .whereType<SupportPoint>()
        .toList();
  }

  SupportPointType _typeFromAmenity(String? amenity) {
    switch (amenity) {
      case 'police':
        return SupportPointType.delegacia;
      case 'hospital':
        return SupportPointType.hospital;
      case 'social_facility':
      case 'community_centre':
        return SupportPointType.centroApoio;
      default:
        return SupportPointType.outro;
    }
  }

  String _defaultName(String? amenity) {
    switch (amenity) {
      case 'police':
        return 'Delegacia / Posto Policial';
      case 'hospital':
        return 'Hospital';
      case 'social_facility':
      case 'community_centre':
        return 'Centro de Apoio';
      default:
        return 'Ponto de Apoio';
    }
  }
}

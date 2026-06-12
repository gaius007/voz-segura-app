import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/support_point.dart';
import '../../domain/repositories/support_point_repository.dart';

/// Busca pontos de apoio reais via API Overpass (OpenStreetMap). Gratuita, sem
/// chave de API. Retorna delegacias (incl. da Mulher), hospitais/clínicas,
/// centros de apoio, casas de acolhimento e ONGs.
class SupportPointRepositoryImpl implements SupportPointRepository {
  // Mirror como fallback: a instância principal tem rate limit/instabilidade
  static const List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  static final RegExp _womenPoliceRegex =
      RegExp(r'mulher|DDM|DEAM|defesa da mulher', caseSensitive: false);

  @override
  Future<List<SupportPoint>> getNearbySupportPoints(
    double latitude,
    double longitude, {
    double radiusMeters = 5000,
  }) async {
    final r = radiusMeters.round();
    // nwr = node + way + relation: hospitais e delegacias mapeados como áreas
    // (ways) não apareciam na busca antiga (que era só de nodes).
    // "out center" entrega o centro geométrico de ways/relations.
    final query = '''
[out:json][timeout:25];
(
  nwr["amenity"="police"](around:$r,$latitude,$longitude);
  nwr["amenity"~"^(hospital|clinic|doctors)\$"](around:$r,$latitude,$longitude);
  nwr["amenity"="social_facility"](around:$r,$latitude,$longitude);
  nwr["social_facility"](around:$r,$latitude,$longitude);
  nwr["amenity"="community_centre"](around:$r,$latitude,$longitude);
  nwr["office"="ngo"](around:$r,$latitude,$longitude);
);
out center 150;
''';

    final data = await _queryWithFallback(query);
    final elements = (data['elements'] as List?) ?? const [];

    final seen = <String>{};
    final points = <SupportPoint>[];
    for (final e in elements) {
      final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
      // nodes têm lat/lon diretos; ways/relations vêm com o centro em 'center'
      final lat = e['lat'] ?? e['center']?['lat'];
      final lon = e['lon'] ?? e['center']?['lon'];
      if (lat == null || lon == null) continue;

      final id = e['id'].toString();
      if (!seen.add(id)) continue;

      final type = _typeFromTags(tags);
      points.add(SupportPoint(
        id: id,
        name: tags['name'] as String? ?? _defaultName(type),
        type: type,
        latitude: (lat as num).toDouble(),
        longitude: (lon as num).toDouble(),
      ));
    }
    return points;
  }

  // Tenta cada endpoint em sequência; o próximo só é usado se o anterior falhar
  Future<Map<String, dynamic>> _queryWithFallback(String query) async {
    Object? lastError;
    for (final endpoint in _endpoints) {
      try {
        final response = await http
            .post(Uri.parse(endpoint), body: {'data': query})
            .timeout(const Duration(seconds: 12));
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
        lastError = Exception('Overpass API erro: ${response.statusCode}');
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('Overpass indisponível em todos os endpoints: $lastError');
  }

  SupportPointType _typeFromTags(Map<String, dynamic> tags) {
    final amenity = tags['amenity'] as String?;
    final name = tags['name'] as String? ?? '';

    if (amenity == 'police') {
      return _womenPoliceRegex.hasMatch(name)
          ? SupportPointType.delegaciaMulher
          : SupportPointType.delegacia;
    }
    if (amenity == 'hospital' || amenity == 'clinic' || amenity == 'doctors') {
      return SupportPointType.hospital;
    }
    if (tags['social_facility'] == 'shelter') {
      return SupportPointType.casaAcolhimento;
    }
    if (amenity == 'social_facility' ||
        amenity == 'community_centre' ||
        tags.containsKey('social_facility') ||
        tags['office'] == 'ngo') {
      return SupportPointType.centroApoio;
    }
    return SupportPointType.outro;
  }

  String _defaultName(SupportPointType type) {
    switch (type) {
      case SupportPointType.delegaciaMulher:
        return 'Delegacia da Mulher';
      case SupportPointType.delegacia:
        return 'Delegacia / Posto Policial';
      case SupportPointType.hospital:
        return 'Hospital';
      case SupportPointType.casaAcolhimento:
        return 'Casa de Acolhimento';
      case SupportPointType.centroApoio:
        return 'Centro de Apoio';
      default:
        return 'Ponto de Apoio';
    }
  }
}

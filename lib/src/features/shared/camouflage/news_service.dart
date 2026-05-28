import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsArticle {
  final String title;
  final String description;
  final String? imageUrl;
  final String? source;
  final String? link;

  NewsArticle({
    required this.title,
    required this.description,
    this.imageUrl,
    this.source,
    this.link,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'Sem título',
      description: json['description'] ?? 'Sem descrição disponível.',
      imageUrl: json['image_url'],
      source: json['source_id'],
      link: json['link'],
    );
  }
}

class NewsService {
  // O usuário deve trocar por uma chave válida. 
  // Esta chave abaixo é um exemplo e pode estar expirada.
  static const String _apiKey = 'pub_4ee4905895574d39a937badb0643d8bd'; 

  Future<List<NewsArticle>> fetchNews() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://newsdata.io/api/1/news?apikey=$_apiKey&country=br&language=pt&category=top'
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List results = data['results'] ?? [];
          return results.map((json) => NewsArticle.fromJson(json)).toList();
        }
      }
      return _getMockNews();
    } catch (e) {
      return _getMockNews();
    }
  }

  List<NewsArticle> _getMockNews() {
    return [
      NewsArticle(
        title: 'Bolsa de Valores fecha em alta com otimismo no setor de tecnologia',
        description: 'Investidores reagem positivamente aos balanços trimestrais das gigantes do setor.',
        source: 'Portal Econômico',
        link: 'https://g1.globo.com/economia/',
      ),
      NewsArticle(
        title: 'Brasil atinge marca histórica na exportação de energia limpa',
        description: 'País se consolida como líder global em matriz energética sustentável.',
        source: 'Notícias Sustentáveis',
        link: 'https://www.cnnbrasil.com.br/',
      ),
      NewsArticle(
        title: 'Estudo revela segredos da longevidade em populações litorâneas',
        description: 'Pesquisa acompanhou mil idosos durante uma década para entender hábitos saudáveis.',
        source: 'Saúde & Bem-Estar',
        link: 'https://saude.abril.com.br/',
      ),
    ];
  }
}

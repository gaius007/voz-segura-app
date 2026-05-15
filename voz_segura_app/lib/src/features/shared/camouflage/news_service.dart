import 'dart:convert';
import 'package:http/http.dart' as http;

class NewsArticle {
  final String title;
  final String description;
  final String? imageUrl;
  final String? source;
  final String? content;

  NewsArticle({
    required this.title,
    required this.description,
    this.imageUrl,
    this.source,
    this.content,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      source: json['source_id'],
      content: json['content'],
    );
  }
}

class NewsService {
  // ATENÇÃO: O usuário deve substituir esta chave pela sua chave real do NewsData.io
  static const String _apiKey = 'pub_4ee4905895574d39a937badb0643d8bd'; // Exemplo de formato

  Future<List<NewsArticle>> fetchNews() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://newsdata.io/api/1/news?apikey=$_apiKey&country=br&language=pt&category=top'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        return results.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        return _getMockNews();
      }
    } catch (e) {
      return _getMockNews();
    }
  }

  List<NewsArticle> _getMockNews() {
    return [
      NewsArticle(
        title: 'Mercado financeiro apresenta estabilidade nesta manhã',
        description: 'Os principais índices da bolsa operam em leve alta acompanhando o cenário externo.',
        source: 'Economia Hoje',
      ),
      NewsArticle(
        title: 'Novas tecnologias de irrigação aumentam produtividade no campo',
        description: 'Produtores rurais do interior de São Paulo adotam sistemas inteligentes para otimizar o uso da água.',
        source: 'Agro News',
      ),
      NewsArticle(
        title: 'Cresce a busca por cursos de especialização técnica',
        description: 'Instituições de ensino relatam aumento de 25% na procura por cursos de curta duração em tecnologia.',
        source: 'Educação & Carreira',
      ),
      NewsArticle(
        title: 'Previsão do tempo indica chuvas isoladas na região sul',
        description: 'Frente fria deve chegar ao litoral catarinense no final de semana, trazendo queda nas temperaturas.',
        source: 'Clima Tempo',
      ),
    ];
  }
}

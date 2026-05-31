import 'dart:convert';
import 'dart:math';
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

  final Random _random = Random();

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
          if (results.isNotEmpty) {
            final articles = results.map((json) => NewsArticle.fromJson(json)).toList();
            articles.shuffle(_random); // varia a ordem a cada abertura
            return articles;
          }
        }
      }
      return _getRandomMockNews();
    } catch (e) {
      return _getRandomMockNews();
    }
  }

  // Seleciona uma amostra aleatória do pool local para que a notícia falsa
  // varie a cada abertura/refresh, mesmo sem conexão ou chave de API válida.
  List<NewsArticle> _getRandomMockNews({int count = 6}) {
    final pool = List<NewsArticle>.from(_mockNewsPool)..shuffle(_random);
    return pool.take(count.clamp(1, pool.length)).toList();
  }

  static final List<NewsArticle> _mockNewsPool = [
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
    NewsArticle(
      title: 'Nova linha de metrô deve reduzir tempo de deslocamento na capital',
      description: 'Obra entra na fase final e promete beneficiar mais de 500 mil passageiros por dia.',
      source: 'Cidades Hoje',
      link: 'https://g1.globo.com/',
    ),
    NewsArticle(
      title: 'Seleção brasileira confirma amistosos antes da próxima competição',
      description: 'Comissão técnica divulga lista de convocados e calendário de preparação.',
      source: 'Esporte Total',
      link: 'https://ge.globo.com/',
    ),
    NewsArticle(
      title: 'Inteligência artificial começa a transformar o atendimento ao cliente',
      description: 'Empresas relatam ganhos de produtividade com novas ferramentas automatizadas.',
      source: 'Tech Brasil',
      link: 'https://www.tecmundo.com.br/',
    ),
    NewsArticle(
      title: 'Previsão aponta semana de chuvas em boa parte do país',
      description: 'Meteorologistas recomendam atenção a alagamentos nas regiões metropolitanas.',
      source: 'Clima & Tempo',
      link: 'https://www.climatempo.com.br/',
    ),
    NewsArticle(
      title: 'Festival de cinema nacional anuncia filmes selecionados deste ano',
      description: 'Mostra reúne produções independentes de todas as regiões do Brasil.',
      source: 'Cultura em Foco',
      link: 'https://www.adorocinema.com/',
    ),
    NewsArticle(
      title: 'Pequenos negócios impulsionam geração de empregos no trimestre',
      description: 'Setor de serviços lidera contratações segundo levantamento divulgado nesta semana.',
      source: 'Mercado & Negócios',
      link: 'https://www.infomoney.com.br/',
    ),
    NewsArticle(
      title: 'Pesquisadores desenvolvem método mais barato para tratar água',
      description: 'Tecnologia nacional pode levar saneamento a comunidades remotas.',
      source: 'Ciência Diária',
      link: 'https://revistapesquisa.fapesp.br/',
    ),
    NewsArticle(
      title: 'Dicas de organização ajudam a manter a rotina mais leve em casa',
      description: 'Especialistas indicam hábitos simples para reduzir o estresse do dia a dia.',
      source: 'Vida Prática',
      link: 'https://casavogue.globo.com/',
    ),
    NewsArticle(
      title: 'Turismo doméstico cresce e movimenta destinos do interior',
      description: 'Viajantes buscam roteiros de natureza e gastronomia regional nas férias.',
      source: 'Viagem & Lazer',
      link: 'https://viagemeturismo.abril.com.br/',
    ),
  ];
}

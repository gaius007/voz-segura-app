import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'camouflage_notifier.dart';
import 'news_service.dart';

class CamouflageView extends StatefulWidget {
  const CamouflageView({super.key});

  @override
  State<CamouflageView> createState() => _CamouflageViewState();
}

class _CamouflageViewState extends State<CamouflageView> {
  final NewsService _newsService = NewsService();
  List<NewsArticle> _articles = [];
  bool _isLoading = true;
  Timer? _longPressTimer;
  DateTime? _pressStartTime;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final news = await _newsService.fetchNews();
    if (mounted) {
      setState(() {
        _articles = news;
        _isLoading = false;
      });
    }
  }

  void _onPressDown() {
    _pressStartTime = DateTime.now();
    _longPressTimer?.cancel();
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final elapsed = DateTime.now().difference(_pressStartTime!).inMilliseconds;
      setState(() {
        _progress = (elapsed / 5000.0).clamp(0.0, 1.0);
      });
      
      if (_progress >= 1.0) {
        timer.cancel();
        _deactivate();
      }
    });
  }

  void _onPressUp() {
    _longPressTimer?.cancel();
    setState(() {
      _progress = 0.0;
    });
  }

  void _deactivate() {
    context.read<CamouflageNotifier>().setCamouflaged(false);
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Se falhar, abre internamente como fallback
      _openFakeArticle('Notícia', 'Não foi possível carregar o link original.');
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CamouflageNotifier>();
    final secretWord = notifier.secretWord;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'DIÁRIO DE NOTÍCIAS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontFamily: 'Serif',
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: _loadNews,
              color: Colors.black,
              child: ListView.separated(
                itemCount: _articles.length + 1,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black26),
                itemBuilder: (context, index) {
                  // Inserir a notícia secreta na 3ª posição
                  if (index == 2) {
                    return _buildSecretArticle(secretWord);
                  }

                  final articleIndex = index > 2 ? index - 1 : index;
                  if (articleIndex >= _articles.length) return const SizedBox.shrink();
                  
                  final article = _articles[articleIndex];
                  return _buildNewsItem(article);
                },
              ),
            ),
    );
  }

  Widget _buildNewsItem(NewsArticle article) {
    return InkWell(
      onTap: () => _launchURL(article.link),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null) ...[
              Image.network(
                article.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheHeight: 300,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              article.source?.toUpperCase() ?? 'PORTAL BRASIL',
              style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              article.title.toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'Serif',
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              article.description,
              style: TextStyle(color: Colors.grey[800], fontSize: 14, fontFamily: 'Serif'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecretArticle(String secretWord) {
    return GestureDetector(
      onTapDown: (_) => _onPressDown(),
      onTapUp: (_) => _onPressUp(),
      onTapCancel: () => _onPressUp(),
      onTap: () {
        // Se clicar rápido, apenas abre o artigo fake
        _openFakeArticle(secretWord, 'Este artigo contém informações detalhadas sobre o cenário atual do mercado e tendências tecnológicas.');
      },
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: _progress > 0 ? Colors.grey[200] : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESPECIAL'.toUpperCase(),
                  style: TextStyle(color: Colors.grey[700], fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  secretWord.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Serif',
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Acompanhe nossa cobertura completa sobre este tema que está dominando as discussões globais nesta semana.',
                  style: TextStyle(color: Colors.black87, fontSize: 14, fontFamily: 'Serif'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_progress > 0)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                minHeight: 6,
              ),
            ),
        ],
      ),
    );
  }

  void _openFakeArticle(String title, String content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('NOTÍCIA', style: TextStyle(color: Colors.white, fontFamily: 'Serif')),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Serif'),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.black, thickness: 2),
                const SizedBox(height: 16),
                Text(
                  content + '\n\n' + 'Conteúdo jornalístico simulado para manter a integridade do modo camuflagem. ' * 15,
                  style: const TextStyle(fontSize: 16, fontFamily: 'Serif', height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  void _startTimer(BuildContext context) {
    setState(() => _progress = 0.0);
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.02; // 0.02 * 50 steps = 1.0 (5 seconds)
      });
      if (_progress >= 1.0) {
        timer.cancel();
        context.read<CamouflageNotifier>().setCamouflaged(false);
      }
    });
  }

  void _cancelTimer() {
    _longPressTimer?.cancel();
    setState(() {
      _progress = 0.0;
    });
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
          : ListView.separated(
              itemCount: _articles.length + 1, // +1 para a notícia secreta
              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black26),
              itemBuilder: (context, index) {
                // Inserimos a notícia secreta no meio da lista (ex: posição 2)
                if (index == 2) {
                  return _buildSecretArticle(context, secretWord);
                }

                final articleIndex = index > 2 ? index - 1 : index;
                if (articleIndex >= _articles.length) return const SizedBox.shrink();
                
                final article = _articles[articleIndex];
                return _buildNewsItem(context, article);
              },
            ),
    );
  }

  Widget _buildNewsItem(BuildContext context, NewsArticle article) {
    return InkWell(
      onTap: () => _openArticle(context, article.title, article.description),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.source?.toUpperCase() ?? 'NOTÍCIAS BRASIL',
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
            const SizedBox(height: 12),
            Text(
              article.description,
              style: TextStyle(color: Colors.grey[800], fontSize: 14, fontFamily: 'Serif'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecretArticle(BuildContext context, String secretWord) {
    return GestureDetector(
      onTap: () => _openArticle(context, secretWord, 'Conteúdo detalhado sobre esta notícia importante do dia.'),
      onLongPressStart: (_) => _startTimer(context),
      onLongPressEnd: (_) => _cancelTimer(),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: _progress > 0 ? Colors.grey[100] : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Destaque do Editor'.toUpperCase(),
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
                const SizedBox(height: 12),
                const Text(
                  'Análise profunda sobre os impactos globais e as novas tendências do setor para o próximo semestre.',
                  style: TextStyle(color: Colors.black87, fontSize: 14, fontFamily: 'Serif'),
                  maxLines: 2,
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
                minHeight: 4,
              ),
            ),
        ],
      ),
    );
  }

  void _openArticle(BuildContext context, String title, String content) {
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
                const Divider(color: Colors.black),
                const SizedBox(height: 16),
                Text(
                  content + '\n\n' + 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ' * 20,
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

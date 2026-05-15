import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'camouflage_notifier.dart';

class CamouflageView extends StatelessWidget {
  const CamouflageView({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<CamouflageNotifier>();
    final secretWord = notifier.secretWord;

    final newsList = [
      'Mercado financeiro apresenta estabilidade nesta manhã',
      'Novas tecnologias de irrigação aumentam produtividade no campo',
      'Cresce a busca por cursos de especialização técnica',
      secretWord, // A "notícia" de desativação
      'Previsão do tempo indica chuvas isoladas na região sul',
      'Exportações de grãos batem recorde no primeiro trimestre',
      'Infraestrutura urbana recebe novos investimentos estaduais',
      'Estudo aponta tendências para o mercado de trabalho em 2026',
    ];

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
            fontFamily: 'Serif', // Usando fonte serifada para parecer jornal
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(0),
        itemCount: newsList.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black26),
        itemBuilder: (context, index) {
          final title = newsList[index];
          final isSecret = title == secretWord;

          return InkWell(
            onTap: () {
              if (isSecret) {
                notifier.setCamouflaged(false);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POLÍTICA & ECONOMIA',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title.toUpperCase(),
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
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam...',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontFamily: 'Serif',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HÁ 2 HORAS',
                        style: TextStyle(color: Colors.grey[600], fontSize: 10),
                      ),
                      Icon(Icons.share_outlined, size: 16, color: Colors.grey[600]),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

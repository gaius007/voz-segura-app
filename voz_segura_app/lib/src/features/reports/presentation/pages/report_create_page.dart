import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../manager/report_notifier.dart';
import 'dart:io' as io;
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

class ReportCreatePage extends StatefulWidget {
  const ReportCreatePage({super.key});

  @override
  State<ReportCreatePage> createState() => _ReportCreatePageState();
}

class _ReportCreatePageState extends State<ReportCreatePage> {
  final TextEditingController _descController = TextEditingController();
  final List<String> _fotosLocais = [];
  final ImagePicker _picker = ImagePicker();
  bool _enviando = false;

  Future<void> _abrirCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() {
        _fotosLocais.add(image.path);
      });
    }
  }

  Future<void> _salvarNoFirebase() async {
    final texto = _descController.text;
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, descreva o acontecimento.')),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await context.read<ReportNotifier>().adicionarRelato(texto, _fotosLocais);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relato seguro enviado com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.ruby),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Novo Relato'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.sakura, Colors.white],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'DETALHES DO RELATO',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ruby, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    maxLines: 8,
                    enabled: !_enviando,
                    decoration: const InputDecoration(
                      hintText: 'Descreva aqui o que aconteceu com o máximo de detalhes possível para sua segurança...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'EVIDÊNCIAS VISUAIS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ruby, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _enviando ? null : _abrirCamera,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.rose.withOpacity(0.5), width: 1.5),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_enhance_rounded, size: 36, color: AppColors.primary),
                          SizedBox(height: 8),
                          Text(
                            'CAPTURAR EVIDÊNCIA',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_fotosLocais.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _fotosLocais.length,
                        itemBuilder: (context, index) {
                          final path = _fotosLocais[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Hero(
                              tag: 'new-photo-$index',
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppStyles.softShadow,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: kIsWeb 
                                    ? Image.network(path, width: 120, height: 120, fit: BoxFit.cover)
                                    : Image.file(io.File(path), width: 120, height: 120, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 60),
                  _enviando 
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _salvarNoFirebase,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 65),
                          backgroundColor: AppColors.primary,
                          elevation: 10,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text(
                          'ENVIAR RELATO SEGURO',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white),
                        ),
                      ),
                  const SizedBox(height: 20),
                  const Text(
                    'Suas informações são criptografadas e protegidas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textLight, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

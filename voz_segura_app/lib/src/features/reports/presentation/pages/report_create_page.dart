import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../manager/report_notifier.dart';
// Removi o dart:io direto pra nao dar erro no navegador
// O professor disse que eh melhor usar o kIsWeb pra separar as coisas
import 'dart:io' as io; 

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
    // Diminui o tamanho da foto pra caber no Firestore (Plano B do professor)
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70, // Qualidade 70% ja ta otimo e fica leve
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
        const SnackBar(content: Text('Escreve o relato primeiro!')),
      );
      return;
    }

    setState(() => _enviando = true);
    try {
      await context.read<ReportNotifier>().adicionarRelato(texto, _fotosLocais);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relato enviado com sucesso! 🎉')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Relato'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'O que aconteceu?',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF4081)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descController,
                    maxLines: 6,
                    enabled: !_enviando,
                    decoration: InputDecoration(
                      hintText: 'Conte aqui os detalhes importantes...',
                      fillColor: Colors.white.withOpacity(0.8),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Fotos e Provas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _enviando ? null : _abrirCamera,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.pink.shade100, style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_a_photo_rounded, size: 32, color: Color(0xFFFF4081)),
                          Text('Tirar Foto', style: TextStyle(color: Color(0xFFFF4081), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_fotosLocais.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _fotosLocais.length,
                        itemBuilder: (context, index) {
                          final path = _fotosLocais[index];
                          
                          return TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 300),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, val, child) {
                              return Transform.scale(
                                scale: val,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    // Usei o kIsWeb pra nao dar o erro de Platform
                                    child: kIsWeb 
                                      ? Image.network(path, width: 120, height: 120, fit: BoxFit.cover)
                                      : Image.file(io.File(path), width: 120, height: 120, fit: BoxFit.cover),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 48),
                  _enviando 
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _salvarNoFirebase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4081),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('ENVIAR AGORA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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

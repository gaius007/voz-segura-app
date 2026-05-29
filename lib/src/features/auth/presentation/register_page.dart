import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../domain/auth_repository.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

// Tela pra criar conta no Firebase
// Agora com campo de telefone obrigatorio para vinculacao com WhatsApp (Evolution API)
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  // Mascara internacional do Brasil para o campo de telefone
  // Utiliza o mask_text_input_formatter que ja esta no pubspec.yaml
  final _phoneFormatter = MaskTextInputFormatter(
    mask: '+55 (##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    // Valida todos os campos do formulario antes de prosseguir
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Cria conta de autenticacao no Firebase Auth
      final appUser = await context.read<AuthRepository>().createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (appUser != null) {
        // 2. Formata o numero no padrao E.164 puro (+5511999999999)
        final rawNumber = _phoneFormatter.getUnmaskedText();
        final e164Phone = '+55$rawNumber';

        // 3. Registra perfil no Firestore com dados iniciais para a Evolution API
        await FirebaseFirestore.instance.collection('users').doc(appUser.uid).set({
          'uid': appUser.uid,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': e164Phone,
          'whatsappConnected': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) Navigator.pop(context); // volta pro login se deu certo
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar: $e'),
            backgroundColor: AppColors.ruby,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Nome Completo",
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "E-mail",
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O e-mail é obrigatório';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Insira um e-mail válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Senha",
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'A senha é obrigatória';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter no mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de telefone obrigatorio para vinculacao com WhatsApp
              TextFormField(
                controller: _phoneController,
                inputFormatters: [_phoneFormatter],
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textMain),
                decoration: const InputDecoration(
                  labelText: 'Número do WhatsApp *',
                  hintText: '+55 (11) 99999-9999',
                  prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O número de WhatsApp é obrigatório';
                  }
                  // Remove formatacao para validar tamanho bruto (DDD + numero)
                  final clean = _phoneFormatter.getUnmaskedText();
                  if (clean.length < 10 || clean.length > 11) {
                    return 'Insira um número válido com DDD';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),
              _isLoading
                ? const CircularProgressIndicator(color: AppColors.primary)
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onRegister,
                      child: const Text("Registrar"),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

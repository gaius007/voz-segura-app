import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../auth/data/auth_repository.dart';
import '../data/contact_repository.dart';
import '../domain/contact.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';

class EmergencyContactsPage extends StatelessWidget {
  const EmergencyContactsPage({super.key});

  void _showModal(BuildContext context, {Contact? contact}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactForm(contact: contact),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().currentUser;
    final repo = context.read<ContactRepository>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Rede de Apoio"),
      ),
      body: user == null
          ? const Center(child: Text("Faça login primeiro!"))
          : StreamBuilder<List<Contact>>(
              stream: repo.watchContacts(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final contacts = snapshot.data ?? [];
                
                if (contacts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 80, color: AppColors.rose.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text("Sua rede de apoio está vazia.", style: AppStyles.subtitle),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return _ContactCard(
                      contact: contact,
                      onEdit: () => _showModal(context, contact: contact),
                      onDelete: () => repo.deleteContact(user.uid, contact.id!),
                    );
                  },
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => _showModal(context),
          backgroundColor: AppColors.primary,
          label: const Text("NOVO CONTATO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        boxShadow: AppStyles.softShadow,
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.rose, AppColors.carnation],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMain),
                      ),
                      const SizedBox(height: 4),
                      ...contact.methods.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Icon(_getIconForType(m.type), size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(m.value, style: const TextStyle(fontSize: 13, color: AppColors.textLight)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'WhatsApp': return Icons.message_rounded;
      case 'Telefone': return Icons.phone_rounded;
      case 'E-mail': return Icons.email_rounded;
      default: return Icons.contact_page_rounded;
    }
  }
}

class ContactForm extends StatefulWidget {
  final Contact? contact;
  const ContactForm({super.key, this.contact});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final List<_MethodEntry> _methodEntries = [];
  bool _salvando = false;

  final _maskCelular = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    if (widget.contact != null) {
      for (var m in widget.contact!.methods) {
        _methodEntries.add(_MethodEntry(
          controller: TextEditingController(text: m.value),
          type: m.type,
        ));
      }
    } else {
      _addMethod();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var m in _methodEntries) {
      m.controller.dispose();
    }
    super.dispose();
  }

  void _addMethod() {
    setState(() {
      _methodEntries.add(_MethodEntry(
        controller: TextEditingController(),
        type: 'WhatsApp',
      ));
    });
  }

  void _removeMethod(int index) {
    setState(() {
      _methodEntries[index].controller.dispose();
      _methodEntries.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _salvando = true);
    final user = context.read<AuthRepository>().currentUser;
    if (user == null) return;

    try {
      final contact = Contact(
        id: widget.contact?.id,
        name: _nameController.text,
        methods: _methodEntries.map((e) => ContactMethod(type: e.type, value: e.controller.text)).toList(),
      );

      final repo = context.read<ContactRepository>();
      if (widget.contact == null) {
        await repo.addContact(user.uid, contact);
      } else {
        await repo.updateContact(user.uid, contact);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  widget.contact == null ? "Novo Contato" : "Editar Contato",
                  style: AppStyles.h1.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  enabled: !_salvando,
                  decoration: const InputDecoration(
                    labelText: "Nome do Contato",
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => v!.isEmpty ? "Nome obrigatório" : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text("MEIOS DE CONTATO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight, letterSpacing: 1.1)),
                    const Spacer(),
                    IconButton(
                      onPressed: _salvando ? null : _addMethod,
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...List.generate(_methodEntries.length, (index) {
                  final entry = _methodEntries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: entry.type,
                            items: ['WhatsApp', 'Telefone', 'E-mail'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14)))).toList(),
                            onChanged: _salvando ? null : (v) => setState(() => entry.type = v!),
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: entry.controller,
                            enabled: !_salvando,
                            inputFormatters: (entry.type != 'E-mail') ? [_maskCelular] : [],
                            keyboardType: entry.type == 'E-mail' ? TextInputType.emailAddress : TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: entry.type == 'E-mail' ? "email@exemplo.com" : "(00) 00000-0000",
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            validator: (v) => v!.isEmpty ? "Vazio" : null,
                          ),
                        ),
                        if (_methodEntries.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: _salvando ? null : () => _removeMethod(index),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),
                _salvando 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("SALVAR ALTERAÇÕES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodEntry {
  final TextEditingController controller;
  String type;
  _MethodEntry({required this.controller, required this.type});
}

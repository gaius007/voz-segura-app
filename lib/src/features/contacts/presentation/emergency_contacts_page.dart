import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/usecases/watch_contacts.dart';
import '../domain/usecases/add_contact.dart';
import '../domain/usecases/update_contact.dart';
import '../domain/usecases/delete_contact.dart';
import '../domain/contact.dart';
import 'package:voz_segura_app/src/core/theme/app_theme.dart';
import 'package:voz_segura_app/src/core/widgets/confirm_dialog.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  // Stream mantido em cache para não re-assinar o Firestore a cada rebuild do widget.
  Stream<List<Contact>>? _contactsStream;
  String? _cachedUid;

  void _showModal(BuildContext context, {Contact? contact}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactForm(contact: contact),
    );
  }

  Future<bool> _confirmarExclusao(BuildContext context, Contact contact) {
    return showConfirmDialog(
      context,
      title: 'Excluir Contato',
      message:
          'Deseja remover "${contact.name}" da sua rede de apoio? Essa ação não poderá ser desfeita.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthRepository>().currentUser;
    final watchContacts = context.read<WatchContacts>();
    final deleteContact = context.read<DeleteContact>();

    // Cria o stream apenas quando o usuário muda; reusa a mesma assinatura nos demais builds.
    if (user != null && _cachedUid != user.uid) {
      _cachedUid = user.uid;
      _contactsStream = watchContacts.execute(user.uid);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Rede de Apoio"),
      ),
      body: user == null
          ? const Center(child: Text("Faça login primeiro!"))
          : StreamBuilder<List<Contact>>(
              stream: _contactsStream,
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
                        Icon(Icons.people_outline_rounded, size: 80, color: context.appRose.withOpacity(0.5)),
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
                    return Dismissible(
                      key: ValueKey(contact.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) => _confirmarExclusao(context, contact),
                      onDismissed: (_) => deleteContact.execute(user.uid, contact.id!),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.only(right: 28),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: context.appRuby,
                          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                      ),
                      child: _ContactCard(
                        contact: contact,
                        onEdit: () => _showModal(context, contact: contact),
                        onDelete: () async {
                          if (await _confirmarExclusao(context, contact)) {
                            await deleteContact.execute(user.uid, contact.id!);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: FloatingActionButton.extended(
          onPressed: () => _showModal(context),
          backgroundColor: context.appPrimary,
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
        color: context.appGlassColor,
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
        boxShadow: context.appSoftShadow,
        border: Border.all(color: context.appGlassBorder),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.appTextMain),
                      ),
                      const SizedBox(height: 4),
                      ...contact.methods.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Icon(_getIconForType(m.type), size: 14, color: context.appPrimary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                m.value,
                                style: TextStyle(fontSize: 13, color: context.appTextLight),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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

      if (widget.contact == null) {
        await context.read<AddContact>().execute(user.uid, contact);
      } else {
        await context.read<UpdateContact>().execute(user.uid, contact);
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
        decoration: BoxDecoration(
          color: context.appCardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
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
                    color: context.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  widget.contact == null ? "Novo Contato" : "Editar Contato",
                  style: AppStyles.h1.copyWith(fontSize: 22, color: context.appRuby),
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
                    Text("MEIOS DE CONTATO", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.appTextLight, letterSpacing: 1.1)),
                    const Spacer(),
                    IconButton(
                      onPressed: _salvando ? null : _addMethod,
                      icon: Icon(Icons.add_circle_outline_rounded, color: context.appPrimary),
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
                            dropdownColor: context.appCardColor,
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
                  ? CircularProgressIndicator(color: context.appPrimary)
                  : ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60),
                        backgroundColor: context.appPrimary,
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

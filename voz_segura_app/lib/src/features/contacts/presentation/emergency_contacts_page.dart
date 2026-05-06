import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../data/firestore_contact_repository.dart';
import '../domain/contact.dart';
import 'contacts_controller.dart';

class EmergencyContactsPage extends ConsumerStatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  ConsumerState<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends ConsumerState<EmergencyContactsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  String _selectedType = 'WhatsApp';

  final _phoneMask = MaskTextInputFormatter(
    mask: '+## (##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final List<String> _contactTypes = ['WhatsApp', 'Telefone', 'E-mail', 'Instagram', 'Outro'];

  IconData _getIconForType(String type) {
    return switch (type) {
      'WhatsApp' => Icons.chat_bubble_outline,
      'Telefone' => Icons.phone_outlined,
      'E-mail' => Icons.email_outlined,
      'Instagram' => Icons.camera_alt_outlined,
      _ => Icons.contact_emergency_outlined,
    };
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.pinkAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showContactModal({Contact? contact}) {
    if (contact != null) {
      _nameController.text = contact.name;
      _valueController.text = contact.value;
      _selectedType = contact.type;
    } else {
      _nameController.clear();
      _valueController.clear();
      _selectedType = 'WhatsApp';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    contact == null ? "Novo Contato" : "Editar Contato",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Nome completo",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v!.isEmpty ? "Informe o nome" : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: "Tipo de contato",
                      prefixIcon: Icon(_getIconForType(_selectedType)),
                    ),
                    items: _contactTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setModalState(() => _selectedType = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _valueController,
                    inputFormatters: (_selectedType == 'WhatsApp' || _selectedType == 'Telefone') ? [_phoneMask] : [],
                    keyboardType: (_selectedType == 'E-mail') ? TextInputType.emailAddress : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: _selectedType == 'E-mail' ? "Endereço de E-mail" : "Valor do Contato",
                      prefixIcon: const Icon(Icons.link_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Campo obrigatório";
                      if (_selectedType == 'E-mail' && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                        return "E-mail inválido";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _saveContact(contact?.id),
                    child: Text(contact == null ? "Adicionar" : "Salvar Alterações"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveContact(String? id) async {
    if (!_formKey.currentState!.validate()) return;

    final contact = Contact(
      id: id,
      name: _nameController.text.trim(),
      type: _selectedType,
      value: _valueController.text.trim(),
    );

    await ref.read(contactsControllerProvider.notifier).saveContact(contact);
    
    if (mounted) {
      Navigator.pop(context);
      _showSnackBar(id == null ? "Contato salvo!" : "Contato atualizado!");
    }
  }

  Future<void> _deleteContact(String contactId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remover da Rede?"),
        content: const Text("Este contato não será alertado em emergências."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remover", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(contactsControllerProvider.notifier).deleteContact(contactId);
      _showSnackBar("Contato removido");
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Rede de Apoio")),
      body: contactsAsync.when(
        data: (contacts) => contacts.isEmpty
            ? const Center(child: Text("Sua rede de apoio está vazia"))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: contacts.length,
                itemBuilder: (context, index) => ContactCard(
                  contact: contacts[index],
                  onEdit: () => _showContactModal(contact: contacts[index]),
                  onDelete: () => _deleteContact(contacts[index].id!),
                  icon: _getIconForType(contacts[index].type),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Erro: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactModal(),
        backgroundColor: Colors.pink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final IconData icon;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onEdit,
    required this.onDelete,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onEdit(),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Editar',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Excluir',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.pink.shade100,
                  child: Icon(icon, color: Colors.pink),
                ),
                title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${contact.type} • ${contact.value}"),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

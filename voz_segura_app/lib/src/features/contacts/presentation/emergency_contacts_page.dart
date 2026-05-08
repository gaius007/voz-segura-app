import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/data/auth_repository.dart';
import '../data/contact_repository.dart';
import '../domain/contact.dart';

// Tela pra gerenciar a rede de apoio (os contatos de emergencia)
class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  String _selectedType = 'WhatsApp';

  // Modal pra adicionar ou editar contato
  void _showModal({Contact? contact}) {
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
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contact == null ? "Novo Contato" : "Editar Contato",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF4081)),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Nome", border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? "Nao esquece do nome!" : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: ['WhatsApp', 'Telefone', 'E-mail'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _selectedType = v!),
                  decoration: const InputDecoration(labelText: "Tipo de Contato", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valueController,
                  decoration: const InputDecoration(labelText: "Numero ou Link", border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? "Precisa colocar o contato!" : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _save(contact?.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4081),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("SALVAR CONTATO"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Salva no Firestore do Firebase
  Future<void> _save(String? id) async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = context.read<AuthRepository>().currentUser;
    if (user == null) return;

    final contact = Contact(
      id: id,
      name: _nameController.text,
      type: _selectedType,
      value: _valueController.text,
    );

    if (id == null) {
      await context.read<ContactRepository>().addContact(user.uid, contact);
    } else {
      await context.read<ContactRepository>().updateContact(user.uid, contact);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthRepository>().currentUser;
    final repo = context.read<ContactRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Rede de Apoio"),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.pink.shade50],
          ),
        ),
        child: Center( // Deixando responsivo pra web
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: user == null
                ? const Center(child: Text("Faca login primeiro!"))
                : StreamBuilder<List<Contact>>(
                    stream: repo.watchContacts(user.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final contacts = snapshot.data ?? [];
                      
                      if (contacts.isEmpty) {
                        return const Center(child: Text("Sua rede de apoio esta vazia."));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFF80AB),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("${contact.type}: ${contact.value}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showModal(contact: contact)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => repo.deleteContact(user.uid, contact.id!)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => _showModal(),
          backgroundColor: const Color(0xFFFF4081),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

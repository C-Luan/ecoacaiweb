import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo de Dados para mapear o documento Firestore
class PostoModel {
  final String id;
  final String name;
  final String address;
  final String owner; // Proprietário (Nome do Cidadão)
  final String cidadaoId; // Proprietário (UID do Cidadão)
  final bool isActive;

  PostoModel({
    required this.id,
    required this.name,
    required this.address,
    required this.owner,
    required this.cidadaoId,
    required this.isActive,
  });

  // Factory para criar o modelo a partir do documento Firestore
  factory PostoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    // Assumimos que 'endereco' é um mapa, e 'isActive' e 'cidadaoId' existem
    final addressMap = data?['endereco'] as Map<String, dynamic>? ?? {};
    final fullAddress = '${addressMap['rua'] ?? ''}, ${addressMap['numero'] ?? ''}, ${addressMap['municipio'] ?? ''}';

    return PostoModel(
      id: doc.id,
      name: data?['nome'] ?? 'Posto Sem Nome',
      address: fullAddress,
      cidadaoId: data?['cidadaoId'] ?? '',
      // NOTA: O nome do proprietário (owner) será buscado separadamente ou cacheado
      owner: 'Buscando...', // Placeholder inicial
      isActive: data?['isActive'] ?? false,
    );
  }
}

class PostoScreen extends StatefulWidget {
  const PostoScreen({super.key});

  @override
  State<PostoScreen> createState() => _PostoScreenState();
}

class _PostoScreenState extends State<PostoScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // A coleção de postos
  late Stream<QuerySnapshot> _postosStream;

  @override
  void initState() {
    super.initState();
    // Consulta inicial: carrega todos os postos (seguindo a regra Admin/Proprietário)
    _postosStream = _db.collection('postos').snapshots();
  }

  // Função para alternar o status (Ativo/Inativo)
  Future<void> _togglePostoStatus(String postoId, bool currentStatus) async {
    try {
      await _db.collection('postos').doc(postoId).update({
        'isActive': !currentStatus,
      });
    } catch (e) {
      // Exibe erro de segurança caso as regras do Firestore falhem
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao atualizar status: Verifique regras de segurança. $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (Métodos _buildHeader e _buildPostoListItem, que estão abaixo) ...

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(toolbarHeight: 0, backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(context),
            const SizedBox(height: 24),

            // StreamBuilder para renderizar a lista em tempo real
            StreamBuilder<QuerySnapshot>(
              stream: _postosStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum posto cadastrado.'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final posto = PostoModel.fromFirestore(snapshot.data!.docs[index]);
                    return _buildPostoListItem(context, posto);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Replicando o Widget de Item de Lista com a lógica de dados real
  Widget _buildPostoListItem(BuildContext context, PostoModel posto) {
    final statusText = posto.isActive ? 'Ativo' : 'Inativo';
    final statusColor = posto.isActive ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          radius: 24,
          child: Icon(Icons.store, color: Colors.teal.shade700, size: 24),
        ),
        title: Text(posto.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(posto.address, style: const TextStyle(fontSize: 14)),
            // O nome do proprietário requer uma busca adicional (idealmente, cacheada)
            FutureBuilder<DocumentSnapshot>(
              future: _db.collection('cidadaos').doc(posto.cidadaoId).get(),
              builder: (context, snapshot) {
                String ownerName = 'Buscando...';
                if (snapshot.hasData && snapshot.data!.exists) {
                  ownerName = snapshot.data!['nome'] ?? 'Nome Desconhecido';
                }
                return Text('Proprietário: $ownerName',
                    style: const TextStyle(fontSize: 12, color: Colors.black54));
              },
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(statusText,
                style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
            const SizedBox(width: 8),

            // Botão Editar (Ação de Navegação)
            InkWell(
              onTap: () {
                // Navegar para a tela de edição
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                  SizedBox(width: 2),
                  Text('Editar', style: TextStyle(color: Colors.blue)),
                ]),
              ),
            ),
            const SizedBox(width: 8),

            // Botão Ativar/Desativar (Ação de Firestore)
            InkWell(
              onTap: () => _togglePostoStatus(posto.id, posto.isActive),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(children: [
                  Icon(
                      posto.isActive ? Icons.close : Icons.check,
                      size: 18,
                      color: posto.isActive ? Colors.red.shade700 : Colors.green.shade700),
                  const SizedBox(width: 2),
                  Text(
                    posto.isActive ? 'Desativar' : 'Ativar',
                    style: TextStyle(
                      color: posto.isActive ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
        onTap: () {
          // Ação UX: Abrir detalhes
        },
      ),
    );
  }
  
  // Replicando o Widget de Cabeçalho
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gerenciamento de Postos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Gerencie todos os postos de coleta', style: TextStyle(fontSize: 16, color: Colors.black54)),
          ],
        ),
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navegar para a tela de criação de novo posto
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Novo Posto'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            ),
          ),
        ),
      ],
    );
  }
}
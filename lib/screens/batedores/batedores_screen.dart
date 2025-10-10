import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Necessário para formatar a data

// Modelo de Dados para mapear o documento Firestore
class CidadaoModel {
  final String id;
  final String nome;
  final String email;
  final String cpf;
  final String telefone;
  final DateTime dataCadastro;

  CidadaoModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.cpf,
    required this.telefone,
    required this.dataCadastro,
  });

  factory CidadaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CidadaoModel(
      id: doc.id,
      nome: data['nome'] ?? 'Nome Ausente',
      email: data['email'] ?? 'email@ausente.com',
      cpf: data['cpf'] ?? '000.000.000-00',
      telefone: data['telefone'] ?? '(99) 99999-9999',
      dataCadastro:
          (data['dataCadastro'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CidadaosScreen extends StatefulWidget {
  const CidadaosScreen({super.key});

  @override
  State<CidadaosScreen> createState() => _CidadaosScreenState();
}

class _CidadaosScreenState extends State<CidadaosScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  // Lista que armazena todos os cidadãos para a busca local
  List<CidadaoModel> _allCidadaos = [];
  // Lista exibida na UI após o filtro
  List<CidadaoModel> _filteredCidadaos = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCidadaos);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCidadaos);
    _searchController.dispose();
    super.dispose();
  }

  // 1. Lógica de Filtragem Local (Multi-Campo)
  void _filterCidadaos() {
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredCidadaos = _allCidadaos;
      });
      return;
    }

    setState(() {
      _filteredCidadaos = _allCidadaos.where((cidadao) {
        return cidadao.nome.toLowerCase().contains(query) ||
            cidadao.email.toLowerCase().contains(query) ||
            cidadao.cpf.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Título
            const Text(
              'Gerenciamento de Cidadãos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Visualize e gerencie todos os cidadãos cadastrados',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Campo de Busca
            _buildSearchBar(context),
            const SizedBox(height: 24),

            // StreamBuilder para carregar dados do Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('cidadaos').orderBy('nome').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erro ao carregar dados: ${snapshot.error}'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Mapeia todos os documentos para o modelo
                  final cidadaosList = snapshot.data!.docs
                      .map((doc) => CidadaoModel.fromFirestore(doc))
                      .toList();

                  // Atualiza as listas (evita rebuilds desnecessários no setState do _filterCidadaos)
                  // Só atualiza se houver uma mudança nos dados do Firestore
                  if (_allCidadaos.length != cidadaosList.length) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _allCidadaos = cidadaosList;
                        _filterCidadaos();
                      });
                    });
                  } else if (_filteredCidadaos.isEmpty &&
                      _searchController.text.isEmpty) {
                    // Inicializa a lista filtrada se a busca estiver vazia
                    _allCidadaos = cidadaosList;
                    _filteredCidadaos = _allCidadaos;
                  }

                  if (_filteredCidadaos.isEmpty &&
                      _searchController.text.isNotEmpty) {
                    return const Center(
                      child: Text('Nenhum cidadão encontrado com a busca.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: _filteredCidadaos.length,
                    itemBuilder: (context, index) {
                      return _buildCidadaoListItem(_filteredCidadaos[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Widget de Busca (UI)
  Widget _buildSearchBar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, email ou CPF...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed:
                _filterCidadaos, // Gatilho de filtro (embora o listener faça o trabalho)
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Buscar', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  // 3. Widget de Item de Lista (UI)
  Widget _buildCidadaoListItem(CidadaoModel cidadao) {
    final registrationDate = DateFormat(
      'dd/MM/yyyy',
    ).format(cidadao.dataCadastro);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          radius: 24,
          child: Text(
            cidadao.nome.substring(0, 1),
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          cidadao.nome,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cidadao.email, style: const TextStyle(fontSize: 14)),
            Text(
              'CPF: ${cidadao.cpf}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('(${cidadao.telefone})', style: const TextStyle(fontSize: 14)),
            Text(
              'Cadastrado em $registrationDate',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          // Ação: Navegar para detalhes de edição do cidadão
        },
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AcompanhamentoSolicitacoesScreen extends StatefulWidget {
  const AcompanhamentoSolicitacoesScreen({Key? key}) : super(key: key);

  @override
  State<AcompanhamentoSolicitacoesScreen> createState() =>
      _AcompanhamentoSolicitacoesScreenState();
}

class _AcompanhamentoSolicitacoesScreenState
    extends State<AcompanhamentoSolicitacoesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Stream<QuerySnapshot> _solicitacoesStream;
  List<Map<String, dynamic>> _postosDropdown = [];

  bool _isLoadingPostos = true;
  String _selectedPostoId = 'todos';

  DateTime _dataInicial = DateTime.now();
  DateTime _dataFinal = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchPostosForDropdown().then((_) {
      _solicitacoesStream = _buildQuery();
      setState(() {});
    });
  }

  Future<void> _fetchPostosForDropdown() async {
    final snapshot = await _firestore.collection('postos').get();
    final fetchedPostos = snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, 'nome': data['nome'] ?? 'Sem nome'};
    }).toList();

    setState(() {
      _postosDropdown = [
        {'id': 'todos', 'nome': 'Todos os postos'},
        ...fetchedPostos,
      ];
      _selectedPostoId = 'todos';
      _isLoadingPostos = false;
    });
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = _firestore.collection('solicitacoes');

    if (_selectedPostoId != 'todos') {
      query = query.where('postoId', isEqualTo: _selectedPostoId);
    }

    query = query
        .where(
          'dataCriacao',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            _dataInicial.subtract(const Duration(days: 1)),
          ),
        )
        .where(
          'dataCriacao',
          isLessThanOrEqualTo: Timestamp.fromDate(
            _dataFinal.add(const Duration(days: 1)),
          ),
        )
        .orderBy('dataCriacao', descending: true);

    return query.snapshots();
  }

  Future<Map<String, dynamic>?> _buscarPosto(String postoId) async {
    if (postoId.isEmpty) return null;
    final doc = await _firestore.collection('postos').doc(postoId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acompanhamento de Solicitações')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFiltros(),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoadingPostos
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                      stream: _solicitacoesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('Nenhuma solicitação encontrada.'),
                          );
                        }

                        final solicitacoes = snapshot.data!.docs;

                        return ListView.builder(
                          itemCount: solicitacoes.length,
                          itemBuilder: (context, index) {
                            final doc = solicitacoes[index];
                            final data =
                                doc.data() as Map<String, dynamic>? ?? {};

                            final postoId = data['postoId'] ?? '';
                            final descricao =
                                '${double.parse(data['quantidadeEstimada'].toString()).toStringAsFixed(2)} Kg';
                            final dataAgendada = data['dataSolicitacao'] != null
                                ? DateFormat('dd/MM/yyyy').format(
                                    (data['dataSolicitacao'] as Timestamp)
                                        .toDate(),
                                  )
                                : 'Sem data';

                            return FutureBuilder<Map<String, dynamic>?>(
                              future: _buscarPosto(postoId),
                              builder: (context, postoSnapshot) {
                                if (postoSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const ListTile(
                                    title: Text('Carregando posto...'),
                                  );
                                }

                                final posto = postoSnapshot.data;
                                final nomePosto =
                                    posto?['nome'] ?? 'Posto não encontrado';
                                String endereco = 'Endereço não informado';

                                final enderecoData = posto?['endereco'];
                                if (enderecoData is Map) {
                                  final rua = enderecoData['rua'] ?? '';
                                  final numero = enderecoData['numero'] ?? '';
                                  final bairro = enderecoData['bairro'] ?? '';
                                  endereco = [
                                    rua,
                                    numero,
                                    bairro,
                                  ].where((e) => e.isNotEmpty).join(', ');
                                } else if (enderecoData is String) {
                                  endereco = enderecoData;
                                }

                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      nomePosto,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(endereco),
                                        const SizedBox(height: 4),
                                        Text(descricao),
                                        const SizedBox(height: 4),
                                        Text('Agendamento: $dataAgendada'),
                                      ],
                                    ),
                                    onTap: () => _abrirDetalhesSolicitacao(
                                      context,
                                      data,
                                      posto,
                                    ),
                                  ),
                                );
                              },
                            );
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

  Widget _buildFiltros() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _selectedPostoId,
            items: _postosDropdown
                .map(
                  (posto) => DropdownMenuItem<String>(
                    value: posto['id'],
                    child: Text(posto['nome']),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedPostoId = value!;
              });
            },
            decoration: const InputDecoration(labelText: 'Posto'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: InputDatePickerFormField(
            initialDate: _dataInicial,
            firstDate: DateTime(2024),
            lastDate: DateTime(2100),
            onDateSubmitted: (date) {
              setState(() => _dataInicial = date);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: InputDatePickerFormField(
            initialDate: _dataFinal,
            firstDate: DateTime(2024),
            lastDate: DateTime(2100),
            onDateSubmitted: (date) {
              setState(() => _dataFinal = date);
            },
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _solicitacoesStream = _buildQuery();
            });
          },
          icon: const Icon(Icons.filter_list),
          label: const Text('Filtrar'),
        ),
      ],
    );
  }

  void _abrirDetalhesSolicitacao(
    BuildContext context,
    Map<String, dynamic> solicitacao,
    Map<String, dynamic>? posto,
  ) {
    final nomePosto = posto?['nome'] ?? 'Posto não encontrado';
    String endereco = 'Endereço não informado';
    final enderecoData = posto?['endereco'];
    if (enderecoData is Map) {
      final rua = enderecoData['rua'] ?? '';
      final numero = enderecoData['numero'] ?? '';
      final bairro = enderecoData['bairro'] ?? '';
      endereco = [rua, numero, bairro].where((e) => e.isNotEmpty).join(', ');
    } else if (enderecoData is String) {
      endereco = enderecoData;
    }

    final dataSolicitacao = solicitacao['dataSolicitacao'] != null
        ? DateFormat(
            'dd/MM/yyyy',
          ).format((solicitacao['dataSolicitacao'] as Timestamp).toDate())
        : 'Sem data';

    final descricao = solicitacao['descricao'] ?? 'Sem descrição';
    final status = solicitacao['status'] ?? 'Pendente';
    final nomeSolicitante =
        solicitacao['solicitante']?['nome'] ?? 'Não informado';
    final emailSolicitante =
        solicitacao['solicitante']?['email'] ?? 'Não informado';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Detalhes da Solicitação #${solicitacao['id'] ?? ''}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo: ${solicitacao['tipo'] ?? 'Coleta'}'),
                const SizedBox(height: 4),
                Text('Status: $status'),
                const SizedBox(height: 4),
                Text('Data da Solicitação: $dataSolicitacao'),
                const SizedBox(height: 8),
                Text('Descrição: $descricao'),
                const SizedBox(height: 8),
                Text(
                  'Informações do Posto',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Nome do Posto: $nomePosto'),
                Text('Endereço: $endereco'),
                const SizedBox(height: 8),
                Text(
                  'Informações do Solicitante',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Nome: $nomeSolicitante'),
                Text('Email: $emailSolicitante'),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Aqui você pode atualizar o status, se quiser
              },
              child: const Text('Atualizar Status'),
            ),
          ],
        );
      },
    );
  }
}

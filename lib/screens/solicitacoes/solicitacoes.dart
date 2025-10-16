import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Placeholder para o DetalhesSolicitacaoDialog (mantido como está)
class DetalhesSolicitacaoDialog extends StatelessWidget {
  final String nomePosto;
  final String endereco;
  final String dataSolicitacao;
  final String descricao;
  final String statusInicial;
  final String nomeSolicitante;
  final String emailSolicitante;
  final Map<String, dynamic> solicitacao;
  final Function(String) onUpdateStatus;

  const DetalhesSolicitacaoDialog({
    super.key,
    required this.nomePosto,
    required this.endereco,
    required this.dataSolicitacao,
    required this.descricao,
    required this.statusInicial,
    required this.nomeSolicitante,
    required this.emailSolicitante,
    required this.solicitacao,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Detalhes da Solicitação'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Posto: $nomePosto'),
            Text('Endereço: $endereco'),
            Text('Data: $dataSolicitacao'),
            Text('Status: $statusInicial'),
            Text('Solicitante: $nomeSolicitante ($emailSolicitante)'),
            const SizedBox(height: 10),
            Text('Descrição: $descricao'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Fechar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Concluir'),
          onPressed: () {
            onUpdateStatus('Concluída');
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class AcompanhamentoSolicitacoesScreen extends StatefulWidget {
  const AcompanhamentoSolicitacoesScreen({super.key});

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
  String _selectedPostoPath = 'todos';

  DateTime? _dataInicial;
  DateTime? _dataFinal;

  final dateFormat = DateFormat('dd/MM/yyyy');

  late final TextEditingController dataInicialController;
  late final TextEditingController dataFinalController;

  @override
  void initState() {
    final hojeInicial = DateTime.now();
    final hojeFormatado = dateFormat.format(hojeInicial);

    dataInicialController = TextEditingController(text: hojeFormatado);
    dataFinalController = TextEditingController(text: hojeFormatado);

    super.initState();
    _fetchPostosForDropdown().then((_) {
      // ✅ AQUI: Chame .snapshots() na Query retornada por _buildBaseQuery()
      _solicitacoesStream = _buildBaseQuery().snapshots();
      setState(() {});
    });
  }

  @override
  void dispose() {
    dataInicialController.dispose();
    dataFinalController.dispose();
    super.dispose();
  }

  Future<void> _fetchPostosForDropdown() async {
    final snapshot = await _firestore.collection('postos').get();
    final fetchedPostos = snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.reference.path, 'nome': data['nome'] ?? 'Sem nome'};
    }).toList();

    setState(() {
      _postosDropdown = [
        {'id': 'todos', 'nome': 'Todos'},
        ...fetchedPostos,
      ];
      _selectedPostoPath = 'todos';
      _isLoadingPostos = false;
    });
  }

Future<void> _gerarRelatorioPDF() async {
  try {
    final query = _buildBaseQuery();
    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma solicitação encontrada.')),
      );
      return;
    }

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final List<List<String>> rows = [
      ['Data da Solicitação', 'Posto', 'Endereço', 'Status', 'Solicitante']
    ];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final String? postoId = data['postoId'] as String?;
      String postoNome = '';
      String endereco = '';
      String solicitanteNome = '';

      // Buscar posto
      if (postoId != null && postoId.isNotEmpty) {
        final postoSnap =
            await _firestore.collection('postos').doc(postoId).get();
        if (postoSnap.exists) {
          final postoData = postoSnap.data() as Map<String, dynamic>;
          postoNome = postoData['nome'] ?? '';
          final enderecoMap = postoData['endereco'] as Map<String, dynamic>?;
          if (enderecoMap != null) {
            endereco =
                '${enderecoMap['rua'] ?? ''}, ${enderecoMap['numero'] ?? ''}';
          }

          // Buscar cidadão associado ao posto
          final String? cidadaoId = postoData['cidadaoId'] as String?;
          if (cidadaoId != null && cidadaoId.isNotEmpty) {
            final cidadaoSnap =
                await _firestore.collection('cidadaos').doc(cidadaoId).get();
            if (cidadaoSnap.exists) {
              final cidadaoData =
                  cidadaoSnap.data() as Map<String, dynamic>?;
              solicitanteNome = cidadaoData?['nome'] ?? '';
            }
          }
        }
      }

      final dataSolicitacao =
          (data['dataSolicitacao'] as Timestamp?)?.toDate();
      final dataFormatada =
          dataSolicitacao != null ? dateFormat.format(dataSolicitacao) : '';

      final status = data['status'] ?? '';

      rows.add([
        dataFormatada,
        postoNome,
        endereco,
        status,
        solicitanteNome,
      ]);
    }

    // Construir o conteúdo do PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Text(
              'Relatório de Solicitações',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: 0.5),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            data: rows,
          ),
        ],
      ),
    );

    // Gerar e baixar PDF
    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrl(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'relatorio_solicitacoes.pdf')
      ..click();

    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Relatório gerado com sucesso!')),
    );
  } catch (e, stack) {
    debugPrint('Erro ao gerar relatório: $e\n$stack');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao gerar relatório: $e')),
    );
  }
}


  // ✅ Função alterada para retornar um objeto Query
  Query _buildBaseQuery() {
    final hojeInicial = DateTime.now();
    final inicioDoDiaHoje = DateTime(
      hojeInicial.year,
      hojeInicial.month,
      hojeInicial.day,
    );
    final fimDoDiaHoje = inicioDoDiaHoje.add(
      const Duration(hours: 23, minutes: 59, seconds: 59),
    );

    final dataInicialParaQuery = _dataInicial ?? inicioDoDiaHoje;
    final dataFinalParaQuery = _dataFinal != null
        ? _dataFinal!.add(const Duration(hours: 23, minutes: 59, seconds: 59))
        : fimDoDiaHoje;

    Query query = _firestore.collection('solicitacoes');

    if (_selectedPostoPath != 'todos') {
      query = query.where('postoId', isEqualTo: _selectedPostoPath);
    }

    query = query.where(
      'dataSolicitacao',
      isGreaterThanOrEqualTo: Timestamp.fromDate(dataInicialParaQuery),
    );

    query = query.where(
      'dataSolicitacao',
      isLessThanOrEqualTo: Timestamp.fromDate(dataFinalParaQuery),
    );

    query = query.orderBy('dataSolicitacao', descending: true);

    return query; // ✅ Retorna a Query, sem chamar .snapshots()
  }

  Future<Map<String, dynamic>?> _buscarPosto(String postoPath) async {
    if (postoPath.isEmpty) return null;
    final doc = await _firestore.doc(postoPath).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<Map<String, dynamic>?> _buscarCidadao(String cidadaoPath) async {
    if (cidadaoPath.isEmpty) return null;
    final doc = await _firestore.doc(cidadaoPath).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  void _clearFilters() {
    setState(() {
      _selectedPostoPath = 'todos';
      _dataInicial = null;
      _dataFinal = null;
      dataInicialController.clear();
      dataFinalController.clear();
      // ✅ AQUI: Chame .snapshots() na Query retornada por _buildBaseQuery()
      _solicitacoesStream = _buildBaseQuery().snapshots();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Filtros limpos!')));
  }

  void _applyFilters() {
    try {
      DateTime? parsedInicial;
      if (dataInicialController.text.isNotEmpty) {
        parsedInicial = dateFormat.parse(dataInicialController.text);
      }

      DateTime? parsedFinal;
      if (dataFinalController.text.isNotEmpty) {
        parsedFinal = dateFormat.parse(dataFinalController.text);
      }

      if (parsedInicial != null &&
          parsedFinal != null &&
          parsedInicial.isAfter(parsedFinal)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data inicial não pode ser depois da data final.'),
          ),
        );
        return;
      }

      setState(() {
        _dataInicial = parsedInicial;
        _dataFinal = parsedFinal;
        // ✅ AQUI: Chame .snapshots() na Query retornada por _buildBaseQuery()
        _solicitacoesStream = _buildBaseQuery().snapshots();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Formato de data inválido. Use dd/MM/yyyy'),
        ),
      );
    }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acompanhamento de Solicitações',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gerencie todas as solicitações do sistema',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            _buildFilterArea(context),
            const SizedBox(height: 24),

            _isLoadingPostos
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _solicitacoesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhuma solicitação encontrada com os filtros atuais.',
                          ),
                        );
                      }

                      final solicitacoes = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: solicitacoes.length,
                        itemBuilder: (context, index) {
                          final doc = solicitacoes[index];
                          final data =
                              doc.data() as Map<String, dynamic>? ?? {};

                          return _buildSolicitacaoListItem(data, doc.id);
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterArea(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: _getFilterInputDecoration('Posto'),
                value: _selectedPostoPath,
                items: _postosDropdown.map((Map<String, dynamic> item) {
                  return DropdownMenuItem<String>(
                    value: item['id'],
                    child: Text(item['nome']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPostoPath = newValue!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                context,
                'Data Inicial',
                dataInicialController,
                (pickedDate) {
                  _dataInicial = pickedDate;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                context,
                'Data Final',
                dataFinalController,
                (pickedDate) {
                  _dataFinal = pickedDate;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.filter_list, size: 20),
              label: const Text('Filtrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.close, size: 20, color: Colors.black54),
              label: const Text(
                'Limpar',
                style: TextStyle(color: Colors.black54),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                elevation: 0,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _gerarRelatorioPDF,
              icon: const Icon(Icons.picture_as_pdf, size: 20),
              label: const Text('Gerar Relatório'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String hint,
    TextEditingController controller,
    Function(DateTime?) onDateSelected,
  ) {
    return InkWell(
      onTap: () async {
        DateTime? initialDate = controller.text.isNotEmpty
            ? dateFormat.parse(controller.text)
            : DateTime.now();

        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null) {
          setState(() {
            controller.text = dateFormat.format(pickedDate);
            onDateSelected(pickedDate);
          });
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: _getFilterInputDecoration(
            hint,
          ).copyWith(suffixIcon: const Icon(Icons.calendar_today, size: 18)),
          keyboardType: TextInputType.datetime,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'\d|/'))],
          onTap: () {},
        ),
      ),
    );
  }

  InputDecoration _getFilterInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 8.0,
      ),
      isDense: true,
    );
  }

  Widget _buildSolicitacaoListItem(Map<String, dynamic> data, String docId) {
    // ✅ Assume que data['postoId'] pode ser apenas o ID do documento
    final String? postoIdFromData = data['postoId'] as String?;
    String?
    postoPathForQuery; // Novo nome para a variável que será usada na query

    if (postoIdFromData != null && postoIdFromData.isNotEmpty) {
      // ✅ Se for apenas o ID, reconstrua o caminho completo.
      // Assumimos que todos os IDs de postos estão na coleção 'postos'.
      postoPathForQuery = 'postos/$postoIdFromData';
    }

    debugPrint(
      'DEBUG: postoPathForQuery para solicitação ${docId}: $postoPathForQuery',
    );

    final status = data['status'] ?? 'Pendente';
    final dataSolicitacao = data['dataSolicitacao'] != null
        ? (data['dataSolicitacao'] as Timestamp).toDate()
        : null;
    final date = dataSolicitacao != null
        ? DateFormat('dd/MM/yyyy').format(dataSolicitacao)
        : 'Sem data';

    Color statusColor;
    Color iconBackgroundColor;

    switch (status) {
      case 'Pendente':
      case 'Agendada':
        statusColor = Colors.orange.shade700;
        iconBackgroundColor = Colors.orange.shade50;
        break;
      case 'Processando':
        statusColor = Colors.blue.shade700;
        iconBackgroundColor = Colors.blue.shade50;
        break;
      case 'Concluída':
        statusColor = Colors.green.shade700;
        iconBackgroundColor = Colors.green.shade50;
        break;
      default:
        statusColor = Colors.grey.shade700;
        iconBackgroundColor = Colors.grey.shade50;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: FutureBuilder<DocumentSnapshot?>(
        // ✅ Use postoPathForQuery aqui
        future: postoPathForQuery != null && postoPathForQuery.isNotEmpty
            ? _firestore.doc(postoPathForQuery).get()
            : Future.value(null),
        builder: (context, postoSnapshot) {
          if (!postoSnapshot.hasData ||
              !(postoSnapshot.data?.exists ?? false)) {
            return const ListTile(title: Text("Carregando posto..."));
          }

          final postoData = postoSnapshot.data?.data() as Map<String, dynamic>?;
          final nomePosto = postoData?['nome'] ?? 'Posto Desconhecido';

          // ✅ Repita a lógica para cidadaoId, se necessário (assumindo que também pode ser só o ID)
          final String? cidadaoIdFromData = postoData?['cidadaoId'] as String?;
          String? cidadaoPathForQuery;
          if (cidadaoIdFromData != null && cidadaoIdFromData.isNotEmpty) {
            cidadaoPathForQuery = 'cidadaos/$cidadaoIdFromData';
          }

          return FutureBuilder<DocumentSnapshot?>(
            // ✅ Use cidadaoPathForQuery aqui
            future:
                cidadaoPathForQuery != null && cidadaoPathForQuery.isNotEmpty
                ? _firestore.doc(cidadaoPathForQuery).get()
                : Future.value(null),
            builder: (context, cidadaoSnapshot) {
              final cidadaoData =
                  cidadaoSnapshot.data?.data() as Map<String, dynamic>?;
              final nomeCidadao =
                  cidadaoData?['nome'] ?? 'Cidadão Desconhecido';

              final title = 'Solicitação de Coleta';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posto: $nomePosto',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Solicitante: $nomeCidadao',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(date, style: const TextStyle(fontSize: 14)),
                        const Text(
                          'Coleta',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () => _abrirDetalhesSolicitacao(
                  context,
                  data,
                  postoData,
                  cidadaoData,
                  docId,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _abrirDetalhesSolicitacao(
    BuildContext context,
    Map<String, dynamic> solicitacao,
    Map<String, dynamic>? posto,
    Map<String, dynamic>? cidadao,
    String docId,
  ) {
    final nomePosto = posto?['nome'] ?? 'Posto não encontrado';
    String endereco = 'Endereço não informado';
    final enderecoData = posto?['endereco'];
    if (enderecoData is Map<String, dynamic>) {
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
    final nomeSolicitante = cidadao?['nome'] ?? 'Não informado';
    final emailSolicitante = cidadao?['email'] ?? 'Não informado';

    showDialog(
      context: context,
      builder: (context) {
        return DetalhesSolicitacaoDialog(
          nomePosto: nomePosto,
          endereco: endereco,
          dataSolicitacao: dataSolicitacao,
          descricao: descricao,
          statusInicial: status,
          nomeSolicitante: nomeSolicitante,
          emailSolicitante: emailSolicitante,
          solicitacao: solicitacao,
          onUpdateStatus: (String novoStatus) {
            log(solicitacao.toString());
            FirebaseFirestore.instance
                .collection('solicitacoes')
                .doc(docId)
                .update({'status': novoStatus})
                .then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Status atualizado com sucesso!'),
                    ),
                  );
                })
                .catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao atualizar status: $error')),
                  );
                });
          },
        );
      },
    );
  }
}

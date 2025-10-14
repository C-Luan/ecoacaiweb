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

// O diálogo DetalhesSolicitacaoDialog precisa ser definido, assumindo que está em outro arquivo.
// Neste exemplo, ele é apenas referenciado, mas a lógica de abertura é mantida.
// Para fins de teste, você pode usar um StatelessWidget vazio ou importar o arquivo correto.

// Placeholder para o DetalhesSolicitacaoDialog
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
        // Exemplo de botão para mudar status
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
  String _selectedPostoId = 'todos';

  // Usando null para indicar que não há filtro de data inicialmente
  DateTime? _dataInicial;
  DateTime? _dataFinal;

  final dateFormat = DateFormat('dd/MM/yyyy');

  // Controllers para manter os valores exibidos nos campos de texto
  late final TextEditingController dataInicialController;
  late final TextEditingController dataFinalController;

  @override
  void initState() {
    // 1. Obtém a data de hoje
    final hoje = DateTime.now();

    // 2. Formata a data de hoje para o formato 'dd/MM/yyyy'
    final hojeFormatado = dateFormat.format(hoje);

    // Inicializa os controllers e define a data de hoje
    dataInicialController = TextEditingController(text: hojeFormatado);
    dataFinalController = TextEditingController(text: hojeFormatado);

    super.initState();
    _fetchPostosForDropdown().then((_) {
      // Inicializa a stream após carregar os postos.
      // O _buildQuery() agora filtrará apenas a data de hoje,
      // pois _dataInicial e _dataFinal ainda são null, mas os controllers têm o valor visual.
      // É importante notar que, como _dataInicial e _dataFinal são null, o _buildQuery()
      // usará a lógica de "hoje" que ajustamos anteriormente.
      _solicitacoesStream = _buildQuery();
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
      return {'id': doc.id, 'nome': data['nome'] ?? 'Sem nome'};
    }).toList();

    setState(() {
      _postosDropdown = [
        {'id': 'todos', 'nome': 'Todos'},
        ...fetchedPostos,
      ];
      _selectedPostoId = 'todos';
      _isLoadingPostos = false;
    });
  }

  Future<void> _gerarRelatorioPDF() async {
    try {
      // 🔹 Monta a query baseada nos filtros aplicados
      final query = _criarQueryBase();
      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma solicitação encontrada.')),
        );
        return;
      }

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

      // 🔹 Cria lista de linhas da tabela
      final rows = <List<String>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // 🔸 Referências de outras coleções
        final postoRef = data['postoId'] as DocumentReference?;

        String postoNome = '';
        String solicitanteNome = '';
        String endereco = '';

        // 🔹 Busca nomes relacionados
        if (postoRef != null) {
          final postoSnap = await postoRef.get();
          final postoData = postoSnap.data() as Map<String, dynamic>?;
          postoNome = postoData?['nome'] ?? '';
          endereco =
              '${postoData?['endereco']['rua']},${postoData?['endereco']['numero']}';
        }

        final dataSolicitacao = (data['dataSolicitacao'] as Timestamp?)
            ?.toDate();
        final dataFormatada = dataSolicitacao != null
            ? dateFormat.format(dataSolicitacao)
            : '';

        final status = data['status'] ?? '';

        rows.add([dataFormatada, postoNome, endereco, status, solicitanteNome]);
      }

      // 🔹 Adiciona página no PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Relatório de Solicitações',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.green800,
                      ),
                    ),
                    pw.Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Total de solicitações: ${rows.length}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: ['Data', 'Posto', 'Endereço', 'Status'],
                data: rows,
                border: pw.TableBorder.all(
                  width: 0.5,
                  color: PdfColors.grey400,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.green700,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                headerAlignment: pw.Alignment.center,
                cellAlignment: pw.Alignment.centerLeft,
                rowDecoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.2),
                  ),
                ),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 6,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Ecoaçaí • Sistema de Acompanhamento de Solicitações',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
            ];
          },
        ),
      );

      // 🔹 Gera bytes e inicia download (compatível com Flutter Web)
      final bytes = await pdf.save();
      final blob = html.Blob([Uint8List.fromList(bytes)], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'relatorio_solicitacoes.pdf')
        ..click();

      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório gerado com sucesso!')),
      );
    } catch (e, stack) {
      debugPrint('Erro ao gerar relatório: $e\n$stack');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao gerar relatório: $e')));
    }
  }

  Stream<QuerySnapshot> _buildQuery() {
    // 1. Define as datas padrão (hoje)
    // Início do dia de hoje (00:00:00)
    final hojeInicial = DateTime.now();
    final inicioDoDiaHoje = DateTime(
      hojeInicial.year,
      hojeInicial.month,
      hojeInicial.day,
    );

    // Fim do dia de hoje (23:59:59)
    final fimDoDiaHoje = inicioDoDiaHoje.add(
      const Duration(hours: 23, minutes: 59, seconds: 59),
    );

    // 2. Determina os valores finais para a query
    // Se _dataInicial for null, usa o início do dia de hoje
    final dataInicialParaQuery = _dataInicial ?? inicioDoDiaHoje;

    // Se _dataFinal for null, usa o fim do dia de hoje
    // Se _dataFinal não for null, mas queremos o fim do dia, adicionamos o offset
    final dataFinalParaQuery = _dataFinal != null
        ? _dataFinal!.add(const Duration(hours: 23, minutes: 59, seconds: 59))
        : fimDoDiaHoje;

    Query query = _firestore
        .collection('solicitacoes')
        .orderBy('dataSolicitacao', descending: true);

    if (_selectedPostoId != 'todos') {
      query = query.where('postoId', isEqualTo: _selectedPostoId);
    }

    // Filtro por Data Inicial (sempre aplicado, usando hoje como padrão)
    query = query.where(
      'dataSolicitacao',
      isGreaterThanOrEqualTo: Timestamp.fromDate(dataInicialParaQuery),
    );

    // Filtro por Data Final (sempre aplicado, usando hoje como padrão)
    query = query.where(
      'dataSolicitacao',
      isLessThanOrEqualTo: Timestamp.fromDate(dataFinalParaQuery),
    );

    return query.snapshots();
  }

  Future<Map<String, dynamic>?> _buscarPosto(String postoId) async {
    if (postoId.isEmpty) return null;
    final doc = await _firestore.collection('postos').doc(postoId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<Map<String, dynamic>?> _buscarCidadao(String cidadaoId) async {
    if (cidadaoId.isEmpty) return null;
    final doc = await _firestore.collection('cidadaos').doc(cidadaoId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Query _criarQueryBase() {
    Query query = FirebaseFirestore.instance.collection('solicitacoes');

    // Mesma lógica de filtros que você já tem
    if (_selectedPostoId != null && _selectedPostoId != 'todos') {
      query = query.where('postoId', isEqualTo: _selectedPostoId);
    }

    if (_dataInicial != null && _dataFinal != null) {
      query = query.where(
        'dataSolicitacao',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_dataInicial!),
        isLessThanOrEqualTo: Timestamp.fromDate(_dataFinal!),
      );
    }

    query = query.orderBy('dataSolicitacao', descending: true);

    return query;
  }

  void _clearFilters() {
    setState(() {
      _selectedPostoId = 'todos';
      _dataInicial = null;
      _dataFinal = null;
      dataInicialController.clear();
      dataFinalController.clear();
      _solicitacoesStream = _buildQuery(); // Atualiza a query
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
        // A Query para o posto já está no _selectedPostoId
        _solicitacoesStream = _buildQuery();
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
            // Título e Descrição (Conforme a imagem)
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

            // Área de Filtros
            _buildFilterArea(context),
            const SizedBox(height: 24),

            // Lista de Solicitações
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

  // =======================================================
  // UI/UX Builders
  // =======================================================

  Widget _buildFilterArea(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Filtro de Posto (Dropdown)
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: _getFilterInputDecoration('Posto'),
                value: _selectedPostoId,
                items: _postosDropdown.map((Map<String, dynamic> item) {
                  return DropdownMenuItem<String>(
                    value: item['id'],
                    child: Text(item['nome']!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedPostoId = newValue!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            // Filtro Data Inicial (Campo de Data)
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
            // Filtro Data Final (Campo de Data)
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

        // Botões de Ação
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
          ],
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Helper para campos de data com DatePicker
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
          onTap: () {}, // Necessário por causa do AbsorbPointer
        ),
      ),
    );
  }

  // Helper para estilo de input
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
    // 🔹 Recupera o postoId como DocumentReference
    final postoRef = data['postoId'] as DocumentReference?;
    final status = data['status'] ?? 'Pendente';
    final dataSolicitacao = data['dataSolicitacao'] != null
        ? (data['dataSolicitacao'] as Timestamp).toDate()
        : null;
    final date = dataSolicitacao != null
        ? DateFormat('dd/MM/yyyy').format(dataSolicitacao)
        : 'Sem data';

    // 🔹 Cores do status
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
        future: postoRef?.get(),
        builder: (context, postoSnapshot) {
          if (!postoSnapshot.hasData) {
            return const ListTile(title: Text("Carregando..."));
          }

          final postoData = postoSnapshot.data?.data() as Map<String, dynamic>?;
          final nomePosto = postoData?['nome'] ?? 'Posto Desconhecido';
          final cidadaoRef = postoData?['cidadaoId'] as DocumentReference?;

          return FutureBuilder<DocumentSnapshot?>(
            future: cidadaoRef?.get(),
            builder: (context, cidadaoSnapshot) {
              final cidadaoData =
                  cidadaoSnapshot.data?.data() as Map<String, dynamic>?;
              final nomeCidadao =
                  cidadaoData?['endereco']?['nome'] ?? 'Cidadão Desconhecido';

              // Monta o título final
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
                    // Badge de status
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

  // =======================================================
  // Lógica para Abrir Detalhes (Mantida)
  // =======================================================

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

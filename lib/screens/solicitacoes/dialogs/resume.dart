import 'package:flutter/material.dart';

class DetalhesSolicitacaoDialog extends StatefulWidget {
  final Map<String, dynamic> solicitacao;
  final String statusInicial;
  final String dataSolicitacao;
  final String descricao;
  final String nomePosto;
  final String endereco;
  final String nomeSolicitante;
  final String emailSolicitante;
  final void Function(String novoStatus)
  onUpdateStatus; // Callback para notificar o status atualizado

  const DetalhesSolicitacaoDialog({
    super.key,
    required this.solicitacao,
    required this.statusInicial,
    required this.dataSolicitacao,
    required this.descricao,
    required this.nomePosto,
    required this.endereco,
    required this.nomeSolicitante,
    required this.emailSolicitante,
    required this.onUpdateStatus,
  });

  @override
  State<DetalhesSolicitacaoDialog> createState() =>
      _DetalhesSolichesitacaoDialogState();
}

class _DetalhesSolichesitacaoDialogState
    extends State<DetalhesSolicitacaoDialog> {
  // Lista de opções de status
  final List<String> statusOptions = [
    'Pendente', // Mantém o status original ou um status inicial
    'Concluida',
    'Agendada',
    'Adiada',
    'Em Rota',
  ];

  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Inicializa o status selecionado com o status atual da solicitação
    // Garante que o status inicial esteja nas opções, senão usa 'Pendente' como fallback
    _selectedStatus = widget.statusInicial;
    if (!statusOptions.contains(_selectedStatus)) {
      statusOptions.insert(0, _selectedStatus);
    }
  }

  // Função para lidar com a atualização de status
  void _handleUpdateStatus() {
    // Chama o callback passando o novo status
    widget.onUpdateStatus(_selectedStatus);
    // Fecha o diálogo
    Navigator.pop(context);
    // Opcionalmente, você pode adicionar uma lógica para salvar no banco de dados/API aqui ou no widget pai
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Detalhes da Solicitação #${widget.solicitacao['id'] ?? ''}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Informações básicas da solicitação ---
            Text('Tipo: ${widget.solicitacao['tipo'] ?? 'Coleta'}'),
            const SizedBox(height: 4),

            // --- Status Atual e Dropdown para Alteração ---
            Row(
              children: [
                const Text('Status: '),
                DropdownButton<String>(
                  value: _selectedStatus,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedStatus = newValue;
                      });
                    }
                  },
                  items: statusOptions.map<DropdownMenuItem<String>>((
                    String value,
                  ) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontWeight: _selectedStatus == value
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Data da Solicitação: ${widget.dataSolicitacao}'),
            const SizedBox(height: 8),
            Text('Descrição: ${widget.descricao}'),
            const SizedBox(height: 8),

            // --- Informações do Posto ---
            const Text(
              'Informações do Posto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Nome do Posto: ${widget.nomePosto}'),
            Text('Endereço: ${widget.endereco}'),
            const SizedBox(height: 8),

            // --- Informações do Solicitante ---
            const Text(
              'Informações do Solicitante',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Nome: ${widget.nomeSolicitante}'),
            Text('Email: ${widget.emailSolicitante}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          // Alterado para TextButton, que é mais comum em actions
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        ElevatedButton(
          onPressed: _handleUpdateStatus, // Chama a nova função
          child: const Text('Atualizar Status'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
// Note: Intl dependency (for DateFormat) is not used in this basic example, 
// but is good practice for real time/date formatting.

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  // Dados mockados para simular a atividade recente
  final List<Map<String, dynamic>> _recentActivity = const [
    {
      'icon': Icons.local_shipping,
      'color': Colors.blue,
      'title': 'Nova solicitação de coleta no Posto Central',
      'time': '2 min atrás'
    },
    {
      'icon': Icons.person_add,
      'color': Colors.deepPurple,
      'title': 'Novo cidadão cadastrado: Ana Silva',
      'time': '15 min atrás'
    },
    {
      'icon': Icons.store,
      'color': Colors.green,
      'title': 'Posto Norte atualizado',
      'time': '1 hora atrás'
    },
    {
      'icon': Icons.check_circle_outline,
      'color': Colors.red,
      'title': 'Solicitação concluída no Posto Sul',
      'time': '2 horas atrás'
    },
  ];

  // Cartão de Estatística Reutilizável
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4, // Adiciona uma sombra para profundidade
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Cantos mais arredondados
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Item de Atividade Recente Reutilizável
  Widget _buildActivityItem(
      IconData icon, Color color, String title, String time) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15), // Fundo claro para o ícone
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        time,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão Geral do Sistema',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, // Fundo branco para a AppBar
        elevation: 0, // Remove a sombra padrão da AppBar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Título/Descrição
            const Text(
              'Estatísticas e resumo das atividades',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),

            // Cartões de Estatísticas (Grid)
            // Usa GridView.count para exibir 3 itens por linha em telas maiores
            // e se adapta automaticamente.
            GridView.count(
              shrinkWrap: true, // Necessário para usar GridView dentro de SingleChildScrollView
              physics:
                  const NeverScrollableScrollPhysics(), // Desabilita o scroll do GridView
              crossAxisCount: 3, // Número de colunas no grid
              crossAxisSpacing: 15.0, // Espaçamento horizontal
              mainAxisSpacing: 15.0, // Espaçamento vertical
              childAspectRatio: 1.5, // Proporção para cartões mais largos
              children: <Widget>[
                _buildStatCard(
                  title: 'Total de Cidadãos',
                  value: '3',
                  icon: Icons.group,
                  color: Colors.deepPurple,
                ),
                _buildStatCard(
                  title: 'Postos Ativos',
                  value: '2',
                  icon: Icons.location_on,
                  color: Colors.green,
                ),
                _buildStatCard(
                  title: 'Solicitações Hoje',
                  value: '0',
                  icon: Icons.assignment,
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(), // Separador visual
            const SizedBox(height: 20),

            // Atividade Recente
            const Text(
              'Atividade Recente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),

            // Lista de Atividades
            Card(
              elevation: 2, // Leve elevação para o bloco de atividades
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivity.length,
                  itemBuilder: (context, index) {
                    final activity = _recentActivity[index];
                    return _buildActivityItem(
                      activity['icon'] as IconData,
                      activity['color'] as Color,
                      activity['title'] as String,
                      activity['time'] as String,
                    );
                  },
                ),
              ),
            ),
            // Espaçamento final
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
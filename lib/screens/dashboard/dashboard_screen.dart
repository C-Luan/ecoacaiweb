import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MainDashboardScreen extends StatelessWidget {
  const MainDashboardScreen({super.key});

  // 🔹 Total de documentos em uma coleção
  Stream<int> _getTotal(String collectionName) {
    return FirebaseFirestore.instance.collection(collectionName).snapshots().map(
          (snapshot) => snapshot.docs.length,
        );
  }

  // 🔹 Quantidade de solicitações de hoje
  Stream<int> _getSolicitacoesHoje() {
    final hoje = DateTime.now();
    final inicioDoDia = DateTime(hoje.year, hoje.month, hoje.day);
    final fimDoDia = inicioDoDia.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('solicitacoes')
        .where('dataSolicitacao', isGreaterThanOrEqualTo: inicioDoDia)
        .where('dataSolicitacao', isLessThan: fimDoDia)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // 🔹 Atividades recentes (últimas solicitações)
  Stream<List<Map<String, dynamic>>> _getAtividadesRecentes() {
    return FirebaseFirestore.instance
        .collection('solicitacoes')
        .orderBy('dataSolicitacao', descending: true)
        .limit(5)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> atividades = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final postoId = data['postoId'] as String?;
        String postoNome = 'Desconhecido';

        if (postoId != null) {
          final postoDoc = await FirebaseFirestore.instance
              .collection('postos')
              .doc(postoId)
              .get();

          if (postoDoc.exists) {
            postoNome = postoDoc.data()?['nome'] ?? 'Sem nome';
          }
        }

        atividades.add({
          'icon': Icons.local_shipping,
          'color': Colors.blue,
          'title': 'Nova solicitação em $postoNome',
          'time': _formatarData(data['dataCriacao']),
        });
      }
      return atividades;
    });
  }

  // 🔹 Formatar data
  static String _formatarData(Timestamp? timestamp) {
    if (timestamp == null) return 'Data desconhecida';
    final data = timestamp.toDate();
    final agora = DateTime.now();
    final diff = agora.difference(data);

    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min atrás';
    if (diff.inHours < 24) return '${diff.inHours} h atrás';
    return DateFormat('dd/MM/yyyy HH:mm').format(data);
  }

  // 🔹 Cartão de estatísticas
  Widget _buildStatCard({
    required String title,
    required Stream<int> stream,
    required IconData icon,
    required Color color,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final value = snapshot.data?.toString() ?? '...';
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(icon, color: color, size: 28),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 Item da lista de atividades recentes
  Widget _buildActivityItem(
      IconData icon, Color color, String title, String time) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      trailing: Text(
        time,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Visão Geral do Sistema',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Estatísticas e resumo das atividades',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Cards Responsivos (scroll horizontal se necessário)
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Wrap(
                      spacing: 15.0,
                      runSpacing: 15.0,
                      alignment: WrapAlignment.start,
                      children: [
                        SizedBox(
                          width: isMobile ? 200 : 250,
                          child: _buildStatCard(
                            title: 'Total de Cidadãos',
                            stream: _getTotal('cidadaos'),
                            icon: Icons.group,
                            color: Colors.deepPurple,
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? 200 : 250,
                          child: _buildStatCard(
                            title: 'Postos Ativos',
                            stream: _getTotal('postos'),
                            icon: Icons.location_on,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(
                          width: isMobile ? 200 : 250,
                          child: _buildStatCard(
                            title: 'Solicitações Hoje',
                            stream: _getSolicitacoesHoje(),
                            icon: Icons.assignment,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            const Text(
              'Atividade Recente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getAtividadesRecentes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Nenhuma atividade recente.');
                }

                final atividades = snapshot.data!;
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: atividades.length,
                    itemBuilder: (context, index) {
                      final a = atividades[index];
                      return _buildActivityItem(
                        a['icon'] as IconData,
                        a['color'] as Color,
                        a['title'] as String,
                        a['time'] as String,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

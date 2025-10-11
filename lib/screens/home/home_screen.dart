import 'package:ecoacaiweb/screens/batedores/batedores_screen.dart';
import 'package:ecoacaiweb/screens/dashboard/dashboard_screen.dart';
import 'package:ecoacaiweb/screens/postos/posto_screen.dart';
import 'package:ecoacaiweb/screens/solicitacoes/solicitacoes.dart';
import 'package:ecoacaiweb/services/loginserver/authservicefirebase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';

import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  bool _isExtended = true; // Controla o estado do NavigationRail
  int _selectedIndex = 0; // Controla qual tela está selecionada
  late List<NavigationRailDestination> _destinations;
  // Suas páginas/painéis
  final List<Widget> _pages = [
    MainDashboardScreen(),
    CidadaosScreen(),
    PostoScreen(),
    AcompanhamentoSolicitacoesScreen(),
  ];
  @override
  void initState() {
    super.initState();
    _destinations = [
      NavigationRailDestination(
        icon: Icon(Icons.home),
        selectedIcon: Icon(Icons.home_filled),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.person_search_outlined),
        selectedIcon: Icon(Icons.person_search_rounded),
        label: Text('Batedores'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.store_mall_directory_outlined),
        selectedIcon: Icon(Icons.store_mall_directory_rounded),
        label: Text('Postos de Coleta'),
      ),
       NavigationRailDestination(
        icon: Icon(Icons.read_more_rounded),
        selectedIcon: Icon(Icons.read_more),
        label: Text('Solicitações'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    final theme = Theme.of(context);
    final FirebaseAuth auth = FirebaseAuth.instance;

    if (isMobile) {
      // Return mobile layout with AppBar and Drawer
      return Scaffold(
        appBar: AppBar(
          title: Text(
            (_destinations[_selectedIndex].label as Text).data ?? 'Painel',
          ),
        ),
        drawer: _buildDrawer(context, auth),
        body: _pages[_selectedIndex],
      );
    } else {
      // Return desktop layout with NavigationRail
      return Scaffold(
        body: Row(
          children: <Widget>[
            NavigationRail(
              backgroundColor: Colors.green.shade900,
              selectedIndex: _selectedIndex,
              selectedLabelTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: Colors.white.withValues(alpha: .7),
              ),
              indicatorColor: Colors.white.withValues(alpha: .20),
              selectedIconTheme: const IconThemeData(
                color: Colors.white,
                size: 24,
              ),
              unselectedIconTheme: IconThemeData(
                color: Colors.white.withValues(alpha: .7),
                size: 20,
              ),
              extended: _isExtended,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.none,
              leading: Column(
                children: [
                  const SizedBox(height: 8),
                  IconButton(
                    icon: Icon(
                      _isExtended
                          ? FluentIcons.panel_left_contract_20_filled
                          : FluentIcons.panel_left_expand_20_filled,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExtended = !_isExtended;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_isExtended)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 80,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(
                                  auth.currentUser!.photoURL!,
                                ),
                              ),
                            ),
                          ),
                          // CircleAvatar(
                          //   radius: 36,
                          //   backgroundColor: Colors.white,
                          //   child: Image.network(auth.currentUser!.photoURL!),
                          // ),
                          const SizedBox(width: 12),
                          Text(
                            auth.currentUser?.displayName ?? ''.split(' ')[0],
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
              destinations: _destinations,
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: _buildLogoutButton(context),
                  ),
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      );
    }
  }

  /// Helper method to build the Drawer for mobile view
  Widget _buildDrawer(BuildContext context, FirebaseAuth user) {
    return Drawer(
      child: Column(
        children: [
          // SUBSTITUA O UserAccountsDrawerHeader ANTIGO POR ESTE:
          UserAccountsDrawerHeader(
            // 1. Estiliza o texto para melhor legibilidade no fundo escuro
            accountName: Text(
              user.currentUser?.displayName ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              user.currentUser?.email ?? '',
              style: TextStyle(color: Colors.white.withValues(alpha:  0.8)),
            ),

            // 2. Estiliza o avatar para criar contraste
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white, // Fundo branco para destacar
              child: Image.network(
                user.currentUser!.photoURL!,
               
              ),
            ),

            // 3. Adiciona uma decoração com gradiente ao fundo
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor
                      .withBlue(120)
                      .withGreen(
                        70,
                      ), // Um tom de azul um pouco mais escuro e profundo
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _destinations.length,
              itemBuilder: (context, index) {
                final destination = _destinations[index];
                return ListTile(
                  leading: _selectedIndex == index
                      ? destination.selectedIcon
                      : destination.icon,
                  title: destination.label,
                  selected: _selectedIndex == index,
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                    Navigator.pop(context); // Close the drawer
                  },
                );
              },
            ),
          ),
          // Logout button at the bottom
          const Divider(),
          _buildLogoutButton(context),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    final isExtended = _isExtended; // Use local variable for clarity

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => AuthServiceFirebase().signOut(),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isExtended ? 24 : 12,
            vertical: 12,
          ),
          child: isExtended
              ? Row(
                  children: [
                    Icon(
                      FluentIcons.arrow_exit_20_filled,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 20),
                    Text(
                      'Sair',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                )
              : Icon(
                  FluentIcons.arrow_exit_20_filled,
                  color: theme.colorScheme.error,
                ),
        ),
      ),
    );
  }
}

import 'package:ecoacaiweb/services/loginserver/authservicefirebase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Certifique-se de que a fonte 'ui-rounded' esteja configurada no pubspec.yaml
// ou use uma fonte padrão como 'Roboto' se não estiver disponível.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthServiceFirebase _authService = AuthServiceFirebase();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usando as cores do ThemeData
// Roxo
    final Color secondaryColor = Theme.of(
      context,
    ).colorScheme.secondary; // Verde
    final Color primaryTextColor = Theme.of(
      context,
    ).colorScheme.onSurface; // Cinza Escuro
    final Color linkColor =
        secondaryColor; // Usando secondary para links/destaques
    final Color cardBackgroundColor = Theme.of(
      context,
    ).scaffoldBackgroundColor; // Branco
    final Color fieldBackgroundColor = Theme.of(
      context,
    ).inputDecorationTheme.fillColor!; // Branco

    // Removido o buildBokehCircle e o Stack de fundo para um visual mais limpo e claro

    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Fundo branco
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Card(
            // Card agora usa CardThemeData
            color: cardBackgroundColor,
            margin: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/Ícone
                  Image.asset('assets/logos/ecoacai.png', height: 280),
                  const SizedBox(height: 12),

                  const SizedBox(height: 6),
                  // Tagline
                  Text(
                    "Sua plataforma de coleta de açaí na cidade de Concórdia-PA, o primeiro Bairro sustentável da Amazônia.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryTextColor.withValues(alpha:  0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Campo Email
                  _buildTextField(
                    label: "Email",
                    controller: _emailController,
                    hint: "seu@email.com",
                    textColor: primaryTextColor,
                    fieldBackgroundColor: fieldBackgroundColor,
                  ),
                  const SizedBox(height: 18),
                  // Campo Senha
                  _buildPasswordField(
                    controller: _passwordController,
                    label: "Senha",
                    hint: "••••••••",
                    textColor: primaryTextColor,
                    fieldBackgroundColor: fieldBackgroundColor,
                    linkColor: linkColor,
                  ),
                  const SizedBox(height: 18),
                  // Lembrar de mim
                  _buildRememberMeCheckbox(
                    textColor: primaryTextColor.withValues(alpha:  0.7),
                    activeColor: linkColor,
                    value: _rememberMe,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _rememberMe = newValue ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  // Botão Entrar
                  _buildLoginButton(
                    text: "Entrar",
                    onPressed: () {
                      _authService.signInWithEmailAndPassword(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Link de Registro (exemplo)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Não tem uma conta?",
                        style: TextStyle(
                          color: primaryTextColor.withValues(alpha:  0.7),
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (kDebugMode) {
                            print("Navegar para registro");
                          }
                          // Implementar navegação para a tela de registro
                        },
                        child: Text(
                          "Registre-se",
                          style: TextStyle(
                            color: linkColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets Auxiliares Atualizados ---

  Widget _buildTextField({
    required String label,
    required String hint,
    required Color textColor,
    required Color fieldBackgroundColor,
    required TextEditingController controller,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    // Usando as decorações definidas no ThemeData
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: textColor.withValues(alpha:  0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: isObscure,
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor, fontSize: 15),
          // Usando a decoração padrão do tema, exceto pelo hint/fill, que já estão no tema
          // SOLUÇÃO: Crie um InputDecoration e use applyDefaults para aplicar o tema.
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            // Adicione outras propriedades específicas aqui, se necessário.
          ).applyDefaults(theme.inputDecorationTheme), // Aplica o tema global
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String hint,
    required Color textColor,
    required Color fieldBackgroundColor,
    required Color linkColor,
    required TextEditingController controller,
  }) {
    // Usando as decorações definidas no ThemeData
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: textColor.withValues(alpha:  0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            InkWell(
              onTap: () {
                if (kDebugMode) {
                  print("Esqueceu a senha?");
                }
                // Implementar navegação para recuperação de senha
              },
              child: Text(
                "Esqueceu a senha?",
                style: TextStyle(
                  color: linkColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: true,
          controller: controller,
          style: TextStyle(color: textColor, fontSize: 15),
          // SOLUÇÃO: Crie um InputDecoration e use applyDefaults para aplicar o tema.
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            // Adicione outras propriedades específicas aqui, se necessário.
          ).applyDefaults(theme.inputDecorationTheme), // Aplica o tema global
        ),
      ],
    );
  }

  Widget _buildRememberMeCheckbox({
    required Color textColor,
    required Color activeColor,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor, // Cor secundária (verde)
            checkColor: Colors.white,
            side: WidgetStateBorderSide.resolveWith(
              (states) =>
                  BorderSide(width: 1.5, color: textColor.withValues(alpha:  0.7)),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          "Lembrar de mim",
          style: TextStyle(color: textColor, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildLoginButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    // Usamos FilledButton para aproveitar o FilledButtonThemeData do ThemeData (cor primary: roxo)
    return FilledButton(onPressed: onPressed, child: Text(text));
  }
}

import 'dart:math';

import 'package:flutter/material.dart';

import '/shared/routes/app_routes.dart';
import '/data/services/session_service.dart';
import '/data/services/secure_storage_service.dart';

import '/view/widgets/lili_animation.dart';
import '/shared/constants/splash_messages.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final String _mensagem;

  final SessionService _sessionService = SessionService(
    secureStorage: SecureStorageService(),
  );

  @override
  void initState() {
    super.initState();

    // Escolhe uma mensagem uma única vez por inicialização.
    _mensagem = SplashMessages
        .mensagens[Random().nextInt(SplashMessages.mensagens.length)];

    // Mantém a duração da Splash em três segundos.
    // Este controlador não interfere na animação da Lili.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _iniciarAplicativo();
  }

  Future<void> _iniciarAplicativo() async {
    String? token;

    // Recupera a sessão enquanto a animação acontece.
    final tokenFuture = _sessionService.recuperarToken();

    try {
      // Aguarda o tempo mínimo da Splash.
      await _controller.forward().orCancel;

      // Aguarda a leitura do token, se necessário.
      token = await tokenFuture;

      debugPrint(
        'SESSAO: token armazenado = '
        '${token != null && token.isNotEmpty}',
      );
    } on TickerCanceled {
      return;
    } catch (e) {
      debugPrint('SESSAO: erro ao recuperar token: $e');
      token = null;
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      token != null && token.isNotEmpty ? AppRoutes.home : AppRoutes.login,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐙', style: TextStyle(fontSize: 110)),

              const Text('Projeto OS', style: TextStyle(fontSize: 30)),

              const SizedBox(height: 30),

              // Lili caminha e muda de direção automaticamente.
              const LiliAnimation(),

              const SizedBox(height: 12),

              Text(
                _mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Versão 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.indigo),
          ),
        ),
      ),
    );
  }
}

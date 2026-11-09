import 'dart:math';

import 'package:flutter/material.dart';

import '/shared/routes/app_routes.dart';
import '/data/services/session_service.dart';
import '/data/services/secure_storage_service.dart';

import '/view/widgets/banana_animation.dart';
import '/shared/constants/splash_messages.dart';
import '/data/services/motd_service.dart';
import '/view/motd/motd_view.dart';

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

    // Seleciona uma mensagem aleatória ao iniciar.
    _mensagem = SplashMessages
        .mensagens[Random().nextInt(SplashMessages.mensagens.length)];

    // Duração mínima da Splash: três segundos.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _iniciarAplicativo();
  }

  Future<void> _iniciarAplicativo() async {
    String? token;

    final tokenFuture = _sessionService.recuperarToken();

    try {
      await _controller.forward().orCancel;

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

    // Determina o destino original do aplicativo.
    final proximaRota = token != null && token.isNotEmpty
        ? AppRoutes.home
        : AppRoutes.login;

    // Consulta o canal de avisos.
    final motdService = MotdService();
    final aviso = await motdService.buscarAvisoPendente();

    if (!mounted) return;

    // Se não existir aviso pendente, navega normalmente.
    if (aviso == null) {
      Navigator.of(context).pushReplacementNamed(proximaRota);
      return;
    }

    // Se existir aviso, apresenta a camada intermediária.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) => MotdView(aviso: aviso, proximaRota: proximaRota),
      ),
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
              // Logotipo provisório da Consultoria Bananeira.
              Image.asset('assets/icon/app_icon.png', width: 110, height: 110),

              const SizedBox(height: 12),

              const Text(
                'Consultoria Bananeira',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30),
              ),

              const SizedBox(height: 30),

              // Animação original, ainda será substituída.
              const BananaAnimation(),

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

import 'dart:math';

import 'package:flutter/material.dart';

import '/shared/routes/app_routes.dart';
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
    try {
      await _controller.forward().orCancel;
    } on TickerCanceled {
      return;
    }

    if (!mounted) return;

    // Temporário: exige login até integrarmos a validação por /auth/me.
    const proximaRota = AppRoutes.login;

    try {
      final aviso = await MotdService().buscarAvisoPendente();

      if (!mounted) return;

      if (aviso != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) =>
                MotdView(aviso: aviso, proximaRota: proximaRota),
          ),
        );
        return;
      }
    } catch (_) {
      // Falha no MOTD não bloqueia a abertura do login.
      if (!mounted) return;
    }

    Navigator.of(context).pushReplacementNamed(proximaRota);
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

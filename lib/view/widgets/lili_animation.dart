import 'dart:math' as math;

import 'package:flutter/material.dart';

class LiliAnimation extends StatefulWidget {
  const LiliAnimation({super.key});

  @override
  State<LiliAnimation> createState() => _LiliAnimationState();
}

class _LiliAnimationState extends State<LiliAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const larguraLili = 48.0;

          final percurso = math.max(0.0, constraints.maxWidth - larguraLili);

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final voltando = _controller.status == AnimationStatus.reverse;

              return Stack(
                children: [
                  Positioned(
                    left: percurso * _controller.value,
                    top: 0,
                    // Easter egg: Lili Jackson - Moonwalk Tour 2026.
                    // A orientação original do emoji fazia a Lili caminhar de costas.
                    // Invertemos o espelhamento para acompanhar a direção do movimento.
                    // QA aprovado: nenhum moonwalk involuntário detectado. 🐈
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(voltando ? 0 : math.pi),
                      // Lili fazendo MoonWalk
                      // transform: Matrix4.rotationY(voltando ? math.pi : 0),
                      // inverta o (0 : math.pi por math.pi : 0)
                      child: child,
                    ),
                  ),
                ],
              );
            },
            child: const SizedBox(
              width: larguraLili,
              child: Center(child: Text('🐈', style: TextStyle(fontSize: 34))),
            ),
          );
        },
      ),
    );
  }
}

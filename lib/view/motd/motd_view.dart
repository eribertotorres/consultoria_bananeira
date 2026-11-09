import 'package:flutter/material.dart';

import '/data/services/motd_service.dart';
import '/data/models/motd_message.dart';

class MotdView extends StatefulWidget {
  final MotdMessage aviso;
  final String proximaRota;

  const MotdView({super.key, required this.aviso, required this.proximaRota});

  @override
  State<MotdView> createState() => _MotdViewState();
}

class _MotdViewState extends State<MotdView> {
  final MotdService _service = MotdService();

  bool _continuando = false;

  Future<void> _continuar() async {
    if (_continuando) return;

    setState(() => _continuando = true);

    await _service.marcarComoVisualizado(widget.aviso.id);

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(widget.proximaRota);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 80,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 24),

                  Text(
                    widget.aviso.titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.aviso.mensagem,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _continuando ? null : _continuar,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _continuando ? 'Continuando...' : 'Continuar',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '/data/services/session_service.dart';
import '/data/services/secure_storage_service.dart';
import '/shared/routes/app_routes.dart';

class ErpMobileHomeView extends StatefulWidget {
  const ErpMobileHomeView({super.key});

  @override
  State<ErpMobileHomeView> createState() => _ErpMobileHomeViewState();
}

class _ErpMobileHomeViewState extends State<ErpMobileHomeView> {
  final SessionService _sessionService = SessionService(
    secureStorage: SecureStorageService(),
  );

  bool _saindo = false;

  Future<void> _sair() async {
    if (_saindo) return;

    setState(() {
      _saindo = true;
    });

    try {
      await _sessionService.encerrarSessao();

      if (!mounted) return;

      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível concluir a saída. '
            'Verifique a conexão e tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saindo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultoria Bananeira'),
        actions: [
          TextButton.icon(
            onPressed: _saindo ? null : _sair,
            icon: _saindo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: Text(_saindo ? 'Saindo...' : 'Sair'),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
              SizedBox(height: 20),
              Text('Login realizado!', style: TextStyle(fontSize: 24)),
              SizedBox(height: 12),
              Text(
                'Integração com a API Bananeira funcionando.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

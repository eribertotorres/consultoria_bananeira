import 'package:shared_preferences/shared_preferences.dart';

import '../models/motd_message.dart';

class MotdService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const String _chaveVisualizados = 'motd_visualizados';

  // Aviso de demonstração.
  // Futuramente será recebido pela API.
  static final MotdMessage _avisoAtual = MotdMessage(
    id: 'boas_vindas_001',
    titulo: 'Bem-vindo à Consultoria Bananeira!',
    mensagem:
        'Estamos preparando ferramentas e informações '
        'para ajudar na gestão da produção, '
        'comercialização e logística da banana.\n\n'
        'Acompanhe nossas próximas novidades!',
    ativo: true,
    inicio: DateTime(2026, 11, 1),
    fim: DateTime(2027, 12, 31),
  );

  Future<MotdMessage?> buscarAvisoPendente() async {
    if (!_avisoAtual.estaVigente) return null;

    try {
      final visualizados =
          await _prefs.getStringList(_chaveVisualizados) ?? <String>[];

      if (visualizados.contains(_avisoAtual.id)) {
        return null;
      }

      return _avisoAtual;
    } catch (_) {
      // Falha na leitura não deve bloquear o aplicativo.
      return null;
    }
  }

  Future<void> marcarComoVisualizado(String id) async {
    try {
      final visualizados =
          await _prefs.getStringList(_chaveVisualizados) ?? <String>[];

      if (!visualizados.contains(id)) {
        visualizados.add(id);

        await _prefs.setStringList(_chaveVisualizados, visualizados);
      }
    } catch (_) {
      // A navegação deve continuar mesmo com erro local.
    }
  }
}

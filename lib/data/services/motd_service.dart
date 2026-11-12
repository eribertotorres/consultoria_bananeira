import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/motd_message.dart';
import '/data/services/repositories/auth_repository.dart';

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
    MotdMessage? aviso;

    try {
      aviso = await _buscarAvisoRemoto();
    } catch (_) {
      // Falha remota: utiliza o aviso local.
      aviso = _avisoAtual;
    }

    // Resposta remota válida com data:null não usa o aviso local.
    if (aviso == null || !aviso.estaVigente) {
      return null;
    }

    try {
      final visualizados =
          await _prefs.getStringList(_chaveVisualizados) ?? <String>[];

      if (visualizados.contains(aviso.id)) {
        return null;
      }

      return aviso;
    } catch (_) {
      // Falha local não deve bloquear a navegação.
      return null;
    }
  }

  Future<MotdMessage?> _buscarAvisoRemoto() async {
    final response = await http
        .get(
          Uri.parse('${AuthRepository.baseUrl}/motd'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw Exception('Falha na consulta de comunicados.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! Map<String, dynamic> || !decoded.containsKey('data')) {
      throw const FormatException('Resposta MOTD inválida.');
    }

    final data = decoded['data'];

    if (data == null) return null;

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Dados MOTD inválidos.');
    }

    return MotdMessage.fromMap(data);
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

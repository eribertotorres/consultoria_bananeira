import 'dart:convert';

import 'package:http/http.dart' as http;

import '/data/models/historico_item.dart';
import '/data/services/database_service.dart';
import '/data/services/secure_storage_service.dart';

class HistoricoRepository {
  static const String _baseUrl = 'https://oquetemnomeucosmetico.com.br/api';

  final _database = DatabaseService.instance;
  final _storage = SecureStorageService();

  Future<List<HistoricoItem>> listarLocais() async {
    final resultados = await Future.wait([
      _database.listarAtendimentosPorStatus('pendente'),
      _database.listarAtendimentosPorStatus('verificar'),
      _database.listarAtendimentosPorStatus('sincronizado'),
    ]);

    return resultados
        .expand((registros) => registros)
        .map(HistoricoItem.fromLocal)
        .toList();
  }

  Future<List<HistoricoItem>> listarRemotos() async {
    final token = await _storage.recuperarToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sessão não encontrada.');
    }

    final response = await http
        .get(
          Uri.parse('$_baseUrl/historico'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível consultar o histórico: '
        'HTTP ${response.statusCode}',
      );
    }

    final corpo = jsonDecode(response.body) as Map<String, dynamic>;

    if (corpo['sucesso'] != true || corpo['dados'] is! List) {
      throw const FormatException('Resposta inesperada da API.');
    }

    return (corpo['dados'] as List<dynamic>)
        .map((item) => HistoricoItem.fromApi(item as Map<String, dynamic>))
        .toList();
  }
}

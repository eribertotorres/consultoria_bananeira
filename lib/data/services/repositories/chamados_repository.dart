import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:projeto_os/data/models/chamado_model.dart';
import 'package:projeto_os/data/services/database_service.dart';
import 'package:projeto_os/data/services/secure_storage_service.dart';

abstract class IChamadosRepository {
  Future<List<ChamadoModel>> listarChamados();

  bool get usandoDadosLocais;
}

class SessaoExpiradaException implements Exception {
  const SessaoExpiradaException();
}

class ChamadosRepository implements IChamadosRepository {
  static const String baseUrl = 'https://oquetemnomeucosmetico.com.br/api';

  late final SecureStorageService _secureStorage;

  final DatabaseService _database = DatabaseService.instance;

  // Indica a origem dos dados da última consulta.
  bool _usandoDadosLocais = false;

  @override
  bool get usandoDadosLocais => _usandoDadosLocais;

  ChamadosRepository({required SecureStorageService secureStorage}) {
    _secureStorage = secureStorage;
  }

  @override
  Future<List<ChamadoModel>> listarChamados() async {
    debugPrint('RF08: iniciando recuperação do token');
    final token = await _secureStorage.recuperarToken();
    debugPrint('RF08: recuperação do token concluída');

    if (token == null || token.isEmpty) {
      throw const SessaoExpiradaException();
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/chamados'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        throw const SessaoExpiradaException();
      }

      if (response.statusCode != 200) {
        throw HttpException(
          'Erro ao buscar chamados: HTTP ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['sucesso'] != true) {
        throw const FormatException('A API não confirmou a consulta.');
      }

      final dados = json['dados'] as List<dynamic>;

      final chamados = dados.map((item) {
        return ChamadoModel.fromMap(item as Map<String, dynamic>);
      }).toList();

      // Atualiza a cópia local.
      try {
        await _database.salvarChamados(chamados);
        debugPrint('SQLite: chamados salvos com sucesso.');
      } catch (e, stackTrace) {
        debugPrint('SQLite: erro ao salvar chamados: $e');
        debugPrintStack(stackTrace: stackTrace);
      }

      // A consulta foi atendida pela API.
      _usandoDadosLocais = false;

      return chamados;
    } on SocketException {
      return _carregarOffline();
    } on TimeoutException {
      return _carregarOffline();
    } on http.ClientException {
      return _carregarOffline();
    }
  }

  Future<List<ChamadoModel>> _carregarOffline() async {
    debugPrint('RF08: iniciando consulta ao SQLite');
    final chamados = await _database.listarChamadosLocais();
    debugPrint('RF08: SQLite retornou ${chamados.length} chamados');

    if (chamados.isNotEmpty) {
      // A consulta utilizou a cópia do SQLite.
      _usandoDadosLocais = true;

      debugPrint('CHAMADOS: utilizando dados locais (offline).');

      return chamados;
    }

    throw Exception('Sem conexão e sem chamados salvos no dispositivo.');
  }
}

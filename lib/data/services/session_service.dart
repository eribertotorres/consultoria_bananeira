import 'dart:convert';

import 'package:http/http.dart' as http;

import '/data/services/secure_storage_service.dart';
import '/data/services/repositories/auth_repository.dart';

class SessionService {
  final SecureStorageService secureStorage;

  SessionService({required this.secureStorage});

  Future<String?> recuperarToken() {
    return secureStorage.recuperarToken();
  }

  Future<bool> possuiToken() async {
    final token = await recuperarToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> validarSessao() async {
    final token = await recuperarToken();

    if (token == null || token.isEmpty) {
      return false;
    }

    final response = await http
        .get(
          Uri.parse('${AuthRepository.baseUrl}/auth/me'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      await secureStorage.removerToken();
      return false;
    }

    if (response.statusCode != 200) {
      throw Exception('Não foi possível validar a sessão.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Resposta de sessão inválida.');
    }

    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw const FormatException('Dados de sessão inválidos.');
    }

    final usuario = data['usuario'];

    if (usuario is! Map<String, dynamic> ||
        usuario['id'] is! int ||
        usuario['nome'] is! String ||
        usuario['email'] is! String) {
      throw const FormatException('Usuário da sessão inválido.');
    }

    return true;
  }

  // Ainda é apenas limpeza local.
  // Conectaremos este método ao logout remoto na próxima etapa.
  Future<void> encerrarSessao() async {
    final token = await recuperarToken();

    if (token == null || token.isEmpty) {
      await secureStorage.removerToken();
      return;
    }

    final response = await http
        .post(
          Uri.parse('${AuthRepository.baseUrl}/auth/logout'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 204 && response.statusCode != 401) {
      throw Exception('Não foi possível encerrar a sessão.');
    }

    await secureStorage.removerToken();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '/shared/result/result.dart';
import '/data/models/user_model.dart';
import '/data/services/secure_storage_service.dart';

abstract class IAuthRepository {
  Future<Result<UserModel>> login({
    required String email,
    required String password,
  });
}

class AuthRepository implements IAuthRepository {
  // Endereço de desenvolvimento para o emulador Android.
  static const String baseUrl = 'http://10.0.2.2/api/v1';

  final SecureStorageService _secureStorage = SecureStorageService();

  @override
  Future<Result<UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 500) {
        return Failure<UserModel>(
          Exception('Servidor indisponível. Tente novamente mais tarde.'),
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Resposta inválida.');
      }

      if (response.statusCode != 200) {
        final error = decoded['error'];
        final message = error is Map<String, dynamic> ? error['message'] : null;

        return Failure<UserModel>(
          Exception(
            message is String ? message : 'Não foi possível realizar o login.',
          ),
        );
      }

      final data = decoded['data'];

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Dados de login inválidos.');
      }

      final token = data['token'];
      final usuario = data['usuario'];

      if (token is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(token) ||
          data['token_type'] != 'Bearer' ||
          usuario is! Map<String, dynamic> ||
          usuario['id'] is! int ||
          usuario['nome'] is! String ||
          usuario['email'] is! String) {
        throw const FormatException('Contrato de login inválido.');
      }

      final user = UserModel.fromMap(usuario);

      await _secureStorage.salvarToken(token);

      return Success<UserModel>(user);
    } on TimeoutException {
      return Failure<UserModel>(
        Exception('Tempo de conexão esgotado. Tente novamente.'),
      );
    } on SocketException {
      return Failure<UserModel>(
        Exception('Não foi possível conectar à API local.'),
      );
    } on http.ClientException {
      return Failure<UserModel>(Exception('Falha de comunicação com a API.'));
    } on FormatException {
      return Failure<UserModel>(
        Exception('O servidor retornou uma resposta inesperada.'),
      );
    } on Exception {
      return Failure<UserModel>(
        Exception('Não foi possível concluir ou salvar o login.'),
      );
    }
  }
}

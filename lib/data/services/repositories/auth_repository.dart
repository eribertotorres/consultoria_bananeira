import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:projeto_os/shared/result/result.dart';
import 'package:projeto_os/data/models/user_model.dart';
import 'package:projeto_os/shared/utils/crypto_helper.dart';
import 'package:projeto_os/data/services/secure_storage_service.dart';

abstract class IAuthRepository {
  Future<Result<UserModel>> login({
    required String email,
    required String password,
  });
}

class AuthRepository implements IAuthRepository {
  static const String baseUrl = 'https://oquetemnomeucosmetico.com.br/api';
  final SecureStorageService _secureStorage = SecureStorageService();

  @override
  Future<Result<UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final senhaHmac = CryptoHelper.gerarHmacSha256(password);
      final url = Uri.parse('$baseUrl/login');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'senha_hmac': senhaHmac}),
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['sucesso'] == true) {
        final dados = json['dados'];
        final token = dados['token'] as String;
        final usuario = UserModel.fromMap(dados['usuario']);

        await _secureStorage.salvarToken(token);

        return Success<UserModel>(usuario);
      }

      final mensagem = json['mensagem'] ?? 'Erro ao realizar login.';

      return Failure<UserModel>(Exception(mensagem));
    } on TimeoutException {
      return Failure<UserModel>(
        Exception('Tempo de conexão esgotado. Tente novamente.'),
      );
    } on SocketException {
      return Failure<UserModel>(
        Exception('Sem conexão com o servidor. Verifique sua internet.'),
      );
    } on Exception {
      return Failure<UserModel>(
        Exception('Não foi possível realizar o login.'),
      );
    }
  }
}

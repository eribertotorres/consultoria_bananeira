import 'package:projeto_os/data/services/secure_storage_service.dart';

class SessionService {
  late final SecureStorageService _secureStorage;

  SessionService({required SecureStorageService secureStorage}) {
    _secureStorage = secureStorage;
  }

  Future<String?> recuperarToken() {
    return _secureStorage.recuperarToken();
  }

  Future<bool> possuiToken() async {
    final token = await recuperarToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> encerrarSessao() {
    return _secureStorage.removerToken();
  }
}

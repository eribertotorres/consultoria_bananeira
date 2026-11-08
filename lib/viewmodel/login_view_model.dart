import 'package:flutter/foundation.dart';
import 'package:projeto_os/data/services/repositories/auth_repository.dart';
import 'package:projeto_os/data/models/user_model.dart';
import 'package:projeto_os/shared/result/result.dart';

final class LoginViewModel extends ChangeNotifier {
  final IAuthRepository repository;

  LoginViewModel({required this.repository});

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.login(email: email, password: password);

    switch (result) {
      case Success<UserModel>():
        _user = result.data;
        _isLoading = false;
        notifyListeners();
        return true;

      case Failure<UserModel>():
        _user = null;
        _isLoading = false;
        _errorMessage = result.exception.toString().replaceFirst(
          'Exception: ',
          '',
        );

        notifyListeners();
        return false;
    }
  }
}

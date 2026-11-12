import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'view/login/login_view.dart';
import 'viewmodel/login_view_model.dart';
import 'data/services/repositories/auth_repository.dart';

import 'view/splash/splash_view.dart';
import 'shared/routes/app_routes.dart';

import 'view/home/erp_mobile_home_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Consultoria Bananeira',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashView(),
      routes: {
        AppRoutes.login: (context) => ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(repository: AuthRepository()),
          child: const LoginView(),
        ),
        AppRoutes.home: (context) => const ErpMobileHomeView(),
      },
    );
  }
}

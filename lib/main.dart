import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'view/login/login_view.dart';
import 'viewmodel/login_view_model.dart';
import 'data/services/repositories/auth_repository.dart';

import 'view/splash/splash_view.dart';
import 'view/home/home_view.dart';
import 'shared/routes/app_routes.dart';

import 'package:projeto_os/viewmodel/chamados_view_model.dart';
import 'package:projeto_os/data/services/repositories/chamados_repository.dart';
import 'package:projeto_os/data/services/secure_storage_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Projeto OS',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),

      home: const SplashView(),
      routes: {
        AppRoutes.login: (context) => ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(repository: AuthRepository()),
          child: const LoginView(),
        ),
        AppRoutes.home: (context) => ChangeNotifierProvider<ChamadosViewModel>(
          create: (context) => ChamadosViewModel(
            repository: ChamadosRepository(
              secureStorage: SecureStorageService(),
            ),
          )..carregarChamados(),
          child: const HomeView(),
        ),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: ApiTestView()),
  );
}

class ApiTestView extends StatefulWidget {
  const ApiTestView({super.key});

  @override
  State<ApiTestView> createState() => _ApiTestViewState();
}

class _ApiTestViewState extends State<ApiTestView> {
  late final Future<String> _resultado = _consultarApi();

  Future<String> _consultarApi() async {
    final response = await http
        .get(
          Uri.parse('http://10.0.2.2/api/v1/health'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Servidor retornou HTTP ${response.statusCode}.');
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));

    if (json is! Map<String, dynamic>) {
      throw const FormatException('Resposta JSON inválida.');
    }

    final data = json['data'];

    if (data is! Map<String, dynamic> ||
        data['status'] != 'ok' ||
        data['service'] != 'consultoria-bananeira-api') {
      throw const FormatException('Resposta diferente do contrato esperado.');
    }

    return 'API conectada!\n\nServiço: ${data['service']}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico da API')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<String>(
            future: _resultado,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator();
              }

              return SelectableText(
                snapshot.hasError
                    ? 'Falha na consulta:\n${snapshot.error}'
                    : snapshot.data!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              );
            },
          ),
        ),
      ),
    );
  }
}

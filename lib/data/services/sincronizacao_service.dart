import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '/data/services/database_service.dart';
import '/data/services/secure_storage_service.dart';

class SincronizacaoService {
  static const String _baseUrl = 'https://oquetemnomeucosmetico.com.br/api';

  static const int _limiteFotoBytes = 5 * 1024 * 1024;

  final DatabaseService _database = DatabaseService.instance;
  final SecureStorageService _storage = SecureStorageService();

  // Consulta o servidor sem registrar novos atendimentos.
  Future<List<dynamic>> _consultarHistorico(String token) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/historico'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ao consultar histórico: HTTP ${response.statusCode}',
      );
    }

    final corpo = jsonDecode(response.body) as Map<String, dynamic>;

    if (corpo['sucesso'] != true || corpo['dados'] is! List) {
      throw const FormatException('Resposta inesperada do histórico.');
    }

    return corpo['dados'] as List<dynamic>;
  }

  Future<String> _recuperarToken() async {
    final token = await _storage.recuperarToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sessão não encontrada.');
    }

    return token;
  }

  // Verifica a imagem antes de alterar o status do atendimento.
  // Retorna null quando o atendimento não possui fotografia.
  Future<File?> _prepararFoto(Map<String, Object?> atendimento) async {
    final caminho = atendimento['foto_path'] as String?;

    if (caminho == null || caminho.trim().isEmpty) {
      return null;
    }

    final arquivo = File(caminho);

    if (!await arquivo.exists()) {
      throw StateError(
        'A fotografia do atendimento não foi encontrada no dispositivo.',
      );
    }

    final tamanho = await arquivo.length();

    if (tamanho == 0 || tamanho > _limiteFotoBytes) {
      throw StateError(
        'A fotografia está vazia ou ultrapassa o limite de 5 MB.',
      );
    }

    final extensao = caminho.split('.').last.toLowerCase();

    if (!['jpg', 'jpeg', 'png', 'webp'].contains(extensao)) {
      throw StateError('Formato de fotografia não permitido pela API.');
    }

    return arquivo;
  }

  // Confere registros incertos contra o histórico da API.
  // Nunca reenvia atendimentos.
  Future<int> reconciliarVerificar() async {
    final token = await _recuperarToken();

    // Se estiver offline, falha antes de alterar o SQLite.
    final historico = await _consultarHistorico(token);

    final registros = await _database.listarAtendimentosPorStatus('verificar');

    int confirmados = 0;

    for (final registro in registros) {
      final chamadoId = registro['chamado_id'] as int;

      final categoriaLocal = (registro['categoria_tecnico'] as String).trim();

      final procedimentoLocal = (registro['descricao_procedimento'] as String)
          .trim();

      final caminhoFoto = registro['foto_path'] as String?;
      final possuiFotoLocal =
          caminhoFoto != null && caminhoFoto.trim().isNotEmpty;

      bool encontrado = false;

      for (final item in historico) {
        if (item is! Map<String, dynamic>) continue;

        if (item['chamado_id'] != chamadoId) continue;
        if (item['status_chamado'] != 'resolvido') continue;

        final atendimento = item['atendimento'];

        if (atendimento is! Map<String, dynamic>) continue;

        final categoriaRemota = atendimento['categoria_tecnico'];
        final procedimentoRemoto = atendimento['descricao_procedimento'];

        if (categoriaRemota is! String || procedimentoRemoto is! String) {
          continue;
        }

        final fotoUrl = atendimento['foto_url'];
        final possuiFotoRemota = fotoUrl is String && fotoUrl.trim().isNotEmpty;

        // Se havia foto no envio, exige foto no histórico.
        if (possuiFotoLocal && !possuiFotoRemota) {
          continue;
        }

        if (categoriaRemota.trim() == categoriaLocal &&
            procedimentoRemoto.trim() == procedimentoLocal) {
          encontrado = true;
          break;
        }
      }

      debugPrint('SYNC: OS #$chamadoId confirmada no histórico: $encontrado');

      if (encontrado) {
        await _database.atualizarStatusAtendimento(
          registro['id'] as int,
          'sincronizado',
        );

        confirmados++;
      } else {
        debugPrint('SYNC: OS #$chamadoId ainda exige verificação.');
      }
    }

    return confirmados;
  }

  Future<int> sincronizarPendentes() async {
    final token = await _recuperarToken();

    // Valida a conexão autenticada antes de iniciar os POSTs.
    await _consultarHistorico(token);

    final registrosVerificar = await _database.listarAtendimentosPorStatus(
      'verificar',
    );

    if (registrosVerificar.isNotEmpty) {
      throw Exception(
        'Existem atendimentos que precisam ser verificados '
        'antes de uma nova sincronização.',
      );
    }

    final pendentes = await _database.listarAtendimentosPendentes();

    int sincronizados = 0;

    for (final atendimento in pendentes) {
      final id = atendimento['id'] as int;
      final chamadoId = atendimento['chamado_id'] as int;

      // Falhas no arquivo devem ocorrer antes do status
      // mudar de pendente para verificar.
      final foto = await _prepararFoto(atendimento);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/atendimento'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['chamado_id'] = chamadoId.toString();
      request.fields['categoria_tecnico'] =
          atendimento['categoria_tecnico'] as String;
      request.fields['descricao_procedimento'] =
          atendimento['descricao_procedimento'] as String;
      final dataResolucao = atendimento['data_resolucao'] as String?;

      if (dataResolucao != null && dataResolucao.isNotEmpty) {
        final data = DateTime.parse(dataResolucao).toLocal();

        String doisDigitos(int valor) => valor.toString().padLeft(2, '0');

        request.fields['data_resolucao'] =
            '${data.year}-${doisDigitos(data.month)}-${doisDigitos(data.day)} '
            '${doisDigitos(data.hour)}:${doisDigitos(data.minute)}:'
            '${doisDigitos(data.second)}';
      }
      // Campo exigido pela API: foto.
      if (foto != null) {
        request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
      }

      // A partir daqui, um problema na conexão pode tornar
      // desconhecido o resultado do envio.
      await _database.atualizarStatusAtendimento(id, 'verificar');

      try {
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 30),
        );

        final response = await http.Response.fromStream(streamedResponse)
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 201) {
          final corpo = jsonDecode(response.body) as Map<String, dynamic>;

          final dados = corpo['dados'];

          if (corpo['sucesso'] == true &&
              dados is Map<String, dynamic> &&
              dados['chamado_id'] == chamadoId &&
              dados['status_chamado'] == 'resolvido') {
            final fotoUrl = dados['foto_url'];

            final fotoConfirmada =
                foto == null ||
                (fotoUrl is String && fotoUrl.trim().isNotEmpty);

            if (fotoConfirmada) {
              await _database.atualizarStatusAtendimento(id, 'sincronizado');

              sincronizados++;
              continue;
            }

            debugPrint(
              'SYNC: OS #$chamadoId resolvida, '
              'mas sem confirmação da fotografia.',
            );
          }
        }

        debugPrint(
          'SYNC: OS #$chamadoId retornou '
          'HTTP ${response.statusCode}.',
        );

        // Não repete automaticamente a operação.
        break;
      } on Exception catch (e) {
        debugPrint(
          'SYNC: resultado desconhecido para OS '
          '#$chamadoId: $e',
        );
        break;
      }
    }

    return sincronizados;
  }

  Future<bool> chamadoAtivoNoServidor(int chamadoId) async {
    final token = await _recuperarToken();

    final response = await http
        .get(
          Uri.parse('$_baseUrl/chamados'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível verificar a OS: '
        'HTTP ${response.statusCode}',
      );
    }

    final corpo = jsonDecode(response.body) as Map<String, dynamic>;

    if (corpo['sucesso'] != true || corpo['dados'] is! List) {
      throw const FormatException('Resposta inesperada ao consultar chamados.');
    }

    final chamados = corpo['dados'] as List<dynamic>;

    return chamados.any(
      (item) => item is Map<String, dynamic> && item['id'] == chamadoId,
    );
  }

  Future<bool> recuperarAtendimento(int chamadoId) async {
    final token = await _recuperarToken();

    final historico = await _consultarHistorico(token);

    final jaResolvido = historico.any(
      (item) => item is Map<String, dynamic> && item['chamado_id'] == chamadoId,
    );

    if (jaResolvido) {
      throw Exception(
        'A OS já consta no histórico do servidor. '
        'Não é seguro reenviá-la.',
      );
    }

    final continuaAtiva = await chamadoAtivoNoServidor(chamadoId);

    if (!continuaAtiva) {
      throw Exception('A OS não está ativa no servidor.');
    }

    final registros = await _database.listarAtendimentosPorStatus('verificar');

    final correspondentes = registros
        .where((registro) => registro['chamado_id'] == chamadoId)
        .toList();

    if (correspondentes.length != 1) {
      throw Exception(
        'Não foi encontrado exatamente um atendimento '
        'em verificação para essa OS.',
      );
    }

    await _database.atualizarStatusAtendimento(
      correspondentes.first['id'] as int,
      'pendente',
    );

    return true;
  }
}

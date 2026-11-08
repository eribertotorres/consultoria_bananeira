import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:projeto_os/data/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory diretorioTemporario;
  late DatabaseService service;
  late Database db;

  const chamadoId = 990001;

  setUpAll(() async {
    // Habilita SQLite no ambiente de testes.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Banco isolado: nunca utiliza os dados do aplicativo.
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'clayton_test_',
    );

    await databaseFactoryFfi.setDatabasesPath(diretorioTemporario.path);

    service = DatabaseService.instance;
    db = await service.database;
  });

  setUp(() async {
    // Cada teste começa com o atendimento de teste limpo.
    await db.delete(
      'atendimentos_pendentes',
      where: 'chamado_id = ?',
      whereArgs: [chamadoId],
    );
  });

  tearDownAll(() async {
    await db.close();

    if (await diretorioTemporario.exists()) {
      await diretorioTemporario.delete(recursive: true);
    }
  });

  test('Banco possui coluna data_resolucao', () async {
    final colunas = await db.rawQuery(
      'PRAGMA table_info(atendimentos_pendentes)',
    );

    final nomes = colunas.map((coluna) => coluna['name']).toList();

    expect(nomes, contains('data_resolucao'));
    expect(nomes, contains('foto_path'));
  });

  test('Salva atendimento offline com foto e data', () async {
    final data = DateTime(2026, 10, 30, 10, 30);

    await service.salvarAtendimentoPendente(
      chamadoId: chamadoId,
      categoriaTecnico: 'Conector danificado',
      descricaoProcedimento: 'Conector substituído e testado.',
      fotoPath: '/teste/foto.jpg',
      dataResolucao: data,
    );

    final registro = await service.buscarAtendimentoPendente(chamadoId);

    expect(registro, isNotNull);
    expect(registro!['status'], 'pendente');
    expect(registro['categoria_tecnico'], 'Conector danificado');
    expect(registro['foto_path'], '/teste/foto.jpg');
    expect(registro['data_resolucao'], data.toIso8601String());
  });

  test('Atualização preserva foto e timestamp originais', () async {
    final dataOriginal = DateTime(2026, 10, 30, 9, 15);

    await service.salvarAtendimentoPendente(
      chamadoId: chamadoId,
      categoriaTecnico: 'Falha de sinal',
      descricaoProcedimento: 'Sinal verificado e corrigido.',
      fotoPath: '/teste/original.jpg',
      dataResolucao: dataOriginal,
    );

    await service.salvarAtendimentoPendente(
      chamadoId: chamadoId,
      categoriaTecnico: 'Conector danificado',
      descricaoProcedimento: 'Conector substituído após diagnóstico.',
      // Sem outra foto e sem outra data.
    );

    final registro = await service.buscarAtendimentoPendente(chamadoId);

    expect(registro, isNotNull);
    expect(registro!['categoria_tecnico'], 'Conector danificado');
    expect(registro['foto_path'], '/teste/original.jpg');
    expect(registro['data_resolucao'], dataOriginal.toIso8601String());
  });

  test('Impede edição de atendimento sincronizado', () async {
    await service.salvarAtendimentoPendente(
      chamadoId: chamadoId,
      categoriaTecnico: 'Problema na ONU',
      descricaoProcedimento: 'Equipamento substituído e validado.',
      fotoPath: '/teste/foto.jpg',
    );

    final registro = await service.buscarAtendimentoPendente(chamadoId);

    final id = registro!['id'] as int;

    await service.atualizarStatusAtendimento(id, 'sincronizado');

    await expectLater(
      service.salvarAtendimentoPendente(
        chamadoId: chamadoId,
        categoriaTecnico: 'Outros',
        descricaoProcedimento: 'Tentativa de alteração indevida.',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('Identifica OS que já possui atendimento', () async {
    await service.salvarAtendimentoPendente(
      chamadoId: chamadoId,
      categoriaTecnico: 'Falha de configuração',
      descricaoProcedimento: 'Configuração corrigida e validada.',
      fotoPath: '/teste/foto.jpg',
    );

    final ids = await service.listarIdsComAtendimento();

    expect(ids, contains(chamadoId));
  });
}

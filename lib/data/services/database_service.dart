import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:projeto_os/data/models/chamado_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();

  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _inicializarBanco();
    return _database!;
  }

  Future<Database> _inicializarBanco() async {
    final caminho = join(await getDatabasesPath(), 'projeto_os.db');

    return openDatabase(
      caminho,
      version: 4,

      // Banco criado pela primeira vez.
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE chamados (
            id INTEGER PRIMARY KEY,
            codigo_cliente TEXT NOT NULL,
            nome_cliente TEXT NOT NULL,
            categoria_informada TEXT NOT NULL,
            descricao_problema TEXT NOT NULL,
            endereco_cliente TEXT NOT NULL,
            bairro TEXT NOT NULL,
            cidade TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            status TEXT NOT NULL,
            criado_em TEXT NOT NULL
          )
        ''');

        await _criarTabelaAtendimentos(db);
      },

      // Atualiza bancos existentes sem perder registros.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _criarTabelaAtendimentos(db);
        }

        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE atendimentos_pendentes
            ADD COLUMN foto_path TEXT
          ''');
        }
        if (oldVersion < 4) {
          final colunas = await db.rawQuery(
            'PRAGMA table_info(atendimentos_pendentes)',
          );

          final colunaExiste = colunas.any(
            (coluna) => coluna['name'] == 'data_resolucao',
          );

          if (!colunaExiste) {
            await db.execute('''
      ALTER TABLE atendimentos_pendentes
      ADD COLUMN data_resolucao TEXT
    ''');
          }
        }
      },
    );
  }

  Future<void> _criarTabelaAtendimentos(Database db) async {
    await db.execute('''
    CREATE TABLE IF NOT EXISTS atendimentos_pendentes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chamado_id INTEGER NOT NULL UNIQUE,
      categoria_tecnico TEXT NOT NULL,
      descricao_procedimento TEXT NOT NULL,
      criado_em TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pendente',
      foto_path TEXT,
      data_resolucao TEXT
    )
  ''');
  }

  Future<void> salvarAtendimentoPendente({
    required int chamadoId,
    required String categoriaTecnico,
    required String descricaoProcedimento,
    String? fotoPath,
    DateTime? dataResolucao,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      final existentes = await txn.query(
        'atendimentos_pendentes',
        columns: ['id', 'status'],
        where: 'chamado_id = ?',
        whereArgs: [chamadoId],
        limit: 1,
      );

      if (existentes.isNotEmpty) {
        final registro = existentes.first;

        if (registro['status'] != 'pendente') {
          throw StateError('Este atendimento não pode mais ser alterado.');
        }

        final dadosAtualizados = <String, Object?>{
          'categoria_tecnico': categoriaTecnico,
          'descricao_procedimento': descricaoProcedimento,
        };

        // Só substitui a foto quando outra foi selecionada.
        if (fotoPath != null) {
          dadosAtualizados['foto_path'] = fotoPath;
        }

        await txn.update(
          'atendimentos_pendentes',
          dadosAtualizados,
          where: 'id = ? AND status = ?',
          whereArgs: [registro['id'], 'pendente'],
        );
      } else {
        await txn.insert('atendimentos_pendentes', {
          'chamado_id': chamadoId,
          'categoria_tecnico': categoriaTecnico,
          'descricao_procedimento': descricaoProcedimento,
          'criado_em': DateTime.now().toIso8601String(),
          'status': 'pendente',
          'foto_path': fotoPath,
          'data_resolucao': dataResolucao?.toIso8601String(),
        });
      }
    });
  }

  Future<void> salvarChamados(List<ChamadoModel> chamados) async {
    final db = await database;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final chamado in chamados) {
        batch.insert(
          'chamados',
          chamado.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  Future<List<ChamadoModel>> listarChamadosLocais() async {
    final db = await database;

    final registros = await db.query('chamados', orderBy: 'criado_em DESC');

    return registros.map((registro) => ChamadoModel.fromMap(registro)).toList();
  }

  Future<Map<String, Object?>?> buscarAtendimentoPendente(int chamadoId) async {
    final db = await database;

    final registros = await db.query(
      'atendimentos_pendentes',
      where: 'chamado_id = ?',
      whereArgs: [chamadoId],
      limit: 1,
    );

    if (registros.isEmpty) return null;

    return registros.first;
  }

  Future<List<Map<String, Object?>>> listarAtendimentosPendentes() async {
    final db = await database;

    return db.query(
      'atendimentos_pendentes',
      where: 'status = ?',
      whereArgs: ['pendente'],
      orderBy: 'criado_em ASC',
    );
  }

  Future<void> atualizarStatusAtendimento(int id, String status) async {
    final db = await database;

    await db.update(
      'atendimentos_pendentes',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, Object?>>> listarAtendimentosPorStatus(
    String status,
  ) async {
    final db = await database;

    return db.query(
      'atendimentos_pendentes',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'criado_em ASC',
    );
  }

  Future<Set<int>> listarIdsComAtendimento() async {
    final db = await database;

    final registros = await db.query(
      'atendimentos_pendentes',
      columns: ['chamado_id'],
    );

    return registros.map((registro) => registro['chamado_id'] as int).toSet();
  }
}

import 'package:flutter/material.dart';

import 'package:projeto_os/data/services/database_service.dart';
import 'package:projeto_os/data/services/sincronizacao_service.dart';

class SincronizacaoView extends StatefulWidget {
  const SincronizacaoView({super.key});

  @override
  State<SincronizacaoView> createState() => _SincronizacaoViewState();
}

class _SincronizacaoViewState extends State<SincronizacaoView> {
  String _mensagemErroSincronizacao(Object erro) {
    final descricao = erro.toString().toLowerCase();

    if (descricao.contains('socketexception') ||
        descricao.contains('clientexception') ||
        descricao.contains('failed host lookup') ||
        descricao.contains('network is unreachable') ||
        descricao.contains('connection refused') ||
        descricao.contains('tempo') ||
        descricao.contains('timeout')) {
      return 'Sem conexão com o servidor. '
          'Seus atendimentos continuam salvos no dispositivo.';
    }

    if (descricao.contains('sessão') || descricao.contains('401')) {
      return 'Sua sessão precisa ser renovada. '
          'Os atendimentos locais foram preservados.';
    }

    if (descricao.contains('verificar')) {
      return 'Existem atendimentos aguardando conferência. '
          'Verifique-os antes de uma nova sincronização.';
    }

    return 'Não foi possível concluir a sincronização. '
        'Consulte o status dos atendimentos antes de tentar novamente.';
  }

  Future<void> _recuperarAtendimento(int chamadoId) async {
    if (_sincronizando || _carregando) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recuperar atendimento?'),
          content: Text(
            'A OS #$chamadoId será conferida novamente '
            'no servidor.\n\n'
            'Se continuar ativa e não constar no histórico, '
            'seu atendimento local poderá voltar para '
            'PENDENTE.\n\n'
            'Esta operação não envia o atendimento.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Conferir e recuperar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !mounted) return;

    setState(() {
      _sincronizando = true;
    });

    try {
      final recuperado = await _sincronizacao.recuperarAtendimento(chamadoId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recuperado
                ? 'OS #$chamadoId recuperada. '
                      'Atendimento novamente pendente.'
                : 'Não foi possível recuperar a OS #$chamadoId.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao recuperar OS #$chamadoId: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sincronizando = false;
        });

        await _carregarFila();
      }
    }
  }

  final _database = DatabaseService.instance;
  final _sincronizacao = SincronizacaoService();

  bool _carregando = true;
  bool _sincronizando = false;

  String? _erro;

  List<Map<String, Object?>> _pendentes = [];
  List<Map<String, Object?>> _verificar = [];
  List<Map<String, Object?>> _sincronizados = [];
  Future<void> _conferirNoServidor() async {
    if (_sincronizando || _carregando || _verificar.isEmpty) {
      return;
    }

    setState(() {
      _sincronizando = true;
    });

    try {
      final confirmados = await _sincronizacao.reconciliarVerificar();
      final osAtiva = await _sincronizacao.chamadoAtivoNoServidor(1201);

      debugPrint('DIAGNOSTICO: OS #1201 ativa no servidor = $osAtiva');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$confirmados atendimento(s) confirmado(s) '
            'pelo histórico do servidor.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_mensagemErroSincronizacao(e))));
    } finally {
      if (mounted) {
        setState(() {
          _sincronizando = false;
        });

        await _carregarFila();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarFila();
  }

  Future<void> _carregarFila() async {
    if (!mounted) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultados = await Future.wait([
        _database.listarAtendimentosPorStatus('pendente'),
        _database.listarAtendimentosPorStatus('verificar'),
        _database.listarAtendimentosPorStatus('sincronizado'),
      ]);

      if (!mounted) return;

      setState(() {
        _pendentes = resultados[0];
        _verificar = resultados[1];
        _sincronizados = resultados[2];
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível consultar a fila: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _sincronizarAgora() async {
    if (_sincronizando || _carregando || _pendentes.isEmpty) {
      return;
    }

    setState(() {
      _sincronizando = true;
    });

    try {
      final quantidade = await _sincronizacao.sincronizarPendentes();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$quantidade atendimento(s) confirmado(s) pela API. '
            'Confira o estado dos demais registros.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final mensagem = _mensagemErroSincronizacao(e);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sincronizando = false;
        });

        await _carregarFila();
      }
    }
  }

  Widget _cartaoAtendimento(Map<String, Object?> atendimento, String status) {
    final chamadoId = atendimento['chamado_id'] as int;
    final categoria = atendimento['categoria_tecnico'];
    final procedimento = atendimento['descricao_procedimento'];

    final IconData icone;
    final Color cor;

    switch (status) {
      case 'sincronizado':
        icone = Icons.check_circle_outline;
        cor = Colors.green;
      case 'verificar':
        icone = Icons.warning_amber_outlined;
        cor = Colors.orange;
      default:
        icone = Icons.schedule;
        cor = Colors.blueGrey;
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icone, color: cor),
            title: Text('OS #$chamadoId'),
            subtitle: Text(
              'Categoria: $categoria\n'
              'Procedimento: $procedimento\n'
              'Status: $status',
            ),
            isThreeLine: true,
          ),

          if (status == 'verificar')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _sincronizando || _carregando
                      ? null
                      : () => _recuperarAtendimento(chamadoId),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Recuperar atendimento'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _secao(
    String titulo,
    List<Map<String, Object?>> atendimentos,
    String status,
  ) {
    if (atendimentos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          '$titulo (${atendimentos.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...atendimentos.map(
          (atendimento) => _cartaoAtendimento(atendimento, status),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _pendentes.length + _verificar.length + _sincronizados.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronização'),
        actions: [
          IconButton(
            tooltip: 'Atualizar fila',
            onPressed: _carregando || _sincronizando ? null : _carregarFila,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(child: Text(_erro!))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Atendimentos no dispositivo: $total',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pendentes: ${_pendentes.length}  •  '
                  'Verificar: ${_verificar.length}  •  '
                  'Sincronizados: ${_sincronizados.length}',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed:
                      _sincronizando ||
                          _pendentes.isEmpty ||
                          _verificar.isNotEmpty
                      ? null
                      : _sincronizarAgora,
                  icon: _sincronizando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                    _sincronizando ? 'Sincronizando...' : 'Sincronizar agora',
                  ),
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _sincronizando || _carregando || _verificar.isEmpty
                      ? null
                      : _conferirNoServidor,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Conferir no servidor'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Registros em "verificar" precisam de '
                  'conferência no servidor antes de '
                  'qualquer novo envio.',
                  textAlign: TextAlign.center,
                ),
                if (total == 0)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('Nenhum atendimento local encontrado.'),
                    ),
                  ),
                _secao('Aguardando envio', _pendentes, 'pendente'),
                _secao('Necessitam verificação', _verificar, 'verificar'),
                _secao('Confirmados', _sincronizados, 'sincronizado'),
              ],
            ),
    );
  }
}

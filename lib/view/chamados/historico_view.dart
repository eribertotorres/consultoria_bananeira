import 'package:flutter/material.dart';

import '/data/models/historico_item.dart';
import '/data/services/repositories/historico_repository.dart';

class HistoricoView extends StatefulWidget {
  const HistoricoView({super.key});

  @override
  State<HistoricoView> createState() => _HistoricoViewState();
}

class _HistoricoViewState extends State<HistoricoView> {
  final _repository = HistoricoRepository();
  final _buscaController = TextEditingController();

  List<HistoricoItem> _itens = [];

  bool _carregando = true;
  bool _servidorIndisponivel = false;
  String _busca = '';
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // Carrega os atendimentos locais e consulta o servidor.
  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
      _servidorIndisponivel = false;
    });

    try {
      final locais = await _repository.listarLocais();

      List<HistoricoItem> remotos = [];
      bool servidorIndisponivel = false;

      try {
        remotos = await _repository.listarRemotos();
      } catch (e) {
        servidorIndisponivel = true;
        debugPrint('HISTORICO: consulta remota indisponível: $e');
      }

      // O servidor é a fonte principal dos registros sincronizados.
      final idsRemotos = remotos.map((e) => e.chamadoId).toSet();

      final locaisNaoDuplicados = locais.where(
        (item) => !idsRemotos.contains(item.chamadoId),
      );

      if (!mounted) return;

      setState(() {
        _servidorIndisponivel = servidorIndisponivel;

        _itens = [...locaisNaoDuplicados, ...remotos]
          ..sort((a, b) => a.chamadoId.compareTo(b.chamadoId));
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar o histórico: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  // Formata a data para o padrão brasileiro.
  String _formatarData(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Não informada';
    }

    try {
      final data = DateTime.parse(valor).toLocal();

      String doisDigitos(int numero) => numero.toString().padLeft(2, '0');

      return '${doisDigitos(data.day)}/'
          '${doisDigitos(data.month)}/'
          '${data.year} às '
          '${doisDigitos(data.hour)}:'
          '${doisDigitos(data.minute)}';
    } catch (_) {
      return valor;
    }
  }

  // Filtra os atendimentos por ID da OS ou código do cliente.
  List<HistoricoItem> get _filtrados {
    final termo = _busca.trim().toLowerCase();

    if (termo.isEmpty) return _itens;

    return _itens.where((item) {
      return item.chamadoId.toString().contains(termo) ||
          item.codigoCliente.toLowerCase().contains(termo);
    }).toList();
  }

  String _rotuloStatus(String status) {
    switch (status) {
      case 'sincronizado':
        return 'Sincronizado';
      case 'pendente':
        return 'Pendente de envio';
      case 'verificar':
        return 'Necessita conferência';
      default:
        return status;
    }
  }

  // Exibe os detalhes do atendimento.
  void _abrirDetalhes(HistoricoItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('OS #${item.chamadoId}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.nomeCliente.isNotEmpty) ...[
                    Text('Cliente: ${item.nomeCliente}'),
                    const SizedBox(height: 8),
                  ],

                  if (item.codigoCliente.isNotEmpty) ...[
                    Text('Código: ${item.codigoCliente}'),
                    const SizedBox(height: 8),
                  ],

                  Text('Status: ${_rotuloStatus(item.status)}'),

                  const SizedBox(height: 8),

                  Text(
                    'Concluído em: '
                    '${_formatarData(item.dataResolucao)}',
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Categoria técnica',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  Text(item.categoria),

                  const SizedBox(height: 16),

                  const Text(
                    'Procedimento realizado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  Text(item.procedimento),

                  if (item.fotoUrl != null && item.fotoUrl!.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    const Text(
                      'Foto do atendimento',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    Image.network(
                      item.fotoUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Foto indisponível no momento.');
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de atendimentos'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Atualizar histórico',
            onPressed: _carregando ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _buscaController,
              onChanged: (valor) {
                setState(() => _busca = valor);
              },
              decoration: const InputDecoration(
                labelText: 'Pesquisar OS ou código do cliente',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          if (_servidorIndisponivel)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sem acesso ao histórico do servidor. '
                'Exibindo os registros disponíveis no dispositivo.',
                textAlign: TextAlign.center,
              ),
            ),

          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _erro != null
                ? Center(child: Text(_erro!, textAlign: TextAlign.center))
                : filtrados.isEmpty
                ? const Center(child: Text('Nenhum atendimento encontrado.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) {
                      final item = filtrados[index];

                      final sincronizado = item.status == 'sincronizado';

                      return Card(
                        child: ListTile(
                          leading: Icon(
                            sincronizado
                                ? Icons.check_circle_outline
                                : Icons.pending_actions,
                            color: sincronizado ? Colors.green : Colors.orange,
                          ),
                          title: Text(
                            'OS #${item.chamadoId}'
                            '${item.nomeCliente.isNotEmpty ? ' — ${item.nomeCliente}' : ''}',
                          ),
                          subtitle: Text(
                            '${item.categoria}\n'
                            '${_rotuloStatus(item.status)}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _abrirDetalhes(item),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

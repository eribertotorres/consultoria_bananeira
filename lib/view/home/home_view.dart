import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '/viewmodel/chamados_view_model.dart';
import '/view/chamados/chamado_detalhe_view.dart';
import '/view/chamados/sincronizacao_view.dart';
import '/view/chamados/historico_view.dart';
import '/view/widgets/lili_tips.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChamadosViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ordens de Serviço'), centerTitle: true),
      body: Column(
        children: [
          // Barra de navegação.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _botaoMenu(
                    icone: Icons.history,
                    texto: 'Histórico',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HistoricoView(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _botaoMenu(
                    icone: Icons.sync,
                    texto: 'Sincronização',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SincronizacaoView(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _botaoMenu(
                    icone: Icons.refresh,
                    texto: 'Atualizar OS',
                    onPressed: viewModel.carregarChamados,
                  ),
                ),
              ],
            ),
          ),

          // Ordenação por proximidade.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: OutlinedButton.icon(
              icon: Icon(
                viewModel.ordenadoPorProximidade
                    ? Icons.format_list_numbered
                    : Icons.near_me,
              ),
              label: Text(
                viewModel.ordenadoPorProximidade
                    ? 'Ordem original'
                    : 'Ordenar por proximidade',
              ),
              onPressed: () async {
                if (viewModel.ordenadoPorProximidade) {
                  viewModel.restaurarOrdemOriginal();
                  return;
                }

                try {
                  await viewModel.ordenarPorProximidade();
                } catch (e) {
                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Não foi possível obter sua localização: $e',
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // Aviso offline: aparece somente após a consulta
          // terminar com sucesso usando os dados do SQLite.
          if (!viewModel.isLoading &&
              viewModel.errorMessage == null &&
              viewModel.usandoDadosLocais)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cloud_off_outlined, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Modo offline — exibindo chamados salvos '
                        'no dispositivo.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Supervisora Lili.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: LiliTips(),
          ),

          // Listagem de ordens de serviço.
          Expanded(child: _buildBody(context, viewModel)),
        ],
      ),
    );
  }

  Widget _botaoMenu({
    required IconData icone,
    required String texto,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 22),
          const SizedBox(height: 4),
          Text(
            texto,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChamadosViewModel viewModel) {
    // Carregamento: depende somente de isLoading.
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Erro na consulta.
    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(viewModel.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: viewModel.carregarChamados,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final chamados = viewModel.chamadosOrdenados;

    if (chamados.isEmpty) {
      return const Center(child: Text('Nenhuma ordem de serviço disponível.'));
    }

    return RefreshIndicator(
      onRefresh: viewModel.carregarChamados,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: chamados.length,
        itemBuilder: (context, index) {
          final chamado = chamados[index];
          final distancia = viewModel.distanciaDaOs(chamado.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChamadoDetalheView(chamado: chamado),
                      ),
                    );

                    if (!context.mounted) return;

                    // Atualiza o filtro de OS já atendidas,
                    // sem depender de conexão com a internet.
                    await viewModel.atualizarAtendimentosLocais();
                  },
                  leading: const Icon(Icons.build_outlined),
                  title: Text('OS #${chamado.id} — ${chamado.nomeCliente}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Cliente: ${chamado.codigoCliente}'),
                      Text('Categoria: ${chamado.categoriaInformada}'),
                      Text(
                        'Problema: ${chamado.descricaoProblema}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Endereço: ${chamado.enderecoCliente}, '
                        '${chamado.bairro} — ${chamado.cidade}',
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),

                // Distância em quilômetros, quando calculada.
                if (viewModel.ordenadoPorProximidade && distancia != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Distância aproximada: '
                          '${distancia.toStringAsFixed(1)} km',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

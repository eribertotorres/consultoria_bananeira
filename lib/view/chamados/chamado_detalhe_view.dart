import 'package:flutter/material.dart';

import '/data/models/chamado_model.dart';
import '/view/chamados/registrar_atendimento_view.dart';

import '/view/widgets/clima_card.dart';

class ChamadoDetalheView extends StatelessWidget {
  final ChamadoModel chamado;

  const ChamadoDetalheView({super.key, required this.chamado});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OS #${chamado.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chamado.nomeCliente,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Código: ${chamado.codigoCliente}'),
                  Text('Status: ${chamado.status}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          _secao(
            context,
            titulo: 'Problema informado',
            icone: Icons.build_outlined,
            conteudo:
                'Categoria: ${chamado.categoriaInformada}\n\n'
                '${chamado.descricaoProblema}',
          ),

          const SizedBox(height: 16),

          _secao(
            context,
            titulo: 'Local do atendimento',
            icone: Icons.location_on_outlined,
            conteudo:
                '${chamado.enderecoCliente}\n'
                '${chamado.bairro} - ${chamado.cidade}',
          ),
          const SizedBox(height: 16),

          ClimaCard(latitude: chamado.latitude, longitude: chamado.longitude),

          const SizedBox(height: 16),

          _secao(
            context,
            titulo: 'Informações adicionais',
            icone: Icons.info_outline,
            conteudo:
                'Aberto em: ${_formatarData(chamado.criadoEm)}\n'
                'Latitude: ${chamado.latitude}\n'
                'Longitude: ${chamado.longitude}',
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      RegistrarAtendimentoView(chamado: chamado),
                ),
              );
            },
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Registrar atendimento'),
          ),
        ],
      ),
    );
  }

  Widget _secao(
    BuildContext context, {
    required String titulo,
    required IconData icone,
    required String conteudo,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone),
                const SizedBox(width: 8),
                Text(titulo, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(conteudo),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;

    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }
}

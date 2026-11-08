import 'package:flutter/material.dart';

import '/data/services/clima_service.dart';

class ClimaCard extends StatefulWidget {
  final double latitude;
  final double longitude;

  const ClimaCard({super.key, required this.latitude, required this.longitude});

  @override
  State<ClimaCard> createState() => _ClimaCardState();
}

class _ClimaCardState extends State<ClimaCard> {
  final ClimaService _service = ClimaService();

  late Future<ClimaInfo> _consulta;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  void _atualizar() {
    _consulta = _service.consultar(
      latitude: widget.latitude,
      longitude: widget.longitude,
    );
  }

  @override
  void didUpdateWidget(covariant ClimaCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      setState(_atualizar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tempo no local da OS',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar previsão',
                  onPressed: () => setState(_atualizar),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<ClimaInfo>(
              future: _consulta,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text(
                    'Previsão indisponível no momento. '
                    'Você pode continuar o atendimento normalmente.',
                  );
                }

                final clima = snapshot.data!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${clima.simbolo} '
                      '${clima.temperatura.toStringAsFixed(1)} °C '
                      '— ${clima.descricao}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Umidade: ${clima.umidade}%'),
                    Text(
                      'Hoje: máxima '
                      '${clima.maxima.toStringAsFixed(0)} °C '
                      'e mínima '
                      '${clima.minima.toStringAsFixed(0)} °C',
                    ),
                    Text(
                      'Probabilidade máxima de chuva hoje: '
                      '${clima.probabilidadeChuva}%',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dados meteorológicos: Open-Meteo • CC BY 4.0',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

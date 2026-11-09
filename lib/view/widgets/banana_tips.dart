import 'dart:math';

import 'package:flutter/material.dart';

class BananaTips extends StatefulWidget {
  const BananaTips({super.key});

  @override
  State<BananaTips> createState() => _BananaTipsState();
}

class _BananaTipsState extends State<BananaTips> {
  static const List<String> _frases = [
    'Antes de culpar a API, confira se o Wi-Fi está ligado. 🍌',
    'Um commit por vez. Até gatos têm limites.',
    'Não existe bug, existe uma oportunidade de QA felino.',
    'Se compilou, comemore. Se funcionou, faça um commit!',
    'A pressa é inimiga do código. E do cochilo.',
    'Não apague o SQLite só porque ficou nervoso!',
    'Código limpo, caminha macia e sachê em dia.',
    'Uma OS resolvida vale mais que dez TODOs esquecidos.',
    'Se está offline, salve primeiro. Sincronize depois.',
    'Radlumzices não passam pela revisão da Lili.',
    'O Clayton tem oito braços. Você só precisa de um bom plantio.',
    'Toda grande Sprint merece uma pausa para um ronronar.',
  ];

  final Random _random = Random();
  late int _indice;

  @override
  void initState() {
    super.initState();
    _indice = _random.nextInt(_frases.length);
  }

  void _novaDica() {
    setState(() {
      // Evita repetir imediatamente a mesma frase.
      final deslocamento = 1 + _random.nextInt(_frases.length - 1);
      _indice = (_indice + deslocamento) % _frases.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Text('🍌', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BananaTips — Dica da bananeira',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(_frases[_indice]),
                ],
              ),
            ),
            IconButton(
              onPressed: _novaDica,
              tooltip: 'Outra BananaTip',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

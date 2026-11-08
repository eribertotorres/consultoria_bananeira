import 'package:flutter/foundation.dart';

import 'dart:async';

import '/data/models/chamado_model.dart';
import '/data/services/localizacao_service.dart';
import '/data/services/repositories/chamados_repository.dart';
import '/data/services/database_service.dart';

class ChamadosViewModel extends ChangeNotifier {
  final IChamadosRepository repository;

  final LocalizacaoService _localizacaoService = LocalizacaoService();

  ChamadosViewModel({
    required this.repository,
    Future<Set<int>> Function()? buscarIdsComAtendimento,
  }) : _buscarIdsComAtendimento =
           buscarIdsComAtendimento ??
           DatabaseService.instance.listarIdsComAtendimento;

  final Future<Set<int>> Function() _buscarIdsComAtendimento;

  bool _isLoading = false;
  bool _usandoDadosLocais = false;

  String? _errorMessage;

  List<ChamadoModel> _chamados = [];

  bool _ordenadoPorProximidade = false;

  final Map<int, double> _distanciasKm = {};

  // Estado da interface

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  bool get usandoDadosLocais => _usandoDadosLocais;

  bool get ordenadoPorProximidade => _ordenadoPorProximidade;

  double? distanciaDaOs(int chamadoId) => _distanciasKm[chamadoId];

  Set<int> _idsComAtendimento = {};
  // Listagem das ordens de serviço

  List<ChamadoModel> get chamadosOrdenados {
    final lista = _chamados
        .where((chamado) => !_idsComAtendimento.contains(chamado.id))
        .toList();

    if (!_ordenadoPorProximidade) {
      return lista;
    }

    lista.sort((a, b) {
      final distanciaA = _distanciasKm[a.id] ?? double.infinity;

      final distanciaB = _distanciasKm[b.id] ?? double.infinity;

      return distanciaA.compareTo(distanciaB);
    });

    return lista;
  }

  // Geolocalização

  Future<void> ordenarPorProximidade() async {
    final posicao = await _localizacaoService.obterPosicaoAtual();

    _distanciasKm.clear();

    for (final chamado in _chamados) {
      _distanciasKm[chamado.id] = _localizacaoService.calcularDistanciaKm(
        origemLatitude: posicao.latitude,
        origemLongitude: posicao.longitude,
        destinoLatitude: chamado.latitude,
        destinoLongitude: chamado.longitude,
      );
    }

    _ordenadoPorProximidade = true;
    notifyListeners();
  }

  void restaurarOrdemOriginal() {
    _ordenadoPorProximidade = false;
    notifyListeners();
  }

  // Consulta das ordens de serviço

  Future<void> carregarChamados() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _chamados = await repository.listarChamados().timeout(
        const Duration(seconds: 20),
      );
      _idsComAtendimento = await _buscarIdsComAtendimento();

      // Identifica se a última consulta utilizou o SQLite.
      _usandoDadosLocais = repository.usandoDadosLocais;

      // Descarta distâncias antigas após atualizar a lista.
      _distanciasKm.clear();
      _ordenadoPorProximidade = false;
    } on SessaoExpiradaException {
      _errorMessage = 'Sessão expirada. Faça login novamente.';
    } catch (e, stackTrace) {
      debugPrint('Erro ao carregar chamados: $e');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível carregar as ordens de serviço.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> atualizarAtendimentosLocais() async {
    _idsComAtendimento = await _buscarIdsComAtendimento();

    notifyListeners();
  }
}

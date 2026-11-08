import 'package:flutter_test/flutter_test.dart';

import 'package:projeto_os/data/models/chamado_model.dart';
import 'package:projeto_os/data/services/repositories/chamados_repository.dart';
import 'package:projeto_os/viewmodel/chamados_view_model.dart';

// Repositório simulado: não acessa a internet.
class FakeChamadosRepository implements IChamadosRepository {
  FakeChamadosRepository({
    this.usandoDadosLocais = false,
    this.lancarErro = false,
  });

  @override
  final bool usandoDadosLocais;

  final bool lancarErro;

  @override
  Future<List<ChamadoModel>> listarChamados() async {
    if (lancarErro) {
      throw Exception('Falha simulada');
    }

    return <ChamadoModel>[];
  }
}

void main() {
  group('ChamadosViewModel', () {
    test('Carrega chamados e encerra o loading', () async {
      final viewModel = ChamadosViewModel(
        repository: FakeChamadosRepository(),
        buscarIdsComAtendimento: () async => <int>{},
      );

      await viewModel.carregarChamados();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.chamadosOrdenados, isEmpty);
      expect(viewModel.usandoDadosLocais, isFalse);

      viewModel.dispose();
    });

    test('Identifica dados recuperados offline', () async {
      final viewModel = ChamadosViewModel(
        repository: FakeChamadosRepository(usandoDadosLocais: true),
        buscarIdsComAtendimento: () async => <int>{},
      );

      await viewModel.carregarChamados();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.usandoDadosLocais, isTrue);

      viewModel.dispose();
    });

    test('Trata falha do repositório sem travar', () async {
      final viewModel = ChamadosViewModel(
        repository: FakeChamadosRepository(lancarErro: true),
        buscarIdsComAtendimento: () async => <int>{},
      );

      await viewModel.carregarChamados();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNotNull);

      viewModel.dispose();
    });
  });
}

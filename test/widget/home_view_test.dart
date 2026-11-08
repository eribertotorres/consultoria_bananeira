import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:projeto_os/data/models/chamado_model.dart';
import 'package:projeto_os/data/services/repositories/chamados_repository.dart';
import 'package:projeto_os/view/home/home_view.dart';
import 'package:projeto_os/viewmodel/chamados_view_model.dart';

// Repositório simulado: não utiliza rede nem banco real.
class FakeChamadosRepository implements IChamadosRepository {
  FakeChamadosRepository({required this.usandoDadosLocais});

  @override
  final bool usandoDadosLocais;

  @override
  Future<List<ChamadoModel>> listarChamados() async {
    return <ChamadoModel>[];
  }
}

Future<void> montarHome(WidgetTester tester, {required bool offline}) async {
  final viewModel = ChamadosViewModel(
    repository: FakeChamadosRepository(usandoDadosLocais: offline),
    buscarIdsComAtendimento: () async => <int>{},
  );

  addTearDown(viewModel.dispose);

  await viewModel.carregarChamados();

  await tester.pumpWidget(
    ChangeNotifierProvider<ChamadosViewModel>.value(
      value: viewModel,
      child: const MaterialApp(home: HomeView()),
    ),
  );

  await tester.pump();
}

void main() {
  testWidgets('Home exibe as funcionalidades principais', (tester) async {
    await montarHome(tester, offline: false);

    expect(find.text('Ordens de Serviço'), findsOneWidget);

    expect(find.text('Histórico'), findsOneWidget);

    expect(find.text('Sincronização'), findsOneWidget);

    expect(find.text('Atualizar OS'), findsOneWidget);

    expect(find.text('Nenhuma ordem de serviço disponível.'), findsOneWidget);

    expect(find.textContaining('Modo offline'), findsNothing);
  });

  testWidgets('Home informa quando utiliza dados locais', (tester) async {
    await montarHome(tester, offline: true);

    expect(find.textContaining('Modo offline'), findsOneWidget);

    expect(find.textContaining('chamados salvos'), findsOneWidget);

    expect(find.text('Nenhuma ordem de serviço disponível.'), findsOneWidget);

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

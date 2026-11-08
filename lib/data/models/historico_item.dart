class HistoricoItem {
  final int chamadoId;
  final String codigoCliente;
  final String nomeCliente;
  final String categoria;
  final String procedimento;
  final String status;
  final String? fotoUrl;
  final String? dataResolucao;

  const HistoricoItem({
    required this.chamadoId,
    required this.codigoCliente,
    required this.nomeCliente,
    required this.categoria,
    required this.procedimento,
    required this.status,
    this.fotoUrl,
    this.dataResolucao,
  });

  factory HistoricoItem.fromApi(Map<String, dynamic> map) {
    final atendimento = map['atendimento'] as Map<String, dynamic>;

    return HistoricoItem(
      chamadoId: (map['chamado_id'] as num).toInt(),
      codigoCliente: (map['codigo_cliente'] ?? '').toString(),
      nomeCliente: (map['nome_cliente'] ?? '').toString(),
      categoria: (atendimento['categoria_tecnico'] ?? '').toString(),
      procedimento: (atendimento['descricao_procedimento'] ?? '').toString(),
      status: 'sincronizado',
      fotoUrl: atendimento['foto_url'] as String?,
      dataResolucao: atendimento['data_resolucao']?.toString(),
    );
  }

  factory HistoricoItem.fromLocal(Map<String, Object?> map) {
    return HistoricoItem(
      chamadoId: map['chamado_id'] as int,
      codigoCliente: '',
      nomeCliente: '',
      categoria: map['categoria_tecnico'] as String,
      procedimento: map['descricao_procedimento'] as String,
      status: map['status'] as String,
      dataResolucao: map['data_resolucao']?.toString(),
    );
  }
}

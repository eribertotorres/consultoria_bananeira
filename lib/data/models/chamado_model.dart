class ChamadoModel {
  final int id;
  final String codigoCliente;
  final String nomeCliente;
  final String categoriaInformada;
  final String descricaoProblema;
  final String enderecoCliente;
  final String bairro;
  final String cidade;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime criadoEm;

  const ChamadoModel({
    required this.id,
    required this.codigoCliente,
    required this.nomeCliente,
    required this.categoriaInformada,
    required this.descricaoProblema,
    required this.enderecoCliente,
    required this.bairro,
    required this.cidade,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.criadoEm,
  });

  factory ChamadoModel.fromMap(Map<String, dynamic> map) {
    return ChamadoModel(
      id: map['id'] as int,
      codigoCliente: map['codigo_cliente'] as String,
      nomeCliente: map['nome_cliente'] as String,
      categoriaInformada: map['categoria_informada'] as String,
      descricaoProblema: map['descricao_problema'] as String,
      enderecoCliente: map['endereco_cliente'] as String,
      bairro: map['bairro'] as String,
      cidade: map['cidade'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      status: map['status'] as String,
      criadoEm: DateTime.parse(
        (map['criado_em'] as String).replaceFirst(' ', 'T'),
      ),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo_cliente': codigoCliente,
      'nome_cliente': nomeCliente,
      'categoria_informada': categoriaInformada,
      'descricao_problema': descricaoProblema,
      'endereco_cliente': enderecoCliente,
      'bairro': bairro,
      'cidade': cidade,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'criado_em': criadoEm.toIso8601String(),
    };
  }
}

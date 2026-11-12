class MotdMessage {
  final String id;
  final String titulo;
  final String mensagem;
  final bool ativo;
  final DateTime? inicio;
  final DateTime? fim;

  const MotdMessage({
    required this.id,
    required this.titulo,
    required this.mensagem,
    this.ativo = true,
    this.inicio,
    this.fim,
  });
  factory MotdMessage.fromMap(Map<String, dynamic> map) {
    DateTime? lerData(String campo) {
      final valor = map[campo];

      if (valor == null) return null;

      if (valor is! String || !valor.endsWith('Z')) {
        throw FormatException('Data inválida no campo $campo.');
      }

      return DateTime.parse(valor).toUtc();
    }

    final id = map['id'];
    final titulo = map['titulo'];
    final mensagem = map['mensagem'];
    final ativo = map['ativo'];

    if (id is! String ||
        id.isEmpty ||
        titulo is! String ||
        titulo.trim().isEmpty ||
        mensagem is! String ||
        mensagem.trim().isEmpty ||
        ativo is! bool) {
      throw const FormatException('Comunicado inválido.');
    }

    final inicio = lerData('inicio');
    final fim = lerData('fim');

    if (inicio != null && fim != null && !fim.isAfter(inicio)) {
      throw const FormatException('Período do comunicado inválido.');
    }

    return MotdMessage(
      id: id,
      titulo: titulo,
      mensagem: mensagem,
      ativo: ativo,
      inicio: inicio,
      fim: fim,
    );
  }

  bool get estaVigente {
    final agora = DateTime.now();

    if (!ativo) return false;
    if (inicio != null && agora.isBefore(inicio!)) {
      return false;
    }
    if (fim != null && !agora.isBefore(fim!)) {
      return false;
    }

    return true;
  }
}

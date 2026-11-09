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

  bool get estaVigente {
    final agora = DateTime.now();

    if (!ativo) return false;
    if (inicio != null && agora.isBefore(inicio!)) {
      return false;
    }
    if (fim != null && agora.isAfter(fim!)) {
      return false;
    }

    return true;
  }
}

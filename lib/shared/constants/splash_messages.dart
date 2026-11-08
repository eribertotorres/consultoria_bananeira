import 'dart:math';

class SplashMessages {
  static const List<String> mensagens = [
    'Invocando OS com supervisão felina...',
    'Lili está conferindo os chamados...',
    'Preparando as ferramentas do técnico...',
    'Verificando se Radlum mexeu no banco...',
    'Clayton está preparando sua missão...',
    'Consultando a supervisora de QA...',
  ];

  static String mensagemAleatoria() {
    final indice = Random().nextInt(mensagens.length);
    return mensagens[indice];
  }
}

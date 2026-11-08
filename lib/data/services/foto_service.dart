import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class FotoService {
  final ImagePicker _picker = ImagePicker();

  static const int tamanhoMaximo = 5 * 1024 * 1024;

  Future<String?> selecionarFoto({
    required int chamadoId,
    required ImageSource origem,
  }) async {
    final imagem = await _picker.pickImage(
      source: origem,
      imageQuality: 70,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (imagem == null) return null;

    final arquivoTemporario = File(imagem.path);
    final tamanho = await arquivoTemporario.length();

    if (tamanho > tamanhoMaximo) {
      throw Exception('A imagem ultrapassa o limite de 5 MB.');
    }

    final documentos = await getApplicationDocumentsDirectory();

    final pasta = Directory('${documentos.path}/fotos_atendimentos');
    await pasta.create(recursive: true);

    final extensao = imagem.path.split('.').last.toLowerCase();
    final extensaoSegura = ['jpg', 'jpeg', 'png'].contains(extensao)
        ? extensao
        : 'jpg';

    final nome =
        'os_${chamadoId}_${DateTime.now().microsecondsSinceEpoch}'
        '.$extensaoSegura';

    final destino = File('${pasta.path}/$nome');

    await arquivoTemporario.copy(destino.path);

    return destino.path;
  }
}

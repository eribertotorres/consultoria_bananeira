import 'package:geolocator/geolocator.dart';

class LocalizacaoService {
  Future<Position> obterPosicaoAtual() async {
    final habilitado = await Geolocator.isLocationServiceEnabled();

    if (!habilitado) {
      throw Exception(
        'Ative a localização do dispositivo para ordenar '
        'as OS por proximidade.',
      );
    }

    var permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }

    if (permissao == LocationPermission.denied) {
      throw Exception('Permissão de localização não concedida.');
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'Permissão de localização bloqueada. '
        'Altere nas configurações do aplicativo.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  double calcularDistanciaKm({
    required double origemLatitude,
    required double origemLongitude,
    required double destinoLatitude,
    required double destinoLongitude,
  }) {
    final metros = Geolocator.distanceBetween(
      origemLatitude,
      origemLongitude,
      destinoLatitude,
      destinoLongitude,
    );

    return metros / 1000;
  }
}

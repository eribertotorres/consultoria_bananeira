import 'dart:convert';

import 'package:http/http.dart' as http;

class ClimaInfo {
  final double temperatura;
  final int umidade;
  final int codigoTempo;
  final double maxima;
  final double minima;
  final int probabilidadeChuva;

  const ClimaInfo({
    required this.temperatura,
    required this.umidade,
    required this.codigoTempo,
    required this.maxima,
    required this.minima,
    required this.probabilidadeChuva,
  });

  String get descricao {
    switch (codigoTempo) {
      case 0:
        return 'Céu limpo';
      case 1:
      case 2:
        return 'Parcialmente nublado';
      case 3:
        return 'Nublado';
      case 45:
      case 48:
        return 'Nevoeiro';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return 'Garoa';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return 'Chuva';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 'Neve';
      case 95:
        return 'Trovoadas';

      case 96:
        return 'Trovoadas com granizo';

      case 97:
        return 'Trovoadas fortes';

      case 99:
        return 'Trovoadas fortes com granizo';

      default:
        return 'Condição não identificada';
    }
  }

  String get simbolo {
    if (codigoTempo == 0) return '☀️';
    if (codigoTempo <= 3) return '⛅';
    if (codigoTempo == 45 || codigoTempo == 48) return '🌫️';
    if (codigoTempo >= 95) return '⛈️';
    if (codigoTempo >= 71 && codigoTempo <= 77) return '❄️';
    if (codigoTempo == 85 || codigoTempo == 86) return '❄️';
    return '🌧️';
  }
}

class ClimaService {
  Future<ClimaInfo> consultar({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'temperature_2m,relative_humidity_2m,weather_code',
      'daily':
          'temperature_2m_max,temperature_2m_min,'
          'precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '1',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception(
        'Serviço meteorológico indisponível: '
        'HTTP ${response.statusCode}',
      );
    }

    final corpo = jsonDecode(response.body) as Map<String, dynamic>;

    final atual = corpo['current'] as Map<String, dynamic>;
    final diario = corpo['daily'] as Map<String, dynamic>;

    return ClimaInfo(
      temperatura: (atual['temperature_2m'] as num).toDouble(),
      umidade: (atual['relative_humidity_2m'] as num).toInt(),
      codigoTempo: (atual['weather_code'] as num).toInt(),
      maxima: (diario['temperature_2m_max'] as List).first.toDouble(),
      minima: (diario['temperature_2m_min'] as List).first.toDouble(),
      probabilidadeChuva: (diario['precipitation_probability_max'] as List)
          .first
          .toInt(),
    );
  }
}

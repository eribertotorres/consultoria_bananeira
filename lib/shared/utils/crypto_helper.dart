import 'dart:convert';

import 'package:crypto/crypto.dart';

class CryptoHelper {
  static const String _secretKey = r'ISP_TECH_SENAI_2026_xK9#mQ2$vL8!zP4';

  static String gerarHmacSha256(String senha) {
    final keyBytes = utf8.encode(_secretKey);
    final senhaBytes = utf8.encode(senha);

    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(senhaBytes);

    return digest.toString();
  }
}

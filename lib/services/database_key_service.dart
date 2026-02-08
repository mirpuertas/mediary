import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseKeyService {
  static const _secure = FlutterSecureStorage();

  static const String _kDbKey = 'db_encryption_key_v1';

  Future<String> getOrCreateKey() async {
    final existing = await _secure.read(key: _kDbKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final bytes = _randomBytes(32);
    final key = base64UrlEncode(bytes);
    await _secure.write(key: _kDbKey, value: key);
    return key;
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}

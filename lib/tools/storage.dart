import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> logIn(String id, {String? password}) async {
    await _storage.write(key: "id", value: id);
    if (password != null) {
      await _storage.write(key: "password", value: password);
    }
    await _storage.write(key: "isLogged", value: "true");
  }

  Future<String?> getId() async {
    return await _storage.read(key: "id");
  }

  Future<String?> getPassword() async {
    return await _storage.read(key: "password");
  }

  Future<bool> isLogged() async {
    return await _storage.read(key: "isLogged") == "true";
  }

  Future<void> logOut() async {
    await _storage.write(key: "isLogged", value: "false");
    await _storage.delete(key: "id");
    await _storage.delete(key: "password");
  }
}

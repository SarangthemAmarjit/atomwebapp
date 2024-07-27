import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:pointycastle/pointycastle.dart' as pointycastle;
import 'package:pointycastle/export.dart' as pc;

class AtomAES {
  AtomAES() {
    const passphrase = '83D1E1EC3DEE483BB698935F9B312A82';
    const salt = '83D1E1EC3DEE483BB698935F9B312A82';
    final iv = Uint8List.fromList(
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
    const iterations = 65536;
    const keySize = 256;
    const plaintext = 'ABC123';

    final encrypted = encryptText(plaintext, passphrase, salt, iv, iterations);
    final decrypted = decryptText(encrypted, passphrase, salt, iv, iterations);

    print('Encrypted: $encrypted');
    print('Decrypted: $decrypted');
  }

  String encryptText(String plainText, String passphrase, String salt,
      Uint8List iv, int iterations) {
    final plainBytes = utf8.encode(plainText);
    final key = getSymmetricKey(passphrase, salt, iv, iterations);
    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    final encrypted = encrypter.encryptBytes(plainBytes, iv: encrypt.IV(iv));
    return encrypted.base16.toUpperCase();
  }

  String decryptText(String encryptedText, String passphrase, String salt,
      Uint8List iv, int iterations) {
    final encryptedBytes = hexToBytes(encryptedText);
    final key = getSymmetricKey(passphrase, salt, iv, iterations);
    final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'));
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes),
        iv: encrypt.IV(iv));
    return utf8.decode(decrypted);
  }

  encrypt.Key getSymmetricKey(
      String passphrase, String salt, Uint8List iv, int iterations) {
    final keyBytes = pbkdf2(
      passphrase: utf8.encode(passphrase),
      salt: utf8.encode(salt),
      iterations: iterations,
      keyLength: 32,
    );
    return encrypt.Key(Uint8List.fromList(keyBytes));
  }

  Uint8List pbkdf2({
    required List<int> passphrase,
    required List<int> salt,
    required int iterations,
    required int keyLength,
  }) {
    final keyDerivator = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA1Digest(), 64))
      ..init(
          pc.Pbkdf2Parameters(Uint8List.fromList(salt), iterations, keyLength));
    return keyDerivator.process(Uint8List.fromList(passphrase));
  }

  Uint8List hexToBytes(String hex) {
    final length = hex.length;
    final bytes = Uint8List(length ~/ 2);
    for (var i = 0; i < length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }
}

void main() {
  AtomAES();
}

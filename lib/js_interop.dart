// lib/js_interop.dart
@JS()
library js_interop;

import 'dart:async';
import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS('getAtomEncryption')
external Object _getAtomEncryption(String plainText, String password);

@JS('getAtomDecryption')
external Object _getAtomDecryption(String encryptedText, String password);

Future<String> getAtomEncryption(String plainText, String password) {
  final result = _getAtomEncryption(plainText, password);
  return promiseToFuture(result);
}

Future<String> getAtomDecryption(String encryptedText, String password) {
  final result = _getAtomDecryption(encryptedText, password);
  return promiseToFuture(result);
}

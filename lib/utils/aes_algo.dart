import 'dart:io';

import 'package:encrypt/encrypt.dart' as share_crypt;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

final iv = share_crypt.IV.fromLength(16);

Future<void> triggerEncrypt(
    String _path, String fileName,share_crypt.Key key) async {
  var _file = File(_path);
  var bits8 = await _file.readAsBytes(); //8bits
  // var input = bits8.buffer.asUint16List(); // 128bits

  // Compute
  var map = {"bytes": bits8, "key": key, "iv": iv};
  var encryption = await compute(encrypt, map);

  // Save
  var dir = await getExternalStorageDirectory();
  var extension = _path.split(".").last;

  var toSave = File("${dir?.path}/$fileName.$extension");
  await toSave.writeAsBytes(encryption.bytes);
}

Future<void> triggerDecrypt(
    String _path, share_crypt.Key key) async {
  var dir = await getExternalStorageDirectory();

  var extension = _path.split(".").last;
  var file = File("${dir?.path}/encrypt.$extension");
  var input = await file.readAsBytes();
  var enc = share_crypt.Encrypted(input);

  // Compute=
  var map = {"encrypted": enc, "key": key, "iv": iv};
  var decryption = await compute(decrypt, map);

  //Save
  var toSave = File("${dir?.path}/decrypt.$extension");
  await toSave.writeAsBytes(decryption);
}

// void encryptKey() {
//   if (_publicKey != null) {
//     setState(() {
//       _encryptedKey = rsaEncrypt(_publicKey!, key.bytes);
//     });
//     print("Encrypted Key : ${base64Encode(_encryptedKey!)}");
//   }
// }
//
// void decryptKey() {
//   if (_privateKey != null && _encryptedKey != null) {
//     var res = rsaDecrypt(_privateKey!, _encryptedKey!);
//     print("Decrypted Key : ${base64Encode(res)}");
//   }
// }

Future<share_crypt.Encrypted> encrypt(Map map) async {
  // Encryption
  var encryptor = share_crypt.Encrypter(share_crypt.AES(map['key']));
  var encryption = encryptor.encryptBytes(map['bytes'], iv: map['iv']);
  return encryption;
}

Future<List<int>> decrypt(Map map) async {
  // Decryption
  final encryptor = share_crypt.Encrypter(share_crypt.AES(map['key']));
  final decryption = encryptor.decryptBytes(map['encrypted'], iv: map['iv']);
  return decryption;
}

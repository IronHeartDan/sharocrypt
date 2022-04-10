import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';

// Needed By Key Generation Method
SecureRandom getSecureRandom() {
  var secureRandom = FortunaRandom();
  var random = Random.secure();
  List<int> seeds = [];
  for (int i = 0; i < 32; i++) {
    seeds.add(random.nextInt(255));
  }
  secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
  return secureRandom;
}

// Computing In Kind Of Background
Future<AsymmetricKeyPair<PublicKey, PrivateKey>> computeRSAKeyPair(
    SecureRandom secureRandom) async {
  return await compute(getRsaKeyPair, secureRandom);
}

// Actual Generation Of Pair
AsymmetricKeyPair<PublicKey, PrivateKey> getRsaKeyPair(
    SecureRandom secureRandom) {
  var rsaPair = RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 5);
  var params = ParametersWithRandom(rsaPair, secureRandom);
  var keyGenerator = RSAKeyGenerator();
  keyGenerator.init(params);
  return keyGenerator.generateKeyPair();
}

// Convert PublicKey To Pem
// String encodePublicKeyToPemPKCS1(RSAPublicKey publicKey) {
//   var topLevel = ASN1Sequence();
//
//   topLevel.add(ASN1Integer(publicKey.modulus));
//   topLevel.add(ASN1Integer(publicKey.exponent));
//
//   var dataBase64 = base64.encode(topLevel.encodedBytes);
//   return """-----BEGIN PUBLIC KEY-----\r\n$dataBase64\r\n-----END PUBLIC KEY-----""";
// }


// Encryption And Decryption
Uint8List rsaEncrypt(RSAPublicKey myPublic, Uint8List dataToEncrypt) {
  final encryptor = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(myPublic)); // true=encrypt

  return _processInBlocks(encryptor, dataToEncrypt);
}

Uint8List rsaDecrypt(RSAPrivateKey myPrivate, Uint8List cipherText) {
  final decryptor = OAEPEncoding(RSAEngine())
    ..init(false, PrivateKeyParameter<RSAPrivateKey>(myPrivate)); // false=decrypt

  return _processInBlocks(decryptor, cipherText);
}

Uint8List _processInBlocks(AsymmetricBlockCipher engine, Uint8List input) {
  final numBlocks = input.length ~/ engine.inputBlockSize +
      ((input.length % engine.inputBlockSize != 0) ? 1 : 0);

  final output = Uint8List(numBlocks * engine.outputBlockSize);

  var inputOffset = 0;
  var outputOffset = 0;
  while (inputOffset < input.length) {
    final chunkSize = (inputOffset + engine.inputBlockSize <= input.length)
        ? engine.inputBlockSize
        : input.length - inputOffset;

    outputOffset += engine.processBlock(
        input, inputOffset, chunkSize, output, outputOffset);

    inputOffset += chunkSize;
  }

  return (output.length == outputOffset)
      ? output
      : output.sublist(0, outputOffset);
}

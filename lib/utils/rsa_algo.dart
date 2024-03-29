import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/pointycastle.dart';
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
String encodePublicKeyToPemPKCS1(RSAPublicKey publicKey) {
  var topLevel = ASN1Sequence();
  var modulus = ASN1Integer(publicKey.modulus);
  var exponent = ASN1Integer(publicKey.exponent);

  topLevel.add(modulus);
  topLevel.add(exponent);

  var bytes = topLevel.encode();

  var dataBase64 = base64Encode(bytes);
  return """-----BEGIN PUBLIC KEY-----\r\n$dataBase64\r\n-----END PUBLIC KEY-----""";
}

// Convert PrivateKey To Pem
String encodePrivateKeyToPemPKCS1(RSAPrivateKey privateKey) {
  var topLevel = ASN1Sequence();

  var version = ASN1Integer(BigInt.from(0));
  var modulus = ASN1Integer(privateKey.n);
  var publicExponent = ASN1Integer(privateKey.exponent);
  var privateExponent = ASN1Integer(privateKey.privateExponent);
  var p = ASN1Integer(privateKey.p);
  var q = ASN1Integer(privateKey.q);
  var dP = privateKey.privateExponent! % (privateKey.p! - BigInt.from(1));
  var exp1 = ASN1Integer(dP);
  var dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.from(1));
  var exp2 = ASN1Integer(dQ);
  var iQ = privateKey.q!.modInverse(privateKey.p!);
  var co = ASN1Integer(iQ);

  topLevel.add(version);
  topLevel.add(modulus);
  topLevel.add(publicExponent);
  topLevel.add(privateExponent);
  topLevel.add(p);
  topLevel.add(q);
  topLevel.add(exp1);
  topLevel.add(exp2);
  topLevel.add(co);

  var dataBase64 = base64.encode(topLevel.encode());
  return """-----BEGIN PRIVATE KEY-----\r\n$dataBase64\r\n-----END PRIVATE KEY-----""";
}

// Encryption And Decryption
Uint8List rsaEncrypt(RSAPublicKey myPublic, Uint8List dataToEncrypt) {
  final encryptor = OAEPEncoding(RSAEngine())
    ..init(true, PublicKeyParameter<RSAPublicKey>(myPublic)); // true=encrypt

  return _processInBlocks(encryptor, dataToEncrypt);
}

Uint8List rsaDecrypt(RSAPrivateKey myPrivate, Uint8List cipherText) {
  final decryptor = OAEPEncoding(RSAEngine())
    ..init(
        false, PrivateKeyParameter<RSAPrivateKey>(myPrivate)); // false=decrypt

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

Future<void> manageRSA() async {
  var keystore = const FlutterSecureStorage();
  var pair = await computeRSAKeyPair(getSecureRandom());
  var rsaPublicKey = pair.publicKey as RSAPublicKey;
  var rsaPrivateKey = pair.privateKey as RSAPrivateKey;
  var publicKey = encodePublicKeyToPemPKCS1(rsaPublicKey);
  var privateKey = encodePrivateKeyToPemPKCS1(rsaPrivateKey);
  keystore.write(key: "privateKey", value: privateKey);
  var user = FirebaseAuth.instance.currentUser;
  var ref =
  FirebaseFirestore.instance.collection("users").doc(user?.phoneNumber);
  var data = {"publicKey": publicKey};
  var check = await ref.get();
  if (check.exists) {
    await ref.update(data);
  } else {
    await ref.set(data);
  }
}

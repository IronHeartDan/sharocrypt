import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as share_crypt;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:sharocrypt/screens/generated_qr.dart';
import 'package:sharocrypt/screens/scan_qr.dart';

import '../utils/rsa_algo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _path;
  final TextEditingController _controller = TextEditingController();

  share_crypt.Key key = share_crypt.Key.fromSecureRandom(32);
  final iv = share_crypt.IV.fromLength(16);

  RSAPrivateKey? _privateKey;
  RSAPublicKey? _publicKey;

  Uint8List? _encryptedKey;

  void generateRsaPair() async {
    var pair = await computeRSAKeyPair(getSecureRandom());
    _privateKey = pair.privateKey as RSAPrivateKey;
    _publicKey = pair.publicKey as RSAPublicKey;
  }

  void _generateKey() async {
    setState(() {
      key = share_crypt.Key.fromSecureRandom(32);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
            HexColor("#30cfd0"),
            HexColor("#330867"),
          ])),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              width: 300,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.white, onPrimary: Colors.black),
                child: const Text("Select File"),
                onPressed: () async {
                  var checkPermission = await Permission.storage.status;

                  if (checkPermission.isPermanentlyDenied) {
                    FlutterToast(context)
                        .showToast(child: Text(checkPermission.toString()));
                    return;
                  }

                  if (checkPermission.isDenied) {
                    var res = await Permission.storage.request();
                    if (res.isDenied || res.isPermanentlyDenied) {
                      return;
                    }
                  }

                  FlutterToast(context)
                      .showToast(child: Text(checkPermission.toString()));

                  var res = await FilePicker.platform.pickFiles();

                  FlutterToast(context)
                      .showToast(child: Text("Path :: ${res?.paths[0]}"));
                  setState(() {
                    _path = res?.paths[0];
                  });
                  var extension = _path?.split(".").last;
                  print(extension);
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.white, onPrimary: Colors.black),
                child: const Text("Add Custom Key"),
                onPressed: () async {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("Enter Secret Key"),
                          content: TextFormField(
                            controller: _controller,
                            decoration: const InputDecoration(
                                label: Text("Type Here"),
                                border: OutlineInputBorder()),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text("Cancel")),
                            TextButton(
                                onPressed: () {
                                  setState(() {
                                    var inputValue = _controller.value.text;
                                    if (inputValue.isEmpty ||
                                        inputValue.length != 16) {
                                      Navigator.of(context).pop();
                                      FlutterToast(context).showToast(
                                          child: const Text(
                                              "16 Characters Required For 128bit Key"));
                                      return;
                                    }
                                    key = share_crypt.Key.fromUtf8(inputValue);
                                    Navigator.of(context).pop();
                                  });
                                },
                                child: const Text("Use"))
                          ],
                        );
                      });
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 45,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.white, onPrimary: Colors.black),
                  onPressed: () {
                    _generateKey();
                  },
                  child: const Text("Auto Generate Key")),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 45,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.white, onPrimary: Colors.black),
                  onPressed: () async {
                    if (_path == null) {
                      FlutterToast(context)
                          .showToast(child: const Text("Please Select File"));
                      return;
                    }
                    triggerEncrypt();
                  },
                  child: const Text("Encrypt File")),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 45,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.white, onPrimary: Colors.black),
                  onPressed: () {
                    triggerDecrypt();
                  },
                  child: const Text("Decrypt File")),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 45,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.white, onPrimary: Colors.black),
                  onPressed: () {
                    generateRsaPair();
                  },
                  child: const Text("Generate Key Pair")),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 45,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.white, onPrimary: Colors.black),
                  onPressed: () {
                    encryptKey();
                  },
                  child: const Text("Encrypt Secret Key")),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 45,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.white, onPrimary: Colors.black),
                  onPressed: () {
                    decryptKey();
                  },
                  child: const Text("Decrypt Secret Key")),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 45,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.white, onPrimary: Colors.black),
                  onPressed: () {
                    if (_encryptedKey != null) {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              GeneratedQr(encryptedKey: _encryptedKey!)));
                    }
                  },
                  child: const Text("Generate QR")),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: 300,
              height: 45,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.white, onPrimary: Colors.black),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const ScanQr()));
                  },
                  child: const Text("Scan QR")),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> triggerEncrypt() async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Encrypting File")));

    var _file = File(_path!);
    var bits8 = await _file.readAsBytes(); //8bits
    // var input = bits8.buffer.asUint16List(); // 128bits

    // Compute
    var map = {"bytes": bits8, "key": key, "iv": iv};
    var encryption = await compute(encrypt, map);

    // Save
    var dir = await getExternalStorageDirectory();
    var extension = _path!.split(".").last;

    var toSave = File("${dir?.path}/encrypt.$extension");
    await toSave.writeAsBytes(encryption.bytes);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Encryption Finished")));
  }

  Future<void> triggerDecrypt() async {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Decryption Started")));

    var dir = await getExternalStorageDirectory();

    var extension = _path!.split(".").last;
    var file = File("${dir?.path}/encrypt.$extension");
    var input = await file.readAsBytes();
    var enc = share_crypt.Encrypted(input);

    // Compute=
    var map = {"encrypted": enc, "key": key, "iv": iv};
    var decryption = await compute(decrypt, map);

    //Save
    var toSave = File("${dir?.path}/decrypt.$extension");
    await toSave.writeAsBytes(decryption);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Decryption Finished")));
  }

  void encryptKey() {
    if (_publicKey != null) {
      setState(() {
        _encryptedKey = rsaEncrypt(_publicKey!, key.bytes);
      });
      print("Encrypted Key : ${base64Encode(_encryptedKey!)}");
    }
  }

  void decryptKey() {
    if (_privateKey != null && _encryptedKey != null) {
      var res = rsaDecrypt(_privateKey!, _encryptedKey!);
      print("Decrypted Key : ${base64Encode(res)}");
    }
  }
}

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

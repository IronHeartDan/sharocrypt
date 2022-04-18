import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:encrypt/encrypt.dart' as share_crypt;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sharocrypt/screens/search_screen.dart';

import '../utils/rsa_algo.dart';

class TextEncryption extends StatefulWidget {
  const TextEncryption({Key? key}) : super(key: key);

  @override
  State<TextEncryption> createState() => _TextEncryptionState();
}

class _TextEncryptionState extends State<TextEncryption> {
  final _plainTextController = TextEditingController();
  final _keyEditingController = TextEditingController();

  bool isReady = false;

  share_crypt.Key key = share_crypt.Key.fromSecureRandom(32);
  final iv = share_crypt.IV.fromLength(16);

  share_crypt.Encrypted? _currentEncryption;

  bool _processing = false;
  RSAPublicKey? receiverPublicKey;

  @override
  void initState() {
    super.initState();
    _keyEditingController.text = key.base64;
  }

  void _generateRandomKey() {
    setState(() {
      key = share_crypt.Key.fromSecureRandom(32);
      _keyEditingController.text = key.base64;
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        if (_processing) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Processing Encryption"),
                  content: const Text(
                      "Encryption under process please wait on the screen"),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("OK"))
                  ],
                );
              });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10.0),
            width: size.width,
            child: Column(
              children: [
                const SizedBox(
                  width: double.infinity,
                  child: Text(
                    "Text Encryption",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                TextFormField(
                  controller: _plainTextController,
                  decoration: const InputDecoration(
                      label: Text("Enter Plain Text"),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)))),
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _keyEditingController,
                  decoration: const InputDecoration(
                      helperText: "Key Is Of 32 Characters (128bit)",
                      label: Text("Key"),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)))),
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              primary: Colors.grey,
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)))),
                          onPressed: () {
                            _generateRandomKey();
                          },
                          child: const Text("Random")),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              primary: Colors.grey,
                              shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)))),
                          onPressed: () {
                            _keyEditingController.clear();
                          },
                          child: const Text("Clear")),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            primary: HexColor("#3A3843"),
                            onPrimary: Colors.white),
                        onPressed: () {
                          if (!_processing) {
                            handleEncryption();
                          }
                        },
                        child: _processing
                            ? const CircularProgressIndicator()
                            : const Text("Encrypt"))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void handleEncryption() async {
    if (_plainTextController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please Enter Plain Text")));
      return;
    }

    receiverPublicKey = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const SearchScreen()));

    if (receiverPublicKey != null) {
      setState(() {
        _processing = true;
      });
      var info = ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Encrypting Plain Text"),
        duration: Duration(days: 365),
        dismissDirection: DismissDirection.none,
      ));
      await triggerEncrypt();
      var encryptedKey = encryptKey();
      generateQR(encryptedKey);
      info.close();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Encryption Finished")));
      setState(() {
        _processing = false;
      });
    }
  }

  Future<void> triggerEncrypt() async {
    // Compute
    var map = {"plainText": _plainTextController.text, "key": key, "iv": iv};
    var encryption = await compute(encryptFile, map);
    setState(() {
      _currentEncryption = encryption;
    });
  }

  void handleDismiss() {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    setState(() {
      _plainTextController.clear();
      isReady = false;
      _currentEncryption = null;
      receiverPublicKey = null;
      _generateRandomKey();
    });
  }

  String encryptKey() {
    var encryptedKey = rsaEncrypt(receiverPublicKey!, key.bytes);
    return base64Encode(encryptedKey);
  }

  void generateQR(String encryptedKey) async {
    var data = jsonEncode({"TYPE": 0, "KEY": encryptedKey, "IV": iv.base64});
    var qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    await showModalBottomSheet(
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
        context: context,
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              if (receiverPublicKey == null) {
                return true;
              }
              await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Dismiss ?"),
                      content: const Text(
                          "Please Share The QR or else Dismissing Will Rest Current Progress"),
                      actions: [
                        TextButton(
                            onPressed: () async {
                              handleDismiss();
                            },
                            child: const Text(
                              "Already Scanned!",
                              style: TextStyle(color: Colors.blue),
                            )),
                        TextButton(
                            onPressed: () async {
                              handleDismiss();
                            },
                            child: const Text(
                              "Dismiss",
                              style: TextStyle(color: Colors.red),
                            )),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Ok")),
                      ],
                    );
                  });

              return false;
            },
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    const Text(
                      "QR-Code",
                      style: TextStyle(
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Divider(
                      thickness: 2,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    QrImage(
                      data: data,
                      size: 250,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Divider(
                      thickness: 2,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      readOnly: true,
                      initialValue: _currentEncryption?.base64,
                      decoration: const InputDecoration(
                          // errorText:
                          // hasError ? "At Least One Check Required !" : null,
                          label: Text("Cipher Text"),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)))),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    primary: HexColor("#3A3843"),
                                    onPrimary: Colors.white),
                                onPressed: () async {
                                  if (qrValidationResult.status ==
                                      QrValidationStatus.valid) {
                                    var qrCode = qrValidationResult.qrCode;

                                    var painter = QrPainter.withQr(
                                      qr: qrCode!,
                                      color: const Color(0xFF000000),
                                      emptyColor: Colors.white,
                                      gapless: true,
                                      embeddedImageStyle: null,
                                      embeddedImage: null,
                                    );

                                    Directory tempDir =
                                        await getTemporaryDirectory();
                                    String tempPath = tempDir.path;
                                    final ts = DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString();
                                    String path = '$tempPath/$ts.png';

                                    final picData = await painter.toImageData(
                                        1024,
                                        format: ImageByteFormat.png);

                                    await writeToFile(picData!, path);

                                    Share.shareFiles([path], text: 'Share QR');
                                  }
                                },
                                child: const Text("Share")),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10))),
                                    primary: HexColor("#3A3843"),
                                    onPrimary: Colors.white),
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(
                                      text: _currentEncryption?.base64));
                                  FlutterToast(context).showToast(
                                      child: const Text("Copied To Clipboard"));
                                },
                                child: const Text("Copy")),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        });
  }

  Future<void> writeToFile(ByteData data, String path) async {
    final buffer = data.buffer;
    await File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }
}

Future<share_crypt.Encrypted> encryptFile(Map map) async {
  // Encryption
  var encryptor = share_crypt.Encrypter(share_crypt.AES(map['key']));
  var encryption = encryptor.encrypt(map['plainText'], iv: map['iv']);
  return encryption;
}

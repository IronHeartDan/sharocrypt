import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:encrypt/encrypt.dart' as share_crypt;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sharocrypt/utils/rsa_algo.dart';

class ScanQr extends StatefulWidget {
  const ScanQr({Key? key}) : super(key: key);

  @override
  State<ScanQr> createState() => _ScanQrState();
}

class _ScanQrState extends State<ScanQr> {
  final GlobalKey _qrKey = GlobalKey();

  Barcode? result;
  QRViewController? controller;
  Uint8List? encryptedFile;
  Reference? _reference;
  bool _isDownloading = false;
  bool _isDecrypting = false;
  var keystore = const FlutterSecureStorage();

  final _cipherTextController = TextEditingController();
  final _outputController = TextEditingController();

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  void initState() {
    super.initState();
    checkPermission();
  }

  void checkPermission() async {
    var status = await Permission.camera.status;
    print("CAMERA PERMISSION ${status}");
    if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Camera Permission Permanently Denied")));
      Navigator.of(context).pop();
      return;
    }
    if (status.isDenied) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Camera Permission Denied")));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 250.0
        : 300.0;

    if (result != null) {
      var qrData = jsonDecode(result!.code!);
      print("QR TYPE ${qrData['TYPE']}");
      if (qrData["TYPE"] == 0) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: const Text(
              "Found QR",
              style: TextStyle(color: Colors.black),
            ),
          ),
          body: Container(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                QrImage(
                  data: result!.code!,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(
                  height: 20,
                ),
                TextFormField(
                  controller: _cipherTextController,
                  decoration: const InputDecoration(
                      label: Text("Enter Cipher Text"),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)))),
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
                        onPressed: () async {
                          if (_cipherTextController.text.isNotEmpty) {
                            var info = ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Row(
                                children: const [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text("Decrypting"),
                                ],
                              ),
                              duration: const Duration(days: 365),
                              behavior: SnackBarBehavior.fixed,
                              dismissDirection: DismissDirection.none,
                            ));

                            var encryptedKey = qrData["KEY"];
                            var base64IV = qrData["IV"];
                            var privateKey =
                                await keystore.read(key: "privateKey");
                            var rsaPrivateKey =
                                CryptoUtils.rsaPrivateKeyFromPemPkcs1(
                                    privateKey!);

                            var keyBuffer = rsaDecrypt(
                                rsaPrivateKey,
                                base64Decode(encryptedKey)
                                    .buffer
                                    .asUint8List());

                            var key = share_crypt.Key.fromBase64(
                                base64Encode(keyBuffer));
                            var iv = share_crypt.IV.fromBase64(base64IV);

                            try {
                              await triggerTextDecrypt(key, iv);
                            } catch (e) {
                              FlutterToast(context).showToast(
                                  child: const Text("An Error Occured"));
                              print("Error :: ${e}");
                            }

                            info.close();
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text("Please Enter Cipher Text"),
                            ));
                          }
                        },
                        child: const Text("Decrypt"))),
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
                  controller: _outputController,
                  decoration: const InputDecoration(
                      label: Text("Plain Text"),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)))),
                ),
              ],
            ),
          ),
        );
      }
      if (qrData["TYPE"] == 1) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            centerTitle: true,
            title: const Text(
              "Found QR",
              style: TextStyle(color: Colors.black),
            ),
          ),
          body: Container(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                QrImage(
                  data: result!.code!,
                  size: 250,
                  backgroundColor: Colors.white,
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
                        onPressed: () async {
                          if (_isDownloading || encryptedFile != null) {
                            return;
                          }
                          setState(() {
                            _isDownloading = true;
                          });
                          var info = ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Row(
                              children: const [
                                CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                                SizedBox(
                                  width: 20,
                                ),
                                Text("Downloading"),
                              ],
                            ),
                            duration: const Duration(days: 365),
                            behavior: SnackBarBehavior.fixed,
                            dismissDirection: DismissDirection.none,
                          ));
                          var qrData = jsonDecode(result!.code!);
                          setState(() {
                            _reference = FirebaseStorage.instance
                                .refFromURL(qrData["URL"]);
                          });

                          var data = await _reference!.getData();

                          setState(() {
                            print(
                                "DOWNLOADED :${base64Encode(List<int>.from(data!))}");
                            encryptedFile = data;
                            _isDownloading = false;
                          });
                          info.close();
                        },
                        child: _isDownloading
                            ? const CircularProgressIndicator()
                            : const Text("Download"))),
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
                        onPressed: () async {
                          if (encryptedFile != null) {
                            var info = ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                              content: Row(
                                children: const [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 20,
                                  ),
                                  Text("Decrypting"),
                                ],
                              ),
                              duration: const Duration(days: 365),
                              behavior: SnackBarBehavior.fixed,
                              dismissDirection: DismissDirection.none,
                            ));
                            var qrData = jsonDecode(result!.code!);
                            print("QR DATA : $qrData");
                            var encryptedKey = qrData["KEY"];
                            var base64IV = qrData["IV"];
                            var privateKey =
                                await keystore.read(key: "privateKey");
                            var rsaPrivateKey =
                                CryptoUtils.rsaPrivateKeyFromPemPkcs1(
                                    privateKey!);

                            var keyBuffer = rsaDecrypt(
                                rsaPrivateKey,
                                base64Decode(encryptedKey)
                                    .buffer
                                    .asUint8List());

                            var key = share_crypt.Key.fromBase64(
                                base64Encode(keyBuffer));
                            var iv = share_crypt.IV.fromBase64(base64IV);

                            try {
                              await triggerFileDecrypt(key, iv);
                            } catch (e) {
                              FlutterToast(context).showToast(
                                  child: const Text("An Error Occured"));
                              print("Error :: ${e}");
                            }

                            info.close();
                          } else {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text("Please Download The File"),
                            ));
                          }
                        },
                        child: const Text("Decrypt"))),
              ],
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            "Found QR",
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: Container(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                const Text("Invalid QR"),
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
                          setState(() {
                            result = null;
                          });
                        },
                        child: const Text("Re-Try"))),
              ],
            )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Scan QR",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: QRView(
        overlay: QrScannerOverlayShape(
            borderColor: Colors.red,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: scanArea),
        cameraFacing: CameraFacing.back,
        onQRViewCreated: _onQRViewCreated,
        key: _qrKey,
      ),
    );
  }

  Future<void> triggerFileDecrypt(
      share_crypt.Key key, share_crypt.IV iv) async {
    var enc = share_crypt.Encrypted(encryptedFile!);

    // Compute=
    var map = {"encrypted": enc, "key": key, "iv": iv};
    var decryption = await compute(decryptFile, map);

    var dir = await getApplicationDocumentsDirectory();

    //Save
    var toSave = File("${dir.path}/${_reference!.name}");
    await toSave.writeAsBytes(decryption);

    await OpenFile.open(toSave.path);
  }

  Future<void> triggerTextDecrypt(
      share_crypt.Key key, share_crypt.IV iv) async {
    var enc = share_crypt.Encrypted.fromBase64(_cipherTextController.text);

    // Compute=
    var map = {"encrypted": enc, "key": key, "iv": iv};
    var decryption = await compute(decryptText, map);

    setState(() {
      _outputController.text = decryption;
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        print(scanData.code);
        result = scanData;
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

Future<List<int>> decryptFile(Map map) async {
  // Decryption
  final encryptor = share_crypt.Encrypter(share_crypt.AES(map['key']));
  final decryption = encryptor.decryptBytes(map['encrypted'], iv: map['iv']);
  return decryption;
}

Future<String> decryptText(Map map) async {
  // Decryption
  final encryptor = share_crypt.Encrypter(share_crypt.AES(map['key']));
  final decryption = encryptor.decrypt(map['encrypted'], iv: map['iv']);
  return decryption;
}

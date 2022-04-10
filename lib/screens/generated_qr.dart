import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class GeneratedQr extends StatefulWidget {
  final Uint8List encryptedKey;

  const GeneratedQr({Key? key, required this.encryptedKey}) : super(key: key);

  @override
  State<GeneratedQr> createState() => _GeneratedQrState();
}

class _GeneratedQrState extends State<GeneratedQr> {
  late final qrValidationResult;

  @override
  void initState() {
    super.initState();
    qrValidationResult = QrValidator.validate(
      data: base64Encode(widget.encryptedKey),
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(10.0),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          HexColor("#30cfd0"),
          HexColor("#330867"),
        ])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QrImage(
              data: base64Encode(widget.encryptedKey),
              size: 250,
              backgroundColor: Colors.white,
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              "Encrypted Key",
              style: TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    primary: Colors.white, onPrimary: Colors.black),
                onPressed: () async {
                  if (qrValidationResult.status == QrValidationStatus.valid) {
                    final qrCode = qrValidationResult.qrCode;
                    final painter = QrPainter.withQr(
                      qr: qrCode,
                      color: const Color(0xFF000000),
                      gapless: true,
                      embeddedImageStyle: null,
                      embeddedImage: null,
                    );

                    Directory tempDir = await getTemporaryDirectory();
                    String tempPath = tempDir.path;
                    final ts = DateTime.now().millisecondsSinceEpoch.toString();
                    String path = '$tempPath/$ts.png';

                    final picData = await painter.toImageData(2048,
                        format: ImageByteFormat.png);

                    await writeToFile(picData!, path);

                    Share.shareFiles([path], text: 'Share QR');
                  }
                },
                child: const Text("Share"))
          ],
        ),
      ),
    );
  }

  Future<void> writeToFile(ByteData data, String path) async {
    final buffer = data.buffer;
    await File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }
}

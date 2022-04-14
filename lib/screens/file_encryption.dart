import 'dart:io';

import 'package:encrypt/encrypt.dart' as share_crypt;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_segment/flutter_advanced_segment.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:permission_handler/permission_handler.dart';

class FileEncryption extends StatefulWidget {
  const FileEncryption({Key? key}) : super(key: key);

  @override
  State<FileEncryption> createState() => _FileEncryptionState();
}

class _FileEncryptionState extends State<FileEncryption> {
  final _controller = ValueNotifier("enc");
  final _keyEditingController = TextEditingController();

  String? _path;
  String? _fileName;

  share_crypt.Key key = share_crypt.Key.fromSecureRandom(32);
  final iv = share_crypt.IV.fromLength(16);

  share_crypt.Encrypted? _currentEncryption;

  bool _processing = false;
  bool _uploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      print(_controller.value);
    });
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
        } else if (_uploading) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Uploading File"),
                  content: const Text(
                      "Uploading under process please wait on the screen"),
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
        } else {
          return true;
        }
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
                    "File Encryption",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                AdvancedSegment(
                    controller: _controller,
                    activeStyle: const TextStyle(fontWeight: FontWeight.normal),
                    inactiveStyle:
                        const TextStyle(fontWeight: FontWeight.normal),
                    segments: const {
                      "enc": "Encryption",
                      "dec": "Decryption",
                    }),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  height: 50,
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined),
                      const SizedBox(
                        width: 10,
                      ),
                      _fileName != null
                          ? Text(_fileName!)
                          : const Text("Select a file")
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: HexColor("#DCDCDC"),
                          onPrimary: Colors.black,
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)))),
                      onPressed: () {
                        selectFile();
                      },
                      child: const Text("Select File")),
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
                          onPressed: () {},
                          child: const Text("Keystore")),
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
                          handleEncryption();
                        },
                        child: const Text("Encrypt"))),
                const SizedBox(
                  height: 50,
                ),
                const Divider(
                  thickness: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void selectFile() async {
    var checkPermission = await Permission.storage.status;

    if (checkPermission.isPermanentlyDenied) {
      FlutterToast(context).showToast(child: Text(checkPermission.toString()));
      return;
    }

    if (checkPermission.isDenied) {
      var res = await Permission.storage.request();
      if (res.isDenied || res.isPermanentlyDenied) {
        FlutterToast(context)
            .showToast(child: Text(checkPermission.toString()));
        return;
      }
    }

    var res = await FilePicker.platform.pickFiles();

    setState(() {
      _fileName = res?.files[0].name;
      _path = res?.paths[0];
    });
  }

  void handleEncryption() async {
    if (_path == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please Select File")));
      return;
    }
    setState(() {
      _processing = true;
    });
    var info = ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Encrypting $_fileName"),
      duration: const Duration(days: 365),
      dismissDirection: DismissDirection.none,
    ));
    await triggerEncrypt();
    info.close();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Encryption Finished")));
    setState(() {
      _processing = false;
    });

    showModalBottomSheet(
        enableDrag: false,
        isDismissible: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10), topRight: Radius.circular(10)),
        ),
        context: context,
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              if (_currentEncryption != null) {
                await showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Dismiss Encrypted File?"),
                        content: const Text(
                            "Please upload the file to be able to share"),
                        actions: [
                          TextButton(
                              onPressed: () {
                                handleDismiss();
                              },
                              child: const Text(
                                "Dismiss File?",
                                style: TextStyle(color: Colors.red),
                              )),
                          TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text("OK")),
                        ],
                      );
                    });
                return false;
              }
              return true;
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  const Text(
                    "File Encrypted",
                    style: TextStyle(
                      fontSize: 24,
                    ),
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
                          handleUpload();
                        },
                        child: const Text("Upload")),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> triggerEncrypt() async {
    var _file = File(_path!);
    var bits8 = await _file.readAsBytes(); //8bits
    // var input = bits8.buffer.asUint16List(); // 128bits

    // Compute
    var map = {"bytes": bits8, "key": key, "iv": iv};
    var encryption = await compute(encryptFile, map);
    setState(() {
      _currentEncryption = encryption;
    });

    // Save
    // var dir = await getExternalStorageDirectory();
    //
    // var toSave = File("${dir?.path}/$_fileName");
    // await toSave.writeAsBytes(encryption.bytes);
  }

  Future<void> handleUpload() async {
    var storageRef = FirebaseStorage.instance.ref("encrypted_files");
    var ref = storageRef.child(_fileName!);
    Navigator.of(context).pop();
    var info = ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: const [
          CircularProgressIndicator(),
          SizedBox(
            width: 20,
          ),
          Text("Uploading"),
        ],
      ),
      duration: Duration(days: 365),
      behavior: SnackBarBehavior.fixed,
      dismissDirection: DismissDirection.none,
    ));
    ref
        .putData(_currentEncryption!.bytes)
        .snapshotEvents
        .listen((taskSnapshot) {
      switch (taskSnapshot.state) {
        case TaskState.running:
          var status = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          print(status);
          setState(() {
            _uploading = true;
            _uploadProgress = status;
          });
          break;
        case TaskState.success:
          info.close();
          FlutterToast(context).showToast(child: const Text("Uploaded"));
          setState(() {
            _uploading = false;
            _path = null;
            _fileName = null;
            _currentEncryption = null;
          });
          break;
        case TaskState.error:
          info.close();
          FlutterToast(context)
              .showToast(child: const Text("An Error Occurred"));
          break;
        case TaskState.paused:
          break;
        case TaskState.canceled:
          break;
      }
    });
  }

  void handleDismiss() {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    setState(() {
      _path = null;
      _fileName = null;
      _currentEncryption = null;
    });
  }
}

Future<void> uploadFile(Map map) async {}

Future<share_crypt.Encrypted> encryptFile(Map map) async {
  // Encryption
  var encryptor = share_crypt.Encrypter(share_crypt.AES(map['key']));
  var encryption = encryptor.encryptBytes(map['bytes'], iv: map['iv']);
  return encryption;
}

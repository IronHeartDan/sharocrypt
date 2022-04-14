import 'package:encrypt/encrypt.dart' as share_crypt;
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sharocrypt/screens/file_encryption.dart';
import 'package:sharocrypt/utils/aes_algo.dart';

class CustomScreen extends StatefulWidget {
  const CustomScreen({Key? key}) : super(key: key);

  @override
  State<CustomScreen> createState() => _CustomScreenState();
}

class _CustomScreenState extends State<CustomScreen> {
  late String _path;
  late String _fileName;
  final TextEditingController _controllerFileName = TextEditingController();

  share_crypt.Key key = share_crypt.Key.fromSecureRandom(32);

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.black87,
          title: const Text("Encypto"),
          actions: [
            IconButton(
                onPressed: () {
                  showAboutDialog(context: context);
                },
                icon: const Icon(Icons.info)),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: size.width,
                height: size.height / 2.2,
                child: Stack(
                  children: [
                    Container(
                      height: size.height * 0.25,
                      color: Colors.black87,
                    ),
                    Positioned(
                        left: 20,
                        top: 50,
                        child: Row(
                          children: const [
                            Text(
                              "Hello,",
                              style:
                                  TextStyle(fontSize: 24, color: Colors.grey),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              "Danish",
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            )
                          ],
                        )),
                    const Positioned(
                        left: 20,
                        top: 100,
                        child: Text(
                          "Secure Communication Tools",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        )),
                    Positioned(
                      left: 20,
                      right: 20,
                      top: size.height * 0.2,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Card(
                                  clipBehavior: Clip.hardEdge,
                                  elevation: 5,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: InkWell(
                                    onTap: () async {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const FileEncryption()));
                                      return;
                                      var checkPermission =
                                          await Permission.storage.status;

                                      if (checkPermission.isPermanentlyDenied) {
                                        FlutterToast(context).showToast(
                                            child: Text(
                                                checkPermission.toString()));
                                        return;
                                      }

                                      if (checkPermission.isDenied) {
                                        var res =
                                            await Permission.storage.request();
                                        if (res.isDenied ||
                                            res.isPermanentlyDenied) {
                                          return;
                                        }
                                      }

                                      var res =
                                          await FilePicker.platform.pickFiles();

                                      await showModalBottomSheet(
                                          clipBehavior: Clip.hardEdge,
                                          shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.only(
                                                  topRight: Radius.circular(20),
                                                  topLeft:
                                                      Radius.circular(20))),
                                          context: context,
                                          builder: (context) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: Column(
                                                children: [
                                                  const Text(
                                                    "AES File Encryption",
                                                    style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                  TextFormField(
                                                    controller:
                                                        _controllerFileName,
                                                    decoration: const InputDecoration(
                                                        label: Text(
                                                            "Enter File Name"),
                                                        border:
                                                            OutlineInputBorder()),
                                                  ),
                                                  const SizedBox(
                                                    height: 20,
                                                  ),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    height: 40,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        var name =
                                                            _controllerFileName
                                                                .text;
                                                        var path =
                                                            res?.paths[0];
                                                        if (name.isNotEmpty &&
                                                            path != null) {
                                                          setState(() {
                                                            _fileName = name;
                                                            _path = path;
                                                          });

                                                          triggerEncrypt(
                                                                  _path,
                                                                  _fileName,
                                                                  key)
                                                              .whenComplete(() =>
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop());
                                                        }
                                                      },
                                                      child:
                                                          const Text("Encrypt"),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            );
                                          });
                                      // var extension = _path?.split(".").last;
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Image.asset(
                                              "assets/asset_home_one.png"),
                                          const Text(
                                            "File\nEncryption",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Card(
                                  clipBehavior: Clip.hardEdge,
                                  elevation: 5,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: InkWell(
                                    onTap: () {},
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Image.asset(
                                              "assets/asset_home_two.png"),
                                          const Text(
                                            "Text\nEncryption",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Card(
                                  clipBehavior: Clip.hardEdge,
                                  elevation: 5,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: InkWell(
                                    onTap: () {},
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Image.asset(
                                              "assets/asset_home_three.png"),
                                          const Text(
                                            "Secure\nPassword",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Card(
                                  clipBehavior: Clip.hardEdge,
                                  elevation: 5,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(10))),
                                  child: InkWell(
                                    onTap: () {
                                      print("TAP");
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Image.asset(
                                              "assets/asset_home_four.png"),
                                          const Text(
                                            "QR\nCode",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context)
                            .colorScheme
                            .copyWith(primary: Colors.black),
                      ),
                      child: TextFormField(
                        decoration: InputDecoration(
                            label: const Text("Search"),
                            floatingLabelBehavior: FloatingLabelBehavior.never,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: const Icon(Icons.mic),
                            fillColor: HexColor("#EFEFEF"),
                            filled: true,
                            border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10))),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    const Text(
                      "Encryption is a key of\nsecuring the future",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
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
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            clipBehavior: Clip.hardEdge,
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            color: HexColor("#E2E2E2"),
                            child: InkWell(
                              onTap: () {},
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: ListTile(
                                  leading: Icon(Icons.cloud_upload),
                                  title: Text("Backup"),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            clipBehavior: Clip.hardEdge,
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            color: HexColor("#E2E2E2"),
                            child: InkWell(
                              onTap: () {},
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: ListTile(
                                  leading: Icon(Icons.golf_course_outlined),
                                  title: Text("Data Store"),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            clipBehavior: Clip.hardEdge,
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            color: HexColor("#E2E2E2"),
                            child: InkWell(
                              onTap: () async {
                                await FirebaseAuth.instance.signOut();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: InkWell(
                                  child: ListTile(
                                    leading: Icon(Icons.settings),
                                    title: Text("Settings"),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Card(
                            clipBehavior: Clip.hardEdge,
                            shape: const RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10))),
                            color: HexColor("#E2E2E2"),
                            child: InkWell(
                              onTap: () {},
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: ListTile(
                                  leading: Icon(Icons.help),
                                  title: Text("Help"),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

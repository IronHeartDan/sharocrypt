import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class EncryptedFilesScreen extends StatefulWidget {
  const EncryptedFilesScreen({Key? key}) : super(key: key);

  @override
  State<EncryptedFilesScreen> createState() => _EncryptedFilesScreenState();
}

class _EncryptedFilesScreenState extends State<EncryptedFilesScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<FileSystemEntity>?> getFiles() async {
    var dir = await getExternalStorageDirectory();
    var res = await dir?.list().toList();
    return res;
  }

  Future<bool?> deleteFile(DismissDirection direction) async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: FutureBuilder(
        future: getFiles(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text("An Error Occured");
          }

          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              var data = snapshot.data as List<FileSystemEntity>;
              return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      direction: DismissDirection.endToStart,
                      confirmDismiss: deleteFile,
                      background: Container(
                        padding: const EdgeInsets.all(8.0),
                        color: Colors.red,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Icon(
                              Icons.delete,
                              color: Colors.white,
                            )
                          ],
                        ),
                      ),
                      key: Key(index.toString()),
                      child: ListTile(
                        horizontalTitleGap: 2,
                        onTap: () async {
                          await OpenFile.open(data[index].path);
                        },
                        title: Text(data[index].path.split("/").last),
                        leading: const Icon(Icons.insert_drive_file_outlined),
                      ),
                    );
                  });
            }
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

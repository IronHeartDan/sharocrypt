import 'package:basic_utils/basic_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchForm = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  bool notFoundError = false;
  bool _searching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sharing Details",
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Form(
          key: _searchForm,
          child: Column(
            children: [
              TextFormField(
                controller: _searchController,
                maxLength: 10,
                decoration: InputDecoration(
                    errorText: notFoundError ? "User Not Found" : null,
                    label: const Text("Enter Receiver Number"),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please Enter Number";
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 10,
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
                        if (_searchForm.currentState!.validate() &&
                            !_searching) {
                          setState(() {
                            _searching = true;
                            notFoundError = false;
                          });
                          var user = await FirebaseFirestore.instance
                              .collection("users")
                              .doc("+91${_searchController.text}")
                              .get();
                          if (user.exists) {
                            var publicKey = user.data()!['publicKey'];
                            var rsaPublicKey =
                                CryptoUtils.rsaPublicKeyFromPem(publicKey);
                            Navigator.of(context).pop(rsaPublicKey);
                          } else {
                            setState(() {
                              _searching = false;
                              notFoundError = true;
                            });
                          }
                        }
                      },
                      child: _searching
                          ? const CircularProgressIndicator()
                          : const Text("Search"))),
            ],
          ),
        ),
      ),
    );
  }
}

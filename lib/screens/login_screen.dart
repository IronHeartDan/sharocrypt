import 'package:basic_utils/basic_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:sharocrypt/screens/custom_home_scree.dart';
import 'package:sharocrypt/screens/register_screen.dart';
import 'package:validators/validators.dart';

import '../utils/rsa_algo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            width: size.width,
            padding: const EdgeInsets.all(10.0),
            margin: const EdgeInsets.only(top: kToolbarHeight),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Start secure journey with us",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    controller: _emailController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        label: Text("Email"),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Email';
                      } else if (!isEmail(value)) {
                        return "Invalid Email";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    obscureText: true,
                    decoration: const InputDecoration(
                        label: Text("Password"),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 50,
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
                            if (_isLoading) return;
                            if (_formKey.currentState!.validate()) {
                              logInUser();
                            }
                          },
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text("LogIn"))),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account ?"),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterScreen()),
                                (route) => false);
                          },
                          child: const Text(
                            "SignUp",
                            style: TextStyle(color: Colors.blue),
                          ))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void logInUser() async {
    setState(() {
      _isLoading = true;
    });
    var info = ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Logging"),
      duration: Duration(days: 365),
    ));
    var auth = FirebaseAuth.instance;
    var _email = _emailController.text;
    var _pass = _passwordController.text;

    try {
      await auth.signInWithEmailAndPassword(email: _email, password: _pass);
      try {
        await manageRSA();
      } on Exception catch (e) {
        print(e);
        await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return WillPopScope(
                onWillPop: () async {
                  return false;
                },
                child: AlertDialog(
                  title: const Text("An Error Occurred"),
                  content: const Text("Please Try Again!"),
                  actions: [
                    TextButton(
                        onPressed: () async {
                          await manageRSA();
                        },
                        child: const Text("Retry"))
                  ],
                ),
              );
            });
      }
      info.close();
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const CustomScreen()),
          (route) => false);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      info.close();
      if (e.code == 'user-not-found') {
        FlutterToast(context).showToast(child: const Text("User not found!"));
      } else if (e.code == 'wrong-password') {
        FlutterToast(context)
            .showToast(child: const Text("Incorrect Password"));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      info.close();
      print(e);
      FlutterToast(context).showToast(child: Text(e.toString()));
    }
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
}

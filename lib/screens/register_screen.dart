import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:sharocrypt/screens/login_screen.dart';
import 'package:validators/validators.dart';

import 'custom_home_scree.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
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
                          "Create Account",
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "To keep connected with us",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(
                        label: Text("Name"),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Name';
                      } else if (value.length < 4) {
                        return "Minimum Length Required Is 4";
                      }
                      return null;
                    },
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
                    controller: _phoneController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        label: Text("Phone"),
                        border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10)))),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please Enter Phone';
                      } else if (value.length != 10) {
                        return "Invalid Phone";
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
                              registerUser();
                            }
                          },
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text("SignUp"))),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Have an account ? "),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                                (route) => false);
                          },
                          child: const Text(
                            "LogIn",
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

  void registerUser() async {
    setState(() {
      _isLoading = true;
    });
    var info = ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Registering"),
      duration: Duration(days: 365),
    ));
    var auth = FirebaseAuth.instance;
    var _name = _nameController.text;
    var _email = _emailController.text;
    var _phone = _phoneController.text;
    var _pass = _passwordController.text;

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: _email,
        password: _pass,
      );
      await credential.user?.updateDisplayName(_name);

      await auth.verifyPhoneNumber(
          phoneNumber: "+91$_phone",
          verificationCompleted: (phoneAuthCredential) async {
            await credential.user?.updatePhoneNumber(phoneAuthCredential);
            info.close();
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const CustomScreen()), (
                route) => false);
          },
          verificationFailed: (e) {
            FlutterToast(context).showToast(child: Text("${e.message}"));
          },
          codeSent: (id, code) async {
            var _codeController = TextEditingController();
            var _codeForm = GlobalKey<FormState>();
            bool invalidCode = false;
            await showDialog(
                context: context,
                builder: (context) {
                  return WillPopScope(
                    onWillPop: () async {
                      return false;
                    },
                    child:
                        StatefulBuilder(builder: (context, setAlertBoxState) {
                      return AlertDialog(
                        title: const Text("Enter OTP"),
                        content: Form(
                          key: _codeForm,
                          child: TextFormField(
                            controller: _codeController,
                            maxLength: 6,
                            decoration: InputDecoration(
                                errorText: invalidCode ? "Invalid OTP" : null,
                                label: const Text("OTP"),
                                border: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)))),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.length < 6) {
                                return "Please Enter Verification Code Of Length 6";
                              }

                              return null;
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () async {
                                if (_codeForm.currentState!.validate()) {
                                  setAlertBoxState(() {
                                    invalidCode = false;
                                  });

                                  var phoneAuthCredential =
                                      PhoneAuthProvider.credential(
                                          verificationId: id,
                                          smsCode: _codeController.text);
                                  try {
                                    await credential.user?.updatePhoneNumber(
                                        phoneAuthCredential);

                                    info.close();
                                    Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (context) => const CustomScreen()), (
                                        route) => false);
                                  } on FirebaseAuthException catch (e) {
                                    setAlertBoxState(() {
                                      invalidCode = true;
                                    });
                                  }
                                }
                              },
                              child: const Text("Verify"))
                        ],
                      );
                    }),
                  );
                },
                barrierDismissible: false);
          },
          codeAutoRetrievalTimeout: (codeAutoRetrievalTimeout) {});
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      info.close();
      if (e.code == 'weak-password') {
        FlutterToast(context)
            .showToast(child: const Text("The password provided is too weak."));
      } else if (e.code == 'email-already-in-use') {
        FlutterToast(context).showToast(
            child: const Text("The account already exists for that email."));
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
}

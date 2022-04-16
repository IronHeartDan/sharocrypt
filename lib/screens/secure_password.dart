import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:password_generator/password_generator.dart';

class SecurePassword extends StatefulWidget {
  const SecurePassword({Key? key}) : super(key: key);

  @override
  State<SecurePassword> createState() => _SecurePasswordState();
}

class _SecurePasswordState extends State<SecurePassword> {
  final _passwordController = TextEditingController();

  int length = 20;
  bool hasCapitalLetters = true;
  bool hasNumbers = true;
  bool hasSmallLetters = true;
  bool hasSymbols = true;
  bool hasError = false;
  bool lengthError = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Password"),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              TextFormField(
                maxLength: 3,
                initialValue: 20.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (int.parse(value) < 5) {
                    setState(() {
                      lengthError = true;
                    });
                    return;
                  } else {
                    setState(() {
                      lengthError = false;
                    });
                  }
                  setState(() {
                    length = int.parse(value);
                  });
                },
                decoration: InputDecoration(
                    errorText: lengthError ? "At Least 5 is required !" : null,
                    label: const Text("Length"),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
              const SizedBox(
                height: 10,
              ),
              ListTile(
                title: const Text("Capital Letters"),
                trailing: Switch(
                  value: hasCapitalLetters,
                  onChanged: (bool value) {
                    setState(() {
                      hasCapitalLetters = value;
                      check();
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ListTile(
                title: const Text("Small Letters"),
                trailing: Switch(
                  value: hasSmallLetters,
                  onChanged: (bool value) {
                    setState(() {
                      hasSmallLetters = value;
                      check();
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ListTile(
                title: const Text("Include Numbers"),
                trailing: Switch(
                  value: hasNumbers,
                  onChanged: (bool value) {
                    setState(() {
                      hasNumbers = value;
                      check();
                    });
                  },
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ListTile(
                title: const Text("Include Special Characters"),
                trailing: Switch(
                  value: hasSymbols,
                  onChanged: (bool value) {
                    setState(() {
                      hasSymbols = value;
                      check();
                    });
                  },
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
                        if (!hasError && !lengthError) {
                          var _passwordGenerator = PasswordGenerator(
                            length: length,
                            hasCapitalLetters: hasCapitalLetters,
                            hasNumbers: hasNumbers,
                            hasSmallLetters: hasSmallLetters,
                            hasSymbols: hasSymbols,
                          );

                          String _password =
                              _passwordGenerator.generatePassword();

                          setState(() {
                            _passwordController.text = _password;
                          });
                        }
                      },
                      child: const Text("GENERATE"))),
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
                controller: _passwordController,
                decoration: InputDecoration(
                    errorText:
                        hasError ? "At Least One Check Required !" : null,
                    label: const Text("Password"),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void check() {
    if (!hasCapitalLetters && !hasSmallLetters && !hasNumbers && !hasSymbols) {
      setState(() {
        hasError = true;
      });
    } else {
      setState(() {
        hasError = false;
      });
    }
  }
}

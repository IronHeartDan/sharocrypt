import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:sharocrypt/utils/rsa_algo.dart';

import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _processingRSA = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_processingRSA) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Please Wait"),
                  content: const Text(
                      "RSA key pair generation is under process. Please wait on this screen."),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("OK"))
                  ],
                );
              });
        }
        return !_processingRSA;
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text("Settings"),
            backgroundColor: Colors.white,
          ),
          body: SettingsList(sections: [
            SettingsSection(
              title: const Text('General'),
              tiles: <SettingsTile>[
                SettingsTile.navigation(
                  onPressed: (context) async {
                    await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Generate RSA"),
                            content:
                                const Text("Are you sure you want to logout ?"),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("Cancel")),
                              TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();

                                    var info = ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                      content: Text("Processing RSA"),
                                      dismissDirection: DismissDirection.none,
                                      duration: Duration(days: 365),
                                    ));
                                    setState(() {
                                      _processingRSA = true;
                                    });
                                    await manageRSA();
                                    info.close();
                                    setState(() {
                                      _processingRSA = false;
                                    });
                                  },
                                  child: const Text(
                                    "Generate",
                                    style: TextStyle(color: Colors.green),
                                  )),
                            ],
                          );
                        });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("RSA Generated"),
                    ));
                  },
                  enabled: !_processingRSA,
                  leading: const Icon(Icons.vpn_key_outlined),
                  title: const Text('Generate RSA'),
                  value: const Text('Old Files Will Not Be Recoverable'),
                ),
                SettingsTile.navigation(
                  onPressed: (context) async {
                    await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Log Out ?"),
                            content:
                                const Text("Are you sure you want to logout ?"),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("Cancel")),
                              TextButton(
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginScreen()),
                                        (route) => false);
                                  },
                                  child: const Text(
                                    "LogOut",
                                    style: TextStyle(color: Colors.red),
                                  )),
                            ],
                          );
                        });
                  },
                  leading: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'LogOut',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ])),
    );
  }
}

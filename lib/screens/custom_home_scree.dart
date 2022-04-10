import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

import '../utils/custom_app_bar.dart';

class CustomScreen extends StatefulWidget {
  const CustomScreen({Key? key}) : super(key: key);

  @override
  State<CustomScreen> createState() => _CustomScreenState();
}

class _CustomScreenState extends State<CustomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverPersistentHeader(
            delegate: CustomAppBar(expandedHeight: 300)),
        const SliverToBoxAdapter(
          child: SizedBox(
            width: double.infinity,
            height: 200,
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
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
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
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
                  children: const [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: Icon(Icons.cloud_upload),
                            title: Text("Backup"),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: Icon(Icons.golf_course_outlined),
                            title: Text("Data Store"),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: const [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: Icon(Icons.settings),
                            title: Text("Settings"),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: Icon(Icons.help),
                            title: Text("Help"),
                          ),
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

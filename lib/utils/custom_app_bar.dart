import 'package:flutter/material.dart';

class CustomAppBar extends SliverPersistentHeaderDelegate {
  final double expandedHeight;

  const CustomAppBar({required this.expandedHeight});

  double appear(double shrinkOffset) => shrinkOffset / expandedHeight;

  double disappear(double shrinkOffset) => 1 - shrinkOffset / expandedHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        AppBar(
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
        Positioned(
            left: 20,
            top: 150,
            child: Opacity(
              opacity: disappear(shrinkOffset),
              child: Row(
                children: const [
                  Text(
                    "Hello,",
                    style: TextStyle(fontSize: 24, color: Colors.grey),
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
              ),
            )),
        Positioned(
            left: 20,
            top: 200,
            child: Opacity(
              opacity: disappear(shrinkOffset),
              child: const Text(
                "Secure Communication Tools",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            )),
        Positioned(
            left: 20,
            right: 20,
            bottom: -180,
            child: SizedBox(
              height: 280,
              child: GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 2,
                ),
                children: [
                  Card(
                    elevation: 5,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset("assets/asset_home_one.png"),
                          const Text(
                            "File\nEncryption",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          )
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 5,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset("assets/asset_home_two.png"),
                          const Text(
                            "Text\nEncryption",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          )
                        ],
                      ),
                    ),
                  ),
                  Card(
                    elevation: 5,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset("assets/asset_home_three.png"),
                          const Text(
                            "Secure\nPassword",
                            style: TextStyle(fontWeight: FontWeight.w500),
                          )
                        ],
                      ),
                    ),
                  ),
                  Card(
                    clipBehavior: Clip.hardEdge,
                    elevation: 5,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: InkWell(
                      onTap: () {
                        print("TAP");
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset("assets/asset_home_four.png"),
                            const Text(
                              "QR\nCode",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ))
      ],
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => kToolbarHeight + 30;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

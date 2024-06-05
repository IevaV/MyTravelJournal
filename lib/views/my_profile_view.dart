import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:watch_it/watch_it.dart';
import '../services/auth/auth_service.dart';

class MyProfileView extends StatelessWidget with WatchItMixin {
  MyProfileView({super.key});
  final User user = getIt<User>();

  @override
  Widget build(BuildContext context) {
    final pastTrips =
        user.userTrips.where((trip) => trip.state == "past").toList();
    return Scaffold(
      body: Container(
        color: MaterialStateColor.resolveWith(
            (states) => const Color.fromRGBO(119, 102, 203, 1)),
        child: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(125, 119, 255, 0.984),
                  Color.fromRGBO(255, 232, 173, 0.984),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: MaterialStateColor.resolveWith(
                        (states) => const Color.fromRGBO(119, 102, 203, 1)),
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(35),
                        bottomRight: Radius.circular(35)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(flex: 1, child: SizedBox()),
                      const Expanded(
                          flex: 1,
                          child: Center(
                              child: Text(
                            "Test",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 10.0,
                                  offset: Offset(0.0, 3.0),
                                ),
                              ],
                            ),
                          ))),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: () {
                              AuthService.firebase().logout();
                              context.go('/welcome');
                            },
                            icon: const Icon(
                              Icons.logout,
                              size: 40,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 180,
                        width: 150,
                        decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.white60,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
                              child: Text(
                                "I have been on",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xff46467A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 35,
                                width: 75,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: Color(0xff46467A),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25)),
                                ),
                                child: Center(
                                    child: Text(
                                  pastTrips.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                " different\n   trips!",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xff46467A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 180,
                        width: 150,
                        decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.white60,
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
                              child: Text(
                                "I have spent",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xff46467A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 35,
                                width: 75,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: Color(0xff46467A),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25)),
                                ),
                                child: Center(
                                    child: Text(
                                  pastTrips
                                      .map((trip) => trip.days.length)
                                      .reduce(
                                          (value, element) => value + element)
                                      .toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "    days \ntravelling!",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xff46467A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 180,
                        width: 150,
                        decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.white60,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
                              child: Text(
                                "I have visited",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xff46467A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 35,
                                width: 75,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: Color(0xff46467A),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25)),
                                ),
                                child: const Center(
                                    child: Text(
                                  "123",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "   different\ncheckpoints!",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xff46467A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 180,
                        width: 150,
                        decoration: const BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: Colors.white60,
                          borderRadius: BorderRadius.all(Radius.circular(25)),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 12.0, bottom: 12.0),
                              child: Text(
                                "  I have\ntravelled",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xff46467A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                height: 35,
                                width: 75,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: Color(0xff46467A),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(25)),
                                ),
                                child: const Center(
                                    child: Text(
                                  "582",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "kilometers!",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xff46467A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8, right: 8),
                  child: Row(
                    children: [
                      Container(
                        height: 65,
                        width: 250,
                        decoration: const BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: Colors.white60,
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(25.0),
                                bottomRight: Radius.circular(25.0))),
                        child: const Center(
                          child: Text(
                            "Visited Countries",
                            style: TextStyle(
                                fontSize: 24,
                                color: Color(0xff46467A),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 8, left: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 65,
                        width: 250,
                        decoration: const BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: Color(0xff46467A),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(25.0),
                                bottomLeft: Radius.circular(25.0))),
                        child: const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              "Total: 5",
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //     children: [
                //       Container(
                //         height: 120,
                //         width: 350,
                //         decoration: const BoxDecoration(
                //           shape: BoxShape.rectangle,
                //           color: Colors.white60,
                //           borderRadius: BorderRadius.all(Radius.circular(20)),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

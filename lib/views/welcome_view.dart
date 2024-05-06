import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/constants/color_constants.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeView();
}

class _WelcomeView extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                Flexible(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 130,
                        width: 96 * 1.5,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              child:
                                  Image(image: AssetImage('assets/Logo.png')),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Title(
                          color: ColorConstants.assetColorWhite,
                          child: const Text(
                            'MY TRAVEL\n  JOURNAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 10.0,
                                  offset: Offset(0.0, 3.0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Flexible(
                  flex: 2,
                  child: Container(
                    constraints: const BoxConstraints.expand(),
                    decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(60),
                            topRight: Radius.circular(60)),
                        color: Colors.white24),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 60.0,
                            bottom: 20.0,
                          ),
                          child: ElevatedButton(
                            onPressed: () => context.go('/sign-in'),
                            style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(
                                const Size(250, 60),
                              ),
                              backgroundColor: MaterialStateColor.resolveWith(
                                  (states) =>
                                      Color.fromRGBO(119, 102, 203, 0.984)),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              elevation: MaterialStateProperty.all(3.0),
                            ),
                            child: const Text(
                              'SIGN IN',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: ColorConstants.assetColorWhite,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: OutlinedButton(
                            onPressed: () => context.go('/sign-up'),
                            style: ButtonStyle(
                              minimumSize: MaterialStateProperty.all(
                                const Size(250, 60),
                              ),
                              side: MaterialStateProperty.all(const BorderSide(
                                  color: Color.fromRGBO(119, 102, 203, 0.984),
                                  width: 3.0,
                                  style: BorderStyle.solid)),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                            child: const Text(
                              'SIGN UP',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Color.fromRGBO(119, 102, 203, 0.984),
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 10.0,
                                    offset: Offset(0.0, 3.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

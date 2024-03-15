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
      backgroundColor: ColorConstants.primaryYellow,
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              Flexible(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 130,
                      width: 96 * 1.5,
                      child: Stack(
                        alignment: Alignment.center,
                        children: const [
                          Align(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.menu_book_outlined,
                              size: 100.0,
                              color: ColorConstants.primaryTurquoise,
                            ),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Icon(
                              Icons.location_pin,
                              size: 80.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Title(
                        color: ColorConstants.assetColorWhite,
                        child: const Text(
                          'My Travel\n Journal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: ColorConstants.primaryTurquoise,
                          ),
                        ))
                  ],
                ),
              ),
              const Spacer(
                flex: 1,
              ),
              Flexible(
                flex: 4,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () => context.go('/sign-in'),
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all(
                            const Size(200, 50),
                          ),
                          backgroundColor: MaterialStateColor.resolveWith(
                              (states) => ColorConstants.primaryRed),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          elevation: MaterialStateProperty.all(3.0),
                        ),
                        child: const Text(
                          'LOGIN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: ColorConstants.assetColorWhite,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton(
                        onPressed: () => context.go('/sign-up'),
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all(
                            const Size(200, 50),
                          ),
                          side: MaterialStateProperty.all(const BorderSide(
                              color: ColorConstants.primaryRed,
                              width: 1.0,
                              style: BorderStyle.solid)),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        child: const Text(
                          'REGISTER',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: ColorConstants.primaryRed,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

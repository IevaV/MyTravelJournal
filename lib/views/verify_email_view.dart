import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/services/auth/auth_service.dart';
import '../constants/color_constants.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.primaryYellow,
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'VERIFY EMAIL',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.assetColorWhite,
                    ),
                  ),
                  SizedBox(height: 50),
                  Text(
                    "We've sent you an email verification.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      color: ColorConstants.assetColorWhite,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Please open and verify your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () async {
                      await AuthService.firebase().logout();
                      if (context.mounted) {
                        context.go('/sign-in');
                      }
                    },
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(
                        const Size(250, 50),
                      ),
                      backgroundColor: MaterialStateColor.resolveWith(
                          (states) => ColorConstants.primaryTurquoise),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      elevation: MaterialStateProperty.all(3.0),
                    ),
                    child: const Text(
                      'GO TO LOGIN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: ColorConstants.assetColorWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "If you haven't received email verification, press this button",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      color: ColorConstants.assetColorWhite,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () async {
                      await AuthService.firebase().sendEmailVerification();
                    },
                    style: ButtonStyle(
                      minimumSize: MaterialStateProperty.all(
                        const Size(250, 50),
                      ),
                      backgroundColor: MaterialStateColor.resolveWith(
                          (states) => ColorConstants.primaryRed),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      elevation: MaterialStateProperty.all(3.0),
                    ),
                    child: const Text(
                      'RESEND EMAIL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: ColorConstants.assetColorWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

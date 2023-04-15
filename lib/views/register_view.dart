import 'package:flutter/material.dart';
import 'package:mytraveljournal/components/authComponents/auth_input_field.dart';
import 'package:mytraveljournal/constants/color_constants.dart';
import 'dart:developer' as devtools show log;
import 'package:mytraveljournal/constants/routes.dart';
import 'package:mytraveljournal/services/auth/auth_exceptions.dart';
import 'package:mytraveljournal/services/auth/auth_service.dart';
import 'package:mytraveljournal/utilities/show_error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _passwordConfirm;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _passwordConfirm = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ColorConstants.primaryYellow,
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'CREATE ACCOUNT',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.assetColorWhite,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(
                  //       horizontal: 40.0, vertical: 10),
                  //   child: PhysicalModel(
                  //     borderRadius: BorderRadius.circular(50),
                  //     color: ColorConstants.primaryYellow,
                  //     elevation: 5.0,
                  //     shadowColor: ColorConstants.assetColorBlack,
                  //     child: TextField(
                  //       controller: _email,
                  //       enableSuggestions: false,
                  //       autocorrect: false,
                  //       keyboardType: TextInputType.emailAddress,
                  //       decoration: InputDecoration(
                  //         hintStyle: const TextStyle(
                  //           color: ColorConstants.turquoisePlaceholderText,
                  //         ),
                  //         hintText: 'Enter your email here',
                  //         border: OutlineInputBorder(
                  //           borderRadius: BorderRadius.circular(50.0),
                  //           borderSide: BorderSide.none,
                  //         ),
                  //         filled: true,
                  //         fillColor: ColorConstants.yellowPlaceholderBackground,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(
                  //       horizontal: 40.0, vertical: 10),
                  //   child: PhysicalModel(
                  //     borderRadius: BorderRadius.circular(50),
                  //     color: ColorConstants.primaryYellow,
                  //     elevation: 5.0,
                  //     shadowColor: ColorConstants.assetColorBlack,
                  //     child: TextField(
                  //       controller: _password,
                  //       obscureText: true,
                  //       enableSuggestions: false,
                  //       autocorrect: false,
                  //       decoration: InputDecoration(
                  //         hintStyle: const TextStyle(
                  //           color: ColorConstants.turquoisePlaceholderText,
                  //         ),
                  //         hintText: 'Enter your password here',
                  //         border: OutlineInputBorder(
                  //           borderRadius: BorderRadius.circular(50.0),
                  //           borderSide: BorderSide.none,
                  //         ),
                  //         filled: true,
                  //         fillColor: ColorConstants.yellowPlaceholderBackground,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(
                  //       horizontal: 40.0, vertical: 10),
                  //   child: PhysicalModel(
                  //     borderRadius: BorderRadius.circular(50),
                  //     color: ColorConstants.primaryYellow,
                  //     elevation: 5.0,
                  //     shadowColor: ColorConstants.assetColorBlack,
                  //     child: TextField(
                  //       controller: _passwordConfirm,
                  //       obscureText: true,
                  //       enableSuggestions: false,
                  //       autocorrect: false,
                  //       decoration: InputDecoration(
                  //         hintStyle: const TextStyle(
                  //           color: ColorConstants.turquoisePlaceholderText,
                  //         ),
                  //         hintText: 'Confirm your password here',
                  //         border: OutlineInputBorder(
                  //           borderRadius: BorderRadius.circular(50.0),
                  //           borderSide: BorderSide.none,
                  //         ),
                  //         filled: true,
                  //         fillColor: ColorConstants.yellowPlaceholderBackground,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  AuthInPutField(
                    textController: _email,
                    hintText: 'Enter your email here',
                    obscureText: false,
                  ),
                  AuthInPutField(
                    textController: _password,
                    hintText: 'Enter your password here',
                    obscureText: true,
                  ),
                  AuthInPutField(
                    textController: _passwordConfirm,
                    hintText: 'Confirm your password here',
                    obscureText: true,
                  )
                ],
              ),
            ),
            Flexible(
              flex: 2,
              child: Column(
                children: [
                  TextButton(
                    onPressed: () async {
                      final email = _email.text;
                      final password = _password.text;
                      final passwordConfirm = _passwordConfirm.text;
                      if (password == passwordConfirm) {
                        try {
                          await AuthService.firebase()
                              .createUser(email: email, password: password);
                          AuthService.firebase().sendEmailVerification();
                          if (context.mounted) {
                            Navigator.of(context).pushNamed(verifyEmailRoute);
                          }
                        } on WeakPasswordAuthException {
                          showErrorDialog(context, 'Weak password');
                        } on EmailAlreadyInUseAuthException {
                          showErrorDialog(context, 'Email is already in use');
                        } on InvalidEmailAuthException {
                          showErrorDialog(
                              context, 'This is an invalid email address');
                        } on GenericAuthException {
                          await showErrorDialog(context, 'Failed to register');
                        }
                      } else {
                        showErrorDialog(
                            context, 'Password fields do not match!');
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
                      'SIGN UP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: ColorConstants.assetColorWhite,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorConstants.assetColorBlack,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            loginRoute,
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Sign in',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryRed,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/constants/routes.dart';
import 'package:mytraveljournal/main.dart';
import 'package:mytraveljournal/services/auth/auth_exceptions.dart';
import 'package:mytraveljournal/services/auth/auth_service.dart';
import 'package:mytraveljournal/services/auth/auth_user.dart';
import '../components/auth_components/auth_input_field.dart';
import '../constants/color_constants.dart';
import '../utilities/show_error_dialog.dart';

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
                    'LOGIN',
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
                  AuthInputField(
                    textController: _email,
                    hintText: 'Enter your email here',
                    obscureText: false,
                  ),
                  AuthInputField(
                    textController: _password,
                    hintText: 'Enter your password here',
                    obscureText: true,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: TextButton(
                        onPressed: () {
                          //TODO navigation to Forgot Password view
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            registerRoute,
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primaryRed,
                          ),
                        ),
                      ),
                    ),
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
                      try {
                        await AuthService.firebase()
                            .logIn(email: email, password: password);
                        final user = AuthService.firebase().currentUser;
                        if ((user?.isEmailVerified ?? false) &&
                            context.mounted) {
                          GetIt.I.registerSingleton<AuthUser>(user!);
                          context.go('/home');
                        } else {
                          context.go('/verify-email');
                        }
                      } on UserNotFoundAuthException {
                        await showErrorDialog(context, 'User not found');
                      } on WrongPasswordAuthException {
                        await showErrorDialog(context, 'Wrong credentials');
                      } on GenericAuthException {
                        await showErrorDialog(context, 'Authentication error');
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
                      'LOGIN',
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
                        'Not registered yet?',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorConstants.assetColorBlack,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          context.go('/sign-up');
                        },
                        child: const Text(
                          'Sign up',
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/components/auth_components/auth_input_field.dart';
import 'package:mytraveljournal/constants/color_constants.dart';
import 'package:mytraveljournal/services/auth/auth_exceptions.dart';
import 'package:mytraveljournal/services/auth/auth_service.dart';
import 'package:mytraveljournal/utilities/show_error_dialog.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
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
                  AuthInputField(
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
                          //TODO Add user to db
                          AuthService.firebase().sendEmailVerification();
                          if (context.mounted) {
                            context.go('/verify-email');
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
                          context.go('/sign-in');
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

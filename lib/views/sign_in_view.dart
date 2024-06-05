import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/auth/auth_exceptions.dart';
import 'package:mytraveljournal/services/auth/auth_service.dart';
import '../components/auth_components/auth_input_field.dart';
import '../constants/color_constants.dart';
import '../components/dialog_components/show_error_dialog.dart';

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
          child: Column(
            children: [
              Flexible(
                flex: 1,
                child: Container(
                  height: 220,
                  width: 410,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(60),
                          bottomRight: Radius.circular(60)),
                      color: Colors.white24),
                  child: const Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: 25.0,
                          bottom: 10.0,
                        ),
                        child: SizedBox(
                          height: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image(image: AssetImage('assets/Logo.png')),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        'SIGN IN',
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
                    ],
                  ),
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
                      labelText: 'Email',
                    ),
                    AuthInputField(
                      textController: _password,
                      hintText: 'Enter your password here',
                      obscureText: true,
                      labelText: 'Password',
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50.0),
                        child: TextButton(
                          onPressed: () {
                            context.go('/reset-password');
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
                flex: 1,
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final email = _email.text;
                        final password = _password.text;
                        try {
                          await AuthService.firebase()
                              .logIn(email: email, password: password);
                          final user = AuthService.firebase().currentUser;
                          if ((user?.isEmailVerified ?? false) &&
                              context.mounted) {
                            await GetIt.I<User>().assignUserData(user!.uid);
                            context.go('/home');
                          } else {
                            context.go('/verify-email');
                          }
                        } on UserNotFoundAuthException {
                          await showErrorDialog(context, 'User not found');
                        } on WrongPasswordAuthException {
                          await showErrorDialog(context, 'Wrong credentials');
                        } on GenericAuthException {
                          await showErrorDialog(
                              context, 'Authentication error');
                        }
                      },
                      style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all(
                          const Size(250, 60),
                        ),
                        backgroundColor: MaterialStateColor.resolveWith(
                            (states) =>
                                const Color.fromRGBO(119, 102, 203, 0.984)),
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
      ),
    );
  }
}

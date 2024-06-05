import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/components/auth_components/auth_input_field.dart';
import 'package:mytraveljournal/services/auth/auth_service.dart';
import '../constants/color_constants.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  late final TextEditingController _email;

  @override
  void initState() {
    _email = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  height: 600,
                  width: 370,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      color: Colors.white24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 100,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image(image: AssetImage('assets/Logo.png')),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(30.0),
                        child: Text(
                          'Reset your password',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                            color: Color(0xbfC94747),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 50.0),
                        child: Text(
                          "Enter your email address",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.assetColorWhite,
                          ),
                        ),
                      ),
                      AuthInputField(
                        textController: _email,
                        hintText: 'Enter your email here',
                        obscureText: false,
                        labelText: 'Email',
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                await AuthService.firebase()
                                    .sendForgotPasswordEmail(
                                        email: _email.text);
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Email sent!'),
                                      content: Text(
                                          "Password reset request sent to ${_email.text}"),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('OK'))
                                      ],
                                    );
                                  },
                                );
                                context.go('/sign-in');
                              },
                              style: ButtonStyle(
                                minimumSize: MaterialStateProperty.all(
                                  const Size(100, 60),
                                ),
                                backgroundColor: MaterialStateColor.resolveWith(
                                    (states) =>
                                        const Color.fromRGBO(182, 84, 84, 1)),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                elevation: MaterialStateProperty.all(3.0),
                              ),
                              child: const Text(
                                'RESET PASSWORD',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: ColorConstants.assetColorWhite,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: ElevatedButton(
                                onPressed: () async {
                                  context.go('/sign-in');
                                },
                                style: ButtonStyle(
                                  minimumSize: MaterialStateProperty.all(
                                    const Size(80, 40),
                                  ),
                                  backgroundColor:
                                      MaterialStateColor.resolveWith((states) =>
                                          const Color.fromRGBO(
                                              119, 102, 203, 0.984)),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  elevation: MaterialStateProperty.all(3.0),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: ColorConstants.assetColorWhite,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

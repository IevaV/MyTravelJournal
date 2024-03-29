import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/components/auth_components/auth_input_field.dart';
import 'package:mytraveljournal/constants/color_constants.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/services/auth/auth_exceptions.dart';
import 'package:mytraveljournal/services/auth/auth_service.dart';
import 'package:mytraveljournal/services/auth/auth_user.dart';
import 'package:mytraveljournal/services/firestore/user/user_service.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  late final TextEditingController _username;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _passwordConfirm;
  bool isUsernameValid = false;
  dynamic usernameErrorMessage;
  dynamic usernameAvailable;
  TextStyle usernameAvailabilityStyle = const TextStyle();
  RegExp usernameRegex = RegExp(r'^[a-z]{1}(_?[a-z0-9]+)*$');
  UserService userService = getIt<UserService>();

  @override
  void initState() {
    _username = TextEditingController();
    _email = TextEditingController();
    _password = TextEditingController();
    _passwordConfirm = TextEditingController();
    userService.listenToUserNames();
    super.initState();
  }

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  // Validates user input for username field
  void usernameValidation(String username) {
    if (username.length < 4) {
      setState(() {
        usernameAvailable = null;
        usernameErrorMessage = 'Username must be at least 4 characters long';
        isUsernameValid = false;
      });
      // TODO add dynamic error messages for incorrect username input
    } else if (!usernameRegex.hasMatch(username)) {
      setState(() {
        usernameAvailable = null;
        usernameErrorMessage = "Username doesn't match allowed formatting";
        isUsernameValid = false;
      });
    } else if (userService.allUsernameList.contains(username)) {
      setState(() {
        usernameAvailable = null;
        usernameErrorMessage = 'username is taken';
        isUsernameValid = false;
      });
    } else {
      setState(() {
        usernameAvailable = 'username is available';
        usernameErrorMessage = null;
        isUsernameValid = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: ColorConstants.primaryYellow,
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _username,
                    enableSuggestions: false,
                    autocorrect: false,
                    maxLength: 30,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'\w')),
                    ],
                    onChanged: (usernameInputText) {
                      usernameInputText = usernameInputText.toLowerCase();
                      _username.value = TextEditingValue(
                        text: usernameInputText,
                        selection: _username.selection,
                      );
                      usernameValidation(usernameInputText);
                    },
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username here',
                      labelStyle: const TextStyle(color: Colors.black),
                      helperText: usernameAvailable,
                      helperStyle: const TextStyle(
                        color: Colors.green,
                      ),
                      errorText: usernameErrorMessage,
                      filled: true,
                      fillColor: ColorConstants.yellowPlaceholderBackground,
                    ),
                  ),
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
              flex: 1,
              child: Column(
                children: [
                  TextButton(
                    onPressed: () async {
                      if (!isUsernameValid) {
                        return showErrorDialog(context, 'Invalid username');
                      }
                      final username = _username.text;
                      final email = _email.text;
                      final password = _password.text;
                      final passwordConfirm = _passwordConfirm.text;
                      if (password == passwordConfirm) {
                        try {
                          AuthUser user = await AuthService.firebase()
                              .createUser(email: email, password: password);
                          AuthService.firebase().sendEmailVerification();
                          userService.addUsername(username, user.uid);
                          userService.addUser(username, user.uid);
                          userService.cancelListenToUsernames();
                          await userService.usernameListener.cancel();
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
                          userService.cancelListenToUsernames();
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

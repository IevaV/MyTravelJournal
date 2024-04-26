import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth/auth_service.dart';

class MyProfileView extends StatefulWidget {
  const MyProfileView({super.key});

  @override
  State<MyProfileView> createState() => _MyProfileViewState();
}

class _MyProfileViewState extends State<MyProfileView> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () {
          AuthService.firebase().logout();
          context.go('/welcome');
        },
        style: ButtonStyle(
          minimumSize: MaterialStateProperty.all(
            const Size(250, 50),
          ),
          backgroundColor: MaterialStateColor.resolveWith(
              (states) => const Color.fromRGBO(119, 102, 203, 1)),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          elevation: MaterialStateProperty.all(3.0),
        ),
        child: const Text(
          'LOG OUT',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}

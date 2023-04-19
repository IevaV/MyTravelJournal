import 'package:flutter/material.dart';
import 'package:mytraveljournal/services/auth/auth_service.dart';
import 'package:mytraveljournal/views/add_new_trip_view.dart';
import 'package:mytraveljournal/views/landing_view.dart';
import 'package:mytraveljournal/views/login_view.dart';
import 'package:mytraveljournal/views/register_view.dart';
import 'package:mytraveljournal/views/trip_memory_view.dart';
import 'package:mytraveljournal/views/verify_email_view.dart';
import 'package:mytraveljournal/views/welcome_view.dart';

import 'constants/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      routes: {
        welcomeRoute: (context) => const WelcomeView(),
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        verifyEmailRoute: (context) => const VerifyEmailView(),
        landingRoute: (context) => const LandingView(),
        addNewTripRoute: (context) => const AddNewTripView(),
        // tripMemoryRoute: (context) => const TripMemoryView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.firebase().initialize(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = AuthService.firebase().currentUser;
            if (user != null) {
              if (user.isEmailVerified) {
                return const LandingView();
              } else {
                return const VerifyEmailView();
              }
            } else {
              return const WelcomeView();
            }
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/services/auth/auth_service.dart';
import 'package:mytraveljournal/views/add_new_trip_view.dart';
import 'package:mytraveljournal/views/home_view.dart';
import 'package:mytraveljournal/views/landing_view.dart';
import 'package:mytraveljournal/views/login_view.dart';
import 'package:mytraveljournal/views/register_view.dart';
import 'package:mytraveljournal/views/trip_memory_view.dart';
import 'package:mytraveljournal/views/verify_email_view.dart';
import 'package:mytraveljournal/views/welcome_view.dart';
import 'constants/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final String initRoute;
  await AuthService.firebase().initialize();
  final user = AuthService.firebase().currentUser;
  if (user != null) {
    if (user.isEmailVerified) {
      initRoute = '/home';
    } else {
      initRoute = '/verifyEmail';
    }
  } else {
    initRoute = '/welcome';
  }
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellNavigatorKey = GlobalKey<NavigatorState>();

  /// The route configuration.
  final GoRouter router = GoRouter(
    initialLocation: initRoute,
    navigatorKey: rootNavigatorKey,
    routes: [
      ShellRoute(
          navigatorKey: shellNavigatorKey,
          routes: [
            GoRoute(
              parentNavigatorKey: shellNavigatorKey,
              path: '/home',
              builder: (context, state) => const HomeView(),
            ),
          ],
          builder: (context, state, child) {
            return BottomNavigationBarScaffold(child: child);
          }),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/welcome',
        builder: (context, state) => const WelcomeView(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/verifyEmail',
        builder: (context, state) => const VerifyEmailView(),
      ),
    ],
  );

  runApp(
    MaterialApp.router(
      routerConfig: router,
    ),
  );
}

class BottomNavigationBarScaffold extends StatefulWidget {
  const BottomNavigationBarScaffold({super.key, this.child});

  final Widget? child;

  @override
  State<BottomNavigationBarScaffold> createState() =>
      _BottomNavigationBarScaffoldState();
}

class _BottomNavigationBarScaffoldState
    extends State<BottomNavigationBarScaffold> {
  int currentIndex = 0;

  void changeTab(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/profile');
        break;
      default:
        context.go('/home');
        break;
    }
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
        selectedIndex: currentIndex,
        onDestinationSelected: (int index) {
          changeTab(index);
        },
      ),
    );
  }
}

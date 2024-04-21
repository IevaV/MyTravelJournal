import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/auth/auth_service.dart';
import 'package:mytraveljournal/views/future_trips/future_trips_view.dart';
import 'package:mytraveljournal/views/future_trips/add_future_trip_view.dart';
import 'package:mytraveljournal/views/future_trips/plan_future_trip_day_view.dart';
import 'package:mytraveljournal/views/future_trips/plan_future_trip_view.dart';
import 'package:mytraveljournal/views/home_view.dart';
import 'package:mytraveljournal/views/ongoing_trip_view.dart';
import 'package:mytraveljournal/views/sign_in_view.dart';
import 'package:mytraveljournal/views/my_profile_view.dart';
import 'package:mytraveljournal/views/sign_up_view.dart';
import 'package:mytraveljournal/views/verify_email_view.dart';
import 'package:mytraveljournal/views/welcome_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeLocators();
  final String initRoute;
  await AuthService.firebase().initialize();
  final user = AuthService.firebase().currentUser;
  if (user != null) {
    await getIt<User>().assignUserData(user.uid);
    if (user.isEmailVerified) {
      initRoute = '/home';
    } else {
      initRoute = '/verify-email';
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
              builder: (context, state) => HomeView(),
            ),
            GoRoute(
              parentNavigatorKey: shellNavigatorKey,
              path: '/plan',
              builder: (context, state) => const FutureTripsView(),
            ),
            GoRoute(
              parentNavigatorKey: shellNavigatorKey,
              path: '/profile',
              builder: (context, state) => const MyProfileView(),
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
        path: '/sign-in',
        builder: (context, state) => const SignInView(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/sign-up',
        builder: (context, state) => const SignUpView(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailView(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/add-future-trip',
        builder: (context, state) => const AddFutureTripView(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/plan-future-trip',
        builder: (context, state) {
          Trip trip = state.extra as Trip;
          return PlanFutureTripView(
            trip: trip,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/plan-future-trip-day',
        builder: (context, state) {
          TripDay tripDay = state.extra as TripDay;
          return PlanFutureTripDayView(
            tripId: state.uri.queryParameters['tripId']!,
            tripDay: tripDay,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/ongoing-trip',
        builder: (context, state) {
          Trip trip = state.extra as Trip;
          return OngoingTripView(
            trip: trip,
          );
        },
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
        context.go('/plan');
        break;
      case 2:
        context.go('/memories');
        break;
      case 3:
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
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_location_alt),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories),
            label: 'Memories',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
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

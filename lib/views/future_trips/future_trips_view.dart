import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FutureTripsView extends StatelessWidget {
  const FutureTripsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                  onPressed: () =>
                      {GoRouter.of(context).push('/add-future-trip')},
                  child: const Text('Plan new trip')),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/color_constants.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.primaryYellow,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("You don't have any trips yet!"),
              FilledButton(
                  onPressed: () =>
                      {GoRouter.of(context).push('/add-future-trip')},
                  child: const Text('Plan your first trip!')),
            ],
          ),
        ),
      ),
    );
  }
}
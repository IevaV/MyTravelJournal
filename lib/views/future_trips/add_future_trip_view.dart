import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/components/ui_components/date_picker.dart';
import 'dart:developer' as devtools show log;

class AddFutureTripView extends StatefulWidget {
  const AddFutureTripView({super.key});

  @override
  State<AddFutureTripView> createState() => _AddFutureTripViewState();
}

class _AddFutureTripViewState extends State<AddFutureTripView> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _date;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _description = TextEditingController();
    _date = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _title.dispose();
    _description.dispose();
    _date.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: DatePicker(
                  textController: _date,
                ),
              ),
              FilledButton(
                  onPressed: () {
                    GoRouter.of(context).pop();
                  },
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => {
                        //context.go('/plan-trip')
                        devtools.log('Trip created')
                      },
                  child: const Text('Next')),
            ],
          ),
        ),
      ),
    );
  }
}

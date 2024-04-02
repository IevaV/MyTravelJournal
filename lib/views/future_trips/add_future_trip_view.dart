import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mytraveljournal/components/dialog_components/show_error_dialog.dart';
import 'package:mytraveljournal/components/ui_components/date_picker.dart';
import 'package:mytraveljournal/locator.dart';
import 'package:mytraveljournal/models/trip.dart';
import 'package:mytraveljournal/models/trip_day.dart';
import 'package:mytraveljournal/models/user.dart';
import 'package:mytraveljournal/services/firestore/trip/trip_service.dart';

class AddFutureTripView extends StatefulWidget {
  const AddFutureTripView({super.key});

  @override
  State<AddFutureTripView> createState() => _AddFutureTripViewState();
}

class _AddFutureTripViewState extends State<AddFutureTripView> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _date;
  final Map<String, DateTimeRange?> selectedDates = {};
  bool _validateTitleInput = false;
  bool _validateDescriptionInput = false;
  bool _validateDateInput = false;

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
    TripService tripService = getIt<TripService>();
    User user = getIt<User>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create New Trip'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: const OutlineInputBorder(),
                    errorText:
                        _validateTitleInput ? "Title can't be empty" : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: _description,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: const OutlineInputBorder(),
                    errorText: _validateDescriptionInput
                        ? "Description can't be empty"
                        : null,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: DatePicker(
                  textController: _date,
                  pickedDates: selectedDates,
                  validateSelectedDates: _validateDateInput,
                ),
              ),
              FilledButton(
                  onPressed: () {
                    GoRouter.of(context).pop();
                  },
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  setState(() {
                    _validateTitleInput = _title.text.isEmpty;
                    _validateDescriptionInput = _description.text.isEmpty;
                    _validateDateInput = selectedDates['dates'] == null;
                  });

                  if (!_validateTitleInput &&
                      !_validateDescriptionInput &&
                      !_validateDateInput) {
                    try {
                      await tripService.batchUpdateAfterAddingNewTrip(
                        user.uid,
                        _title.text,
                        _description.text,
                        selectedDates['dates']!.start,
                        selectedDates['dates']!.end,
                      );
                      Trip trip = await tripService.getLatestUserTrip(user.uid);
                      context.push('/plan-future-trip', extra: trip);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('New trip added'),
                        ),
                      );
                    } catch (e) {
                      print(e);
                      await showErrorDialog(context,
                          'Something went wrong, please try again later');
                    }
                  }
                },
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

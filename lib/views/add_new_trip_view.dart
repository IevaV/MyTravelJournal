import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../components/auth_components/auth_input_field.dart';
import '../constants/color_constants.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as devtools show log;

class AddNewTripView extends StatefulWidget {
  const AddNewTripView({super.key});

  @override
  State<AddNewTripView> createState() => _AddNewTripViewState();
}

class _AddNewTripViewState extends State<AddNewTripView> {
  // late GoogleMapController mapController;

  // final LatLng _center = const LatLng(45.521563, -122.677433);

  // void _onMapCreated(GoogleMapController controller) {
  //   mapController = controller;
  // }

  late final TextEditingController _title;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;

  @override
  void initState() {
    _title = TextEditingController();
    _startDateController = TextEditingController(
        text: DateFormat('d-MM-yyyy').format(DateTime.now()));
    _endDateController = TextEditingController(
        text: DateFormat('d-MM-yyyy').format(DateTime.now()));
    super.initState();
  }

  @override
  void dispose() {
    _title.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  DateTime selectedDate = DateUtils.dateOnly(DateTime.now());
  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        String date = DateFormat('d-MM-yyyy').format(selectedDate);
        _startDateController.text = date;
      });
    }
  }

  DateTime selectedEndDate = DateUtils.dateOnly(DateTime.now());
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedEndDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedEndDate) {
      setState(() {
        selectedEndDate = picked;
        String date = DateFormat('d-MM-yyyy').format(selectedEndDate);
        _endDateController.text = date;
      });
    }
  }

  int daysBetween(DateTime from, DateTime to) {
    devtools.log(from.toString());
    devtools.log(to.toString());
    return to.difference(from).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'PLAN YOUR TRIP',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.assetColorWhite,
                ),
              ),
            ],
          ),
        ),
        Flexible(
          flex: 2,
          child: Center(
            child: AuthInputField(
              textController: _title,
              hintText: 'Enter your Title',
              obscureText: false,
            ),
          ),
        ),
        Flexible(
          flex: 2,
          child: Row(
            children: [
              Flexible(
                flex: 1,
                child: Column(
                  children: [
                    const Flexible(
                      flex: 1,
                      child: Text('Start date'),
                    ),
                    Flexible(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 10),
                        child: PhysicalModel(
                          borderRadius: BorderRadius.circular(50),
                          color: ColorConstants.primaryYellow,
                          elevation: 5.0,
                          shadowColor: ColorConstants.assetColorBlack,
                          child: TextField(
                            controller: _startDateController,
                            enableSuggestions: false,
                            autocorrect: false,
                            readOnly: true,
                            onTap: () {
                              _selectStartDate(context);
                            },
                            decoration: InputDecoration(
                              suffixIcon: const Icon(Icons.date_range),
                              hintStyle: const TextStyle(
                                color: ColorConstants.turquoisePlaceholderText,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor:
                                  ColorConstants.yellowPlaceholderBackground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 1,
                child: Column(
                  children: [
                    const Flexible(
                      flex: 1,
                      child: Text('End date'),
                    ),
                    Flexible(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 10),
                        child: PhysicalModel(
                          borderRadius: BorderRadius.circular(50),
                          color: ColorConstants.primaryYellow,
                          elevation: 5.0,
                          shadowColor: ColorConstants.assetColorBlack,
                          child: TextField(
                            controller: _endDateController,
                            enableSuggestions: false,
                            autocorrect: false,
                            readOnly: true,
                            onTap: () {
                              _selectEndDate(context);
                            },
                            decoration: InputDecoration(
                              suffixIcon: const Icon(Icons.date_range),
                              hintStyle: const TextStyle(
                                color: ColorConstants.turquoisePlaceholderText,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor:
                                  ColorConstants.yellowPlaceholderBackground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Flexible(
          flex: 3,
          child: ListView.builder(
            itemCount: daysBetween(selectedDate, selectedEndDate),
            itemBuilder: (ctx, index) => ListTile(
              tileColor: ColorConstants.primaryTurquoise,
              title: Text('$index '),
              onTap: () {
//              myModelsListWrapper.editModelNumber(index, -1);
                devtools.log("Something happens");
                //or do any other action you want
              },
            ),
          ),
          // child: ListView(
          //   children: [
          //     if (!selectedEndDate.isAtSameMomentAs(DateTime.now()))
          //       for (int i = 0;
          //           i < daysBetween(selectedDate, selectedEndDate);
          //           i++)
          //         Padding(
          //           padding: const EdgeInsets.all(8.0),
          //           child: SizedBox(
          //             height: 100,
          //             child: Card(
          //               elevation: 15,
          //               shape: RoundedRectangleBorder(
          //                 borderRadius: BorderRadiusDirectional.circular(20),
          //               ),
          //               clipBehavior: Clip.hardEdge,
          //               child: InkWell(
          //                 splashColor: ColorConstants.primaryTurquoise,
          //                 onTap: () {
          //                   debugPrint('Card tapped.');
          //                 },
          //                 child: Container(
          //                   decoration: BoxDecoration(
          //                     border: Border.all(
          //                       color: ColorConstants.primaryTurquoise,
          //                       width: 5,
          //                     ),
          //                     borderRadius: const BorderRadius.all(
          //                       Radius.circular(20),
          //                     ),
          //                   ),
          //                   child: Text('$i test'),
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ),
          //   ],
          // ),
        ),
      ],
    );
  }
}

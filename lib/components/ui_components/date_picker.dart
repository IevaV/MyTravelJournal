import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class DatePicker extends StatelessWidget {
  const DatePicker(
      {super.key, required this.textController, required this.pickedDates});
  final TextEditingController textController;
  final Map<String, dynamic> pickedDates;

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      keyboardType: TextInputType.text,
      firstDate: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      textController.text =
          "${picked.start.day}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.year} - ${picked.end.day}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.year}";
      pickedDates['dates'] = picked;
      // pickedDates['endDate'] = picked.end.toString();
    }
    devtools.log(picked.toString());
    devtools.log(picked!.start.toString());
    devtools.log(picked.end.toString());
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textController,
      readOnly: true,
      onTap: () {
        _selectStartDate(context);
      },
      decoration: const InputDecoration(
        labelText: 'Start Date - End Date',
        border: OutlineInputBorder(),
      ),
    );
  }
}

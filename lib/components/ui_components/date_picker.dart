import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

class DatePicker extends StatelessWidget {
  const DatePicker({super.key, required this.textController});
  final TextEditingController textController;

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      //TODO provide keyboardType after Flutter update
      //keyboardType: TextInputType.text,
      firstDate: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked != null) {
      textController.text = picked.toString();
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

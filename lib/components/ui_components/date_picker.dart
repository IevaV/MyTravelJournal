import 'package:flutter/material.dart';

class DatePicker extends StatelessWidget {
  const DatePicker(
      {super.key,
      required this.textController,
      required this.pickedDates,
      required this.validateSelectedDates,
      required this.textFieldErrorMessage,
      this.firstDate});
  final TextEditingController textController;
  final Map<String, dynamic> pickedDates;
  final bool validateSelectedDates;
  final String textFieldErrorMessage;
  final DateTime? firstDate;

  Future<void> _selectTripDates(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      keyboardType: TextInputType.text,
      firstDate: firstDate == null
          ? DateTime(
              DateTime.now().year, DateTime.now().month, DateTime.now().day)
          : firstDate!,
      lastDate: DateTime(DateTime.now().year + 25),
    );
    if (picked != null) {
      textController.text =
          "${picked.start.day}-${picked.start.month.toString().padLeft(2, '0')}-${picked.start.year} - ${picked.end.day}-${picked.end.month.toString().padLeft(2, '0')}-${picked.end.year}";
      pickedDates['dates'] = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textController,
      readOnly: true,
      onTap: () {
        _selectTripDates(context);
      },
      decoration: InputDecoration(
        suffixIcon: const Icon(Icons.calendar_month),
        filled: true,
        fillColor: Colors.white54,
        hintText: 'Start Date - End Date',
        border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(40.0)),
        errorText: validateSelectedDates ? textFieldErrorMessage : null,
      ),
    );
  }
}

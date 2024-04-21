extension DateComparison on DateTime {
  bool isSameDate(DateTime dateTime) {
    return day == dateTime.day &&
        month == dateTime.month &&
        year == dateTime.year;
  }
}

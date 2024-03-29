int daysBetween(String start, String end) {
  DateTime parsedStartDate = DateTime.parse(start);
  DateTime parsedEndDate = DateTime.parse(end);

  return (parsedEndDate.difference(parsedStartDate).inHours / 24).round();
}

List<DateTime> datesBetween(DateTime start, DateTime end) {
  List<DateTime> days = [];
  for (var i = 0;
      i < (end.difference(start).inHours / 24).round() + 1;
      i++) {
    days.add(DateTime(
      start.year,
      start.month,
      start.day + i,
    ));
  }

  return days;
}

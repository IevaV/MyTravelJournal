int daysBetween(DateTime start, DateTime end) {
  return start.difference(end).inHours ~/ 24;
}

List<DateTime> datesBetween(DateTime start, DateTime end) {
  List<DateTime> days = [];
  for (var i = 0; i < (end.difference(start).inHours / 24).round() + 1; i++) {
    days.add(DateTime(
      start.year,
      start.month,
      start.day + i,
    ));
  }

  return days;
}

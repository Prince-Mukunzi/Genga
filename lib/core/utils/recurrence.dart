DateTime nextOccurrence(DateTime start, String recurrence, {DateTime? after}) {
  final now = after ?? DateTime.now();
  var step = 0;
  var next = start;
  while (!next.isAfter(now)) {
    step++;
    next = switch (recurrence) {
      'daily' => _addDays(start, step),
      'weekly' => _addDays(start, step * 7),
      'monthly' => _addMonths(start, step),
      'yearly' => _addMonths(start, step * 12),
      _ => _addDays(start, step * 30),
    };
  }
  return next;
}

DateTime _addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days, d.hour, d.minute);

// Clamps to the month's last day so a bill on the 31st stays at month end
// instead of drifting into the next month.
DateTime _addMonths(DateTime d, int months) {
  final firstOfTarget = DateTime(d.year, d.month + months);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  final day = d.day > lastDay ? lastDay : d.day;
  return DateTime(
    firstOfTarget.year,
    firstOfTarget.month,
    day,
    d.hour,
    d.minute,
  );
}

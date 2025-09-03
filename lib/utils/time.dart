String dateTimeToString(DateTime time) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');

  final year = time.year.toString();
  final month = twoDigits(time.month);
  final day = twoDigits(time.day);
  final hour = twoDigits(time.hour);
  final minute = twoDigits(time.minute);
  final second = twoDigits(time.second);

  return '$year-$month-$day $hour:$minute:$second';
}
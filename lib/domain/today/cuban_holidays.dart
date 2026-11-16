// Cuba's public holidays, computed offline.

/// Easter Sunday for [year] (anonymous Gregorian algorithm).
DateTime easterSunday(int year) {
  final a = year % 19;
  final b = year ~/ 100;
  final c = year % 100;
  final d = b ~/ 4;
  final e = b % 4;
  final f = (b + 8) ~/ 25;
  final g = (b - f + 1) ~/ 3;
  final h = (19 * a + b - d - g + 15) % 30;
  final i = c ~/ 4;
  final k = c % 4;
  final l = (32 + 2 * e + 2 * i - h - k) % 7;
  final m = (a + 11 * h + 22 * l) ~/ 451;
  final month = (h + l - 7 * m + 114) ~/ 31;
  final day = (h + l - 7 * m + 114) % 31 + 1;
  return DateTime(year, month, day);
}

const _fixedHolidays = <(int, int), String>{
  (1, 1): 'Día de la Liberación',
  (1, 2): 'Día de la Victoria',
  (5, 1): 'Día de los Trabajadores',
  (7, 25): 'Día de la Rebeldía Nacional',
  (7, 26): 'Día de la Rebeldía Nacional',
  (7, 27): 'Día de la Rebeldía Nacional',
  (10, 10): 'Día de la Independencia',
  (12, 25): 'Navidad',
  (12, 31): 'Fin de Año',
};

/// Spanish name of the Cuban public holiday on [date], or null.
String? cubanHolidayName(DateTime date) {
  final fixed = _fixedHolidays[(date.month, date.day)];
  if (fixed != null) return fixed;
  final easter = easterSunday(date.year);
  final goodFriday = DateTime(easter.year, easter.month, easter.day - 2);
  if (date.month == goodFriday.month && date.day == goodFriday.day) {
    return 'Viernes Santo';
  }
  return null;
}

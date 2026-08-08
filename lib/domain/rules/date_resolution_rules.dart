import 'package:my_first_app/core/constants/enums.dart';

/// Deterministic resolution of relative date phrases → calendar dates.
///
/// Pure functions — no I/O. Anchor is always [Memory.createdAt] (or the same
/// instant used as `createdAt` on a live save). Never wall-clock "now" for
/// backfill, or historical phrases shift forward.

/// Resolves a relative [rawPhrase] against [anchorDate].
///
/// Returns a date-only [DateTime] (time zeroed) on success, or `null` when the
/// phrase does not match a known pattern (fail safe — do not guess).
DateTime? resolveRelativeDate({
  required String rawPhrase,
  required DateTime anchorDate,
}) {
  final phrase = _normalizePhrase(rawPhrase);
  if (phrase.isEmpty) return null;

  final anchor = _dateOnly(anchorDate);

  switch (phrase) {
    case 'today':
      return anchor;
    case 'yesterday':
      return anchor.subtract(const Duration(days: 1));
    case 'tomorrow':
      return anchor.add(const Duration(days: 1));
    case 'next week':
      return anchor.add(const Duration(days: 7));
    case 'last week':
      return anchor.subtract(const Duration(days: 7));
    case 'next month':
      return _addCalendarMonths(anchor, 1);
    case 'last month':
      return _addCalendarMonths(anchor, -1);
  }

  final nextWeekday = _nextWeekdayPattern.firstMatch(phrase);
  if (nextWeekday != null) {
    final weekday = _weekdayNameToDart(nextWeekday.group(1)!);
    if (weekday == null) return null;
    return _nextOccurrenceOfWeekday(anchor, weekday);
  }

  final inUnits = _inNUnitsPattern.firstMatch(phrase);
  if (inUnits != null) {
    final n = int.tryParse(inUnits.group(1)!);
    if (n == null || n < 0) return null;
    final unit = inUnits.group(2)!;
    if (unit.startsWith('day')) {
      return anchor.add(Duration(days: n));
    }
    if (unit.startsWith('week')) {
      return anchor.add(Duration(days: n * 7));
    }
    if (unit.startsWith('month')) {
      return _addCalendarMonths(anchor, n);
    }
  }

  return null;
}

/// Chooses the persisted [dateValue] for a Memory write.
///
/// When [datePrecision] is relative, resolves [dateValueRaw] against
/// [anchorDate]. Explicit dates pass through; none → null.
DateTime? resolveDateValueForPersistence({
  required DatePrecision datePrecision,
  required DateTime? dateValue,
  required String? dateValueRaw,
  required DateTime anchorDate,
}) {
  switch (datePrecision) {
    case DatePrecision.explicit:
      return dateValue;
    case DatePrecision.relative:
      final raw = dateValueRaw?.trim();
      if (raw == null || raw.isEmpty) return null;
      return resolveRelativeDate(rawPhrase: raw, anchorDate: anchorDate);
    case DatePrecision.none:
      return null;
  }
}

final RegExp _nextWeekdayPattern = RegExp(
  r'^next\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$',
);

final RegExp _inNUnitsPattern = RegExp(
  r'^in\s+(\d+)\s+(days?|weeks?|months?)$',
);

String _normalizePhrase(String raw) {
  var s = raw.trim().toLowerCase();
  // Strip trailing sentence punctuation commonly left by extractors.
  while (s.isNotEmpty &&
      (s.endsWith('.') || s.endsWith(',') || s.endsWith('!'))) {
    s = s.substring(0, s.length - 1).trimRight();
  }
  // Collapse internal whitespace.
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int? _weekdayNameToDart(String name) {
  switch (name) {
    case 'monday':
      return DateTime.monday;
    case 'tuesday':
      return DateTime.tuesday;
    case 'wednesday':
      return DateTime.wednesday;
    case 'thursday':
      return DateTime.thursday;
    case 'friday':
      return DateTime.friday;
    case 'saturday':
      return DateTime.saturday;
    case 'sunday':
      return DateTime.sunday;
    default:
      return null;
  }
}

/// Next occurrence of [weekday] strictly after [anchor] (never "today").
DateTime _nextOccurrenceOfWeekday(DateTime anchor, int weekday) {
  var daysAhead = (weekday - anchor.weekday) % 7;
  if (daysAhead == 0) daysAhead = 7;
  return anchor.add(Duration(days: daysAhead));
}

DateTime _addCalendarMonths(DateTime date, int months) {
  final totalMonths = date.year * 12 + (date.month - 1) + months;
  final year = totalMonths ~/ 12;
  final month = (totalMonths % 12) + 1;
  final day = date.day.clamp(1, _daysInMonth(year, month));
  return DateTime(year, month, day);
}

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

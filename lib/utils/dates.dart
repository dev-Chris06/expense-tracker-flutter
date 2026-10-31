/// Petites fonctions autour des dates, stockées au format ISO "YYYY-MM-DD".
library;

String _two(int value) => value.toString().padLeft(2, '0');

/// Convertit une date en chaîne ISO "YYYY-MM-DD" (heure locale, pas UTC).
String toIsoDate(DateTime date) => '${date.year}-${_two(date.month)}-${_two(date.day)}';

/// Date du jour au format ISO.
String todayIso() => toIsoDate(DateTime.now());

/// "2026-08-02" → "02/08/2026".
String formatDisplayDate(String isoDate) {
  final parts = isoDate.split('-');
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

/// Vérifie qu'une chaîne est une date ISO valide ("2026-02-31" est refusée :
/// DateTime la transformerait silencieusement en 3 mars).
bool isValidIsoDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  return toIsoDate(parseIsoDate(value)) == value;
}

/// "2026-08-02" → DateTime locale du 2 août 2026.
DateTime parseIsoDate(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

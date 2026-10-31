/// Utilitaires autour des mois, manipulés sous la forme "YYYY-MM"
/// (le préfixe des dates ISO stockées en base).
library;

const _monthNames = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

/// Mois d'une date locale : 31/10/2026 → "2026-10".
String monthKey([DateTime? date]) {
  final d = date ?? DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}';
}

/// Décale un mois : shiftMonth("2026-01", -1) → "2025-12".
String shiftMonth(String month, int delta) {
  final parts = month.split('-').map(int.parse).toList();
  return monthKey(DateTime(parts[0], parts[1] + delta));
}

/// "2026-10" → "Octobre 2026".
String formatMonthLabel(String month) {
  final parts = month.split('-').map(int.parse).toList();
  return '${_monthNames[parts[1] - 1]} ${parts[0]}';
}

/// Part d'un total en pourcentage entier, 0 si le total est nul.
int percentOf(int value, int total) => total > 0 ? (value / total * 100).round() : 0;

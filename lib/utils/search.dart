import '../models/expense.dart';
import 'dates.dart';

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
  'ç': 'c',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i',
  'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
  'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
  'ÿ': 'y', 'ñ': 'n', 'œ': 'oe', 'æ': 'ae',
};

/// Prépare un texte pour la comparaison : minuscules, sans accents et sans
/// espaces. Ainsi « etudes » trouve « Études » et « 1 500 » trouve 1500.
String normalizeForSearch(String value) {
  final lower = value.toLowerCase().replaceAll(RegExp(r'[\s  ]'), '');
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}

/// Indique si une dépense correspond à la recherche. On compare aussi bien
/// les valeurs brutes que les formats affichés à l'écran (date JJ/MM/AAAA).
bool matchesQuery(Expense expense, String query) {
  final needle = normalizeForSearch(query);
  if (needle.isEmpty) return true;
  final fields = [
    expense.categorie.label,
    expense.note ?? '',
    expense.date,
    formatDisplayDate(expense.date),
    expense.montant.toString(),
  ];
  return fields.any((field) => normalizeForSearch(field).contains(needle));
}

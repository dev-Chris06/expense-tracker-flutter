import 'category.dart';

/// Les données nécessaires pour créer ou mettre à jour une dépense.
/// Pas d'id : il est généré par SQLite à l'insertion.
class ExpenseInput {
  const ExpenseInput({
    required this.montant,
    required this.categorie,
    required this.date,
    this.note,
  });

  /// Montant entier en FCFA.
  final int montant;
  final ExpenseCategory categorie;

  /// Date au format ISO "YYYY-MM-DD".
  final String date;

  /// Note optionnelle (null si absente).
  final String? note;

  ExpenseInput copyWith({String? note}) =>
      ExpenseInput(montant: montant, categorie: categorie, date: date, note: note);

  Map<String, Object?> toRow() => {
        'montant': montant,
        'categorie': categorie.label,
        'date': date,
        'note': note,
      };

  @override
  bool operator ==(Object other) =>
      other is ExpenseInput &&
      other.montant == montant &&
      other.categorie == categorie &&
      other.date == date &&
      other.note == note;

  @override
  int get hashCode => Object.hash(montant, categorie, date, note);
}

/// Une dépense telle que stockée en base (avec son id auto-généré).
class Expense extends ExpenseInput {
  const Expense({
    required this.id,
    required super.montant,
    required super.categorie,
    required super.date,
    super.note,
  });

  final int id;

  factory Expense.fromRow(Map<String, Object?> row) => Expense(
        id: row['id'] as int,
        montant: row['montant'] as int,
        categorie: ExpenseCategory.fromLabel(row['categorie'] as String),
        date: row['date'] as String,
        note: row['note'] as String?,
      );
}

import '../models/category.dart';
import '../models/expense.dart';
import 'dates.dart';

/// Plafond de saisie : au-delà, c'est presque sûrement une faute de frappe.
const maxAmount = 999999999;

/// Convertit la saisie en montant entier de FCFA, ou null si invalide.
/// Les espaces (y compris insécables, comme dans « 1 500 ») sont ignorés.
int? parseAmount(String value) {
  final normalized = value.replaceAll(RegExp(r'[\s  ]'), '');
  if (!RegExp(r'^\d+$').hasMatch(normalized)) return null;
  final amount = int.tryParse(normalized);
  return amount != null && amount > 0 && amount <= maxAmount ? amount : null;
}

/// Résultat de validation : soit [error], soit [value].
class ValidationResult {
  const ValidationResult.error(String this.error) : value = null;
  const ValidationResult.ok(ExpenseInput this.value) : error = null;

  final String? error;
  final ExpenseInput? value;
}

ValidationResult validateExpenseInput(String amountText, ExpenseCategory? category, String date) {
  final amount = parseAmount(amountText);
  if (amount == null) {
    return const ValidationResult.error('Saisis un montant entier positif en FCFA (ex. 1 500).');
  }
  if (category == null) return const ValidationResult.error('Choisis une catégorie.');
  if (!isValidIsoDate(date)) return const ValidationResult.error('Choisis une date valide.');
  return ValidationResult.ok(ExpenseInput(montant: amount, categorie: category, date: date));
}

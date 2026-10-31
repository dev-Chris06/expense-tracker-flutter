import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/utils/dates.dart';
import 'package:expense_tracker/utils/formatters.dart';
import 'package:expense_tracker/utils/months.dart';
import 'package:expense_tracker/utils/search.dart';
import 'package:expense_tracker/utils/validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validation', () {
    test('accepts whole FCFA amounts, with spaces', () {
      expect(parseAmount('1500'), 1500);
      expect(parseAmount('1 500'), 1500);
      expect(parseAmount('1 500'), 1500);
      expect(parseAmount('  25 000 '), 25000);
    });

    for (final value in ['', '0', '-3', '12,5', '1.5', 'Infinity', '0x10', 'abc', '${maxAmount + 1}']) {
      test('rejects invalid amount "$value"', () => expect(parseAmount(value), isNull));
    }

    test('requires category and real ISO date', () {
      expect(validateExpenseInput('10', null, '2026-10-26').error, 'Choisis une catégorie.');
      expect(validateExpenseInput('10', ExpenseCategory.autre, '2026-02-31').error,
          'Choisis une date valide.');
    });

    test('returns normalized input when valid', () {
      final result = validateExpenseInput('1 500', ExpenseCategory.transport, '2026-10-26');
      expect(result.error, isNull);
      expect(
        result.value,
        const ExpenseInput(montant: 1500, categorie: ExpenseCategory.transport, date: '2026-10-26'),
      );
    });
  });

  group('formatters', () {
    test('formats amounts with non-breaking thousands separators', () {
      expect(formatAmount(0), '0 FCFA');
      expect(formatAmount(1500), '1 500 FCFA');
      expect(formatAmount(1234567), '1 234 567 FCFA');
    });

    test('pluralizes operation counts', () {
      expect(formatCount(0), '0 opération');
      expect(formatCount(1), '1 opération');
      expect(formatCount(2), '2 opérations');
    });
  });

  group('dates', () {
    test('formats and validates ISO dates', () {
      expect(formatDisplayDate('2026-08-02'), '02/08/2026');
      expect(toIsoDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(isValidIsoDate('2024-02-29'), isTrue);
      expect(isValidIsoDate('2026-02-29'), isFalse);
      expect(isValidIsoDate('2026-8-2'), isFalse);
    });
  });

  group('months', () {
    test('builds, shifts and labels month keys', () {
      expect(monthKey(DateTime(2026, 10, 31)), '2026-10');
      expect(shiftMonth('2026-01', -1), '2025-12');
      expect(shiftMonth('2026-12', 1), '2027-01');
      expect(formatMonthLabel('2026-08'), 'Août 2026');
    });

    test('computes safe percentages', () {
      expect(percentOf(25, 100), 25);
      expect(percentOf(1, 3), 33);
      expect(percentOf(5, 0), 0);
    });
  });

  group('search', () {
    const expense = Expense(
      id: 1,
      montant: 1500,
      categorie: ExpenseCategory.etudes,
      date: '2026-08-02',
      note: 'Cahiers Déjà',
    );

    test('normalizes accents, case and spaces', () {
      expect(normalizeForSearch(' Études 1 500 '), 'etudes1500');
    });

    for (final query in ['', 'etudes', 'ÉTU', 'cahiers deja', '02/08', '2026-08', '1 500', '1500']) {
      test('matches "$query"', () => expect(matchesQuery(expense, query), isTrue));
    }

    for (final query in ['transport', '03/08', '2000']) {
      test('does not match "$query"', () => expect(matchesQuery(expense, query), isFalse));
    }
  });
}

import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/theme.dart';
import 'package:expense_tracker/utils/errors.dart';
import 'package:expense_tracker/widgets/expense_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpForm(
    WidgetTester tester,
    Future<void> Function(ExpenseInput) onSubmit, {
    Expense? initial,
  }) {
    return tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: ExpenseForm(initialExpense: initial, submitLabel: 'Enregistrer', onSubmit: onSubmit),
      ),
    ));
  }

  testWidgets('shows validation errors and does not submit', (tester) async {
    var submitted = false;
    await pumpForm(tester, (_) async => submitted = true);

    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(find.textContaining('montant entier positif'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('amount')), '1 500');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(find.text('Choisis une catégorie.'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('submits the normalized expense with trimmed note', (tester) async {
    ExpenseInput? value;
    await pumpForm(tester, (v) async => value = v);

    await tester.enterText(find.byKey(const Key('amount')), '1 500');
    await tester.tap(find.text('Transport'));
    await tester.enterText(find.byKey(const Key('note')), '  taxi  ');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();

    expect(value?.montant, 1500);
    expect(value?.categorie, ExpenseCategory.transport);
    expect(value?.note, 'taxi');
  });

  testWidgets('pre-fills an existing expense and shows user-facing errors', (tester) async {
    await pumpForm(
      tester,
      (_) async => throw const UserFacingError('Cette dépense n’existe plus.'),
      initial: const Expense(
          id: 3, montant: 2500, categorie: ExpenseCategory.sante, date: '2026-08-02', note: 'pharmacie'),
    );

    expect(find.text('2500'), findsOneWidget);
    expect(find.text('02/08/2026'), findsOneWidget);
    expect(find.text('pharmacie'), findsOneWidget);

    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    expect(find.text('Cette dépense n’existe plus.'), findsOneWidget);
  });
}

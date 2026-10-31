import 'package:expense_tracker/data/database.dart';
import 'package:expense_tracker/data/expense_repository.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tests sur une vraie base SQLite en mémoire (sqflite_common_ffi).
void main() {
  sqfliteFfiInit();
  late Database db;
  late ExpenseRepository repo;

  setUp(() async {
    db = await openExpenseDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    repo = ExpenseRepository(db);
  });

  tearDown(() => db.close());

  ExpenseInput input(int montant, ExpenseCategory categorie, String date, [String? note]) =>
      ExpenseInput(montant: montant, categorie: categorie, date: date, note: note);

  test('creates the latest schema with a date index', () async {
    expect(await db.getVersion(), databaseVersion);
    final columns = await db.rawQuery('PRAGMA table_info(expenses)');
    expect(columns.firstWhere((c) => c['name'] == 'montant')['type'], 'INTEGER');
    final indexes = await db.rawQuery('PRAGMA index_list(expenses)');
    expect(indexes.map((i) => i['name']), contains('idx_expenses_date'));
  });

  test('CRUD round trip, newest first', () async {
    final a = await repo.add(input(1500, ExpenseCategory.transport, '2026-10-01', 'taxi'));
    final b = await repo.add(input(800, ExpenseCategory.nourriture, '2026-10-02'));

    expect((await repo.getAll()).map((e) => e.id), [b, a]);
    expect((await repo.getLatest())!.id, b);
    expect((await repo.getById(a))!.note, 'taxi');

    expect(await repo.update(a, input(2000, ExpenseCategory.sante, '2026-10-01')), isTrue);
    expect((await repo.getById(a))!.montant, 2000);
    expect((await repo.getById(a))!.categorie, ExpenseCategory.sante);

    expect(await repo.delete(a), isTrue);
    expect(await repo.getById(a), isNull);
    expect(await repo.update(a, input(1, ExpenseCategory.autre, '2026-10-01')), isFalse);
    expect(await repo.delete(a), isFalse);
  });

  test('notifies listeners on writes', () async {
    var notifications = 0;
    repo.addListener(() => notifications++);
    final id = await repo.add(input(100, ExpenseCategory.autre, '2026-10-01'));
    await repo.update(id, input(200, ExpenseCategory.autre, '2026-10-01'));
    await repo.delete(id);
    expect(notifications, 3);
  });

  test('aggregates by month and category', () async {
    await repo.add(input(1000, ExpenseCategory.transport, '2026-10-01'));
    await repo.add(input(500, ExpenseCategory.transport, '2026-10-15'));
    await repo.add(input(3000, ExpenseCategory.logement, '2026-10-20'));
    await repo.add(input(700, ExpenseCategory.loisirs, '2026-09-30'));

    final summary = await repo.getMonthSummary('2026-10');
    expect([summary.total, summary.count], [4500, 3]);
    final empty = await repo.getMonthSummary('2026-11');
    expect([empty.total, empty.count], [0, 0]);

    final categories = await repo.getCategoryTotals('2026-10');
    expect(categories.map((c) => [c.categorie, c.total, c.count]), [
      [ExpenseCategory.logement, 3000, 1],
      [ExpenseCategory.transport, 1500, 2],
    ]);

    final months = await repo.getMonthlyTotals();
    expect(months.map((m) => [m.month, m.total]), [
      ['2026-10', 4500],
      ['2026-09', 700],
    ]);
  });

  test('database rejects invalid rows', () async {
    expect(
      () => db.rawInsert(
          "INSERT INTO expenses (montant, categorie, date) VALUES (10, 'Inconnue', '2026-10-01')"),
      throwsA(isA<DatabaseException>()),
    );
    expect(
      () => db.rawInsert(
          "INSERT INTO expenses (montant, categorie, date) VALUES (0, 'Autre', '2026-10-01')"),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('every category label is accepted by the CHECK constraint', () async {
    for (final category in ExpenseCategory.values) {
      await repo.add(input(1, category, '2026-10-01'));
    }
    expect((await repo.getAll()).length, ExpenseCategory.values.length);
  });
}

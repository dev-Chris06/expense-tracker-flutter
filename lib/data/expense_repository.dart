/// Accès à la table "expenses".
///
/// Toutes les requêtes utilisent des paramètres liés (les "?") : c'est la
/// protection standard contre l'injection SQL.
///
/// Le dépôt est un ChangeNotifier : chaque écriture prévient les écrans
/// qui l'écoutent, qui se rechargent alors (équivalent du useFocusEffect de
/// la version Expo).
library;

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/expense.dart';

class MonthSummary {
  const MonthSummary({required this.total, required this.count});

  final int total;
  final int count;
}

class CategoryTotal {
  const CategoryTotal({required this.categorie, required this.total, required this.count});

  final ExpenseCategory categorie;
  final int total;
  final int count;
}

class MonthTotal {
  const MonthTotal({required this.month, required this.total, required this.count});

  /// Mois au format "YYYY-MM".
  final String month;
  final int total;
  final int count;
}

class ExpenseRepository extends ChangeNotifier {
  ExpenseRepository(this._db);

  final Database _db;

  /// Insère une dépense et retourne son id généré.
  Future<int> add(ExpenseInput expense) async {
    final id = await _db.insert('expenses', expense.toRow());
    notifyListeners();
    return id;
  }

  /// Toutes les dépenses, les plus récentes d'abord (l'id départage un même jour).
  Future<List<Expense>> getAll() async {
    final rows = await _db.query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromRow).toList();
  }

  /// Une dépense par son id, ou null si elle n'existe pas.
  Future<Expense?> getById(int id) async {
    final rows = await _db.query('expenses', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Expense.fromRow(rows.first);
  }

  /// La dépense la plus récente, ou null si la table est vide.
  Future<Expense?> getLatest() async {
    final rows = await _db.query('expenses', orderBy: 'date DESC, id DESC', limit: 1);
    return rows.isEmpty ? null : Expense.fromRow(rows.first);
  }

  /// Met à jour une dépense. Retourne false si l'id n'existe plus
  /// (par exemple supprimée entre-temps).
  Future<bool> update(int id, ExpenseInput expense) async {
    final changes =
        await _db.update('expenses', expense.toRow(), where: 'id = ?', whereArgs: [id]);
    if (changes > 0) notifyListeners();
    return changes > 0;
  }

  /// Supprime une dépense. Retourne true si une ligne a bien été supprimée.
  Future<bool> delete(int id) async {
    final changes = await _db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    if (changes > 0) notifyListeners();
    return changes > 0;
  }

  /// Total et nombre de dépenses d'un mois ("YYYY-MM").
  Future<MonthSummary> getMonthSummary(String month) async {
    final rows = await _db.rawQuery(
      'SELECT COALESCE(SUM(montant), 0) AS total, COUNT(*) AS count '
      'FROM expenses WHERE substr(date, 1, 7) = ?',
      [month],
    );
    return MonthSummary(total: rows.first['total'] as int, count: rows.first['count'] as int);
  }

  /// Totaux par catégorie pour un mois, du plus gros au plus petit.
  Future<List<CategoryTotal>> getCategoryTotals(String month) async {
    final rows = await _db.rawQuery(
      'SELECT categorie, SUM(montant) AS total, COUNT(*) AS count '
      'FROM expenses WHERE substr(date, 1, 7) = ? '
      'GROUP BY categorie ORDER BY total DESC, categorie',
      [month],
    );
    return rows
        .map((r) => CategoryTotal(
              categorie: ExpenseCategory.fromLabel(r['categorie'] as String),
              total: r['total'] as int,
              count: r['count'] as int,
            ))
        .toList();
  }

  /// Totaux par mois (mois ayant au moins une dépense), du plus récent au plus ancien.
  Future<List<MonthTotal>> getMonthlyTotals({int limit = 12}) async {
    final rows = await _db.rawQuery(
      'SELECT substr(date, 1, 7) AS month, SUM(montant) AS total, COUNT(*) AS count '
      'FROM expenses GROUP BY month ORDER BY month DESC LIMIT ?',
      [limit],
    );
    return rows
        .map((r) => MonthTotal(
              month: r['month'] as String,
              total: r['total'] as int,
              count: r['count'] as int,
            ))
        .toList();
  }
}

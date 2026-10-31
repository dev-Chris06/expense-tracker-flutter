/// Ouverture de la base SQLite et migrations.
///
/// sqflite gère le numéro de version (PRAGMA user_version) : à l'ouverture,
/// il appelle onCreate pour une base neuve ou onUpgrade si la version
/// stockée est plus ancienne. Dans les deux cas on exécute les migrations
/// manquantes, dans une transaction.
///
/// Règle d'or : une migration publiée ne se modifie JAMAIS. Pour changer le
/// schéma (nouvelle colonne, nouvelle catégorie autorisée…), on ajoute une
/// entrée à la fin de [migrations]. C'est pour ça que la liste des
/// catégories est figée en dur ici au lieu d'être générée depuis l'enum.
///
/// Choix de types : montant INTEGER (le franc CFA n'a pas de centimes,
/// totaux exacts), categorie TEXT + CHECK, date TEXT ISO "YYYY-MM-DD" (se
/// trie en texte), note TEXT nullable.
library;

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Une migration = une liste d'instructions SQL (sqflite n'exécute qu'une
/// instruction par appel à `execute`).
const List<List<String>> migrations = [
  // v1 — schéma initial (équivalent du schéma v2 de la version Expo).
  [
    '''
    CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      montant INTEGER NOT NULL CHECK (montant > 0),
      categorie TEXT NOT NULL CHECK (categorie IN ('Nourriture', 'Transport', 'Communication', 'Logement', 'Études', 'Travail', 'Santé', 'Loisirs', 'Autre')),
      date TEXT NOT NULL,
      note TEXT
    )
    ''',
    'CREATE INDEX idx_expenses_date ON expenses (date)',
  ],
];

/// Version du schéma après application de toutes les migrations.
int get databaseVersion => migrations.length;

Future<void> _migrate(Database db, int from, int to) async {
  await db.transaction((txn) async {
    for (var version = from; version < to; version++) {
      for (final statement in migrations[version]) {
        await txn.execute(statement);
      }
    }
  });
}

/// Ouvre (et crée ou migre si besoin) la base des dépenses.
///
/// [factory] et [path] permettent aux tests d'utiliser une base en mémoire.
Future<Database> openExpenseDatabase({DatabaseFactory? factory, String? path}) async {
  final dbFactory = factory ?? databaseFactory;
  final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), 'expenses.db');
  return dbFactory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: databaseVersion,
      onCreate: (db, version) => _migrate(db, 0, version),
      onUpgrade: _migrate,
    ),
  );
}

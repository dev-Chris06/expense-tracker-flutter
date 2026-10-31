/// Les 9 catégories fixes de dépenses.
///
/// Le libellé (`label`) est ce qui est stocké en base et affiché : il doit
/// rester identique à la liste figée dans la contrainte CHECK du schéma
/// (voir data/database.dart).
enum ExpenseCategory {
  nourriture('Nourriture'),
  transport('Transport'),
  communication('Communication'),
  logement('Logement'),
  etudes('Études'),
  travail('Travail'),
  sante('Santé'),
  loisirs('Loisirs'),
  autre('Autre');

  const ExpenseCategory(this.label);

  final String label;

  /// Retrouve une catégorie à partir de son libellé stocké en base.
  static ExpenseCategory fromLabel(String label) =>
      values.firstWhere((c) => c.label == label, orElse: () => autre);
}

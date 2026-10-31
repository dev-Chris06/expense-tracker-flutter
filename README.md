# Dépenses — version Flutter

Application mobile de suivi de dépenses personnelles en FCFA, 100 % hors
ligne (SQLite local). Version **Flutter** du comparatif Expo vs Flutter ;
la version Expo vit dans le dépôt `expense-tracker-expo` avec exactement les
mêmes fonctionnalités, la même palette et les mêmes textes.

## Fonctionnalités

- **Accueil** : total et nombre d'opérations du mois en cours, dernière dépense.
- **Ajout / modification** : montant entier en FCFA (« 1 500 » accepté),
  9 catégories fixes, date (sélecteur Material en français), note facultative.
- **Liste** : recherche sans accents ni casse sur la catégorie, la note, la
  date (ISO ou JJ/MM/AAAA) et le montant ; filtre par catégorie ; suppression
  avec confirmation.
- **Statistiques** : répartition par catégorie d'un mois (navigation ‹ ›) et
  historique des 12 derniers mois.
- **Thème clair / sombre** qui suit le réglage du système.

## Stack

Flutter 3.47 · Dart 3.13 · sqflite · go_router · flutter_test + sqflite_common_ffi

```
lib/
  main.dart, router.dart, theme.dart
  data/       ouverture + migrations SQLite, ExpenseRepository (ChangeNotifier)
  models/     Expense, ExpenseInput, ExpenseCategory
  screens/    home, add, list, stats, edit
  widgets/    ExpenseForm, AppChip
  utils/      validation, formatage, dates, mois, recherche
test/         tests unitaires, base SQLite réelle en mémoire, tests de widgets
```

## Développement

```bash
flutter pub get
flutter analyze
flutter test        # nécessite libsqlite3 (sudo apt install libsqlite3-dev)
```

Seules les plateformes Android et iOS sont conservées (sqflite ne gère pas
le web ni Linux/Windows sans adaptation).

## Base de données

Le schéma est versionné (PRAGMA user_version, géré par sqflite). Pour le
faire évoluer, **ajouter** une migration à la fin de `migrations` dans
`lib/data/database.dart` — ne jamais modifier une migration déjà publiée.
Ajouter ou renommer une catégorie demande aussi une migration (contrainte CHECK).

## Tester sur le téléphone (APK)

Comme pour Loady, les APK sont construits par GitHub Actions et signés avec
la clé debug partagée (secret `DEBUG_KEYSTORE_BASE64`), ce qui permet
d'installer chaque nouvelle version par-dessus la précédente.

1. Mettre à jour `version:` dans `pubspec.yaml` (ex. `1.0.1+2` : incrémenter
   aussi le numéro après le `+`).
2. Commiter, puis pousser le tag : `git tag v1.0.1 && git push origin v1.0.1`.
3. Le workflow **Build Android APK** publie `depenses-flutter-<version>-arm64.apk`
   (téléphones récents) et `-armv7.apk` (anciens téléphones 32 bits) dans les
   Releases du dépôt (connexion GitHub requise : dépôt privé).

Le workflow peut aussi être lancé à la main (onglet Actions → *Run workflow*).

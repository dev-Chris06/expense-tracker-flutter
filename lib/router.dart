/// Routes de l'application (équivalent du routing par fichiers d'expo-router) :
///   /          → accueil
///   /add       → ajout
///   /list      → liste
///   /stats     → statistiques
///   /edit/42   → modification (route dynamique)
library;

import 'package:go_router/go_router.dart';

import 'data/expense_repository.dart';
import 'screens/add_screen.dart';
import 'screens/edit_screen.dart';
import 'screens/home_screen.dart';
import 'screens/list_screen.dart';
import 'screens/stats_screen.dart';

GoRouter buildRouter(ExpenseRepository repository) => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => HomeScreen(repository: repository)),
        GoRoute(path: '/add', builder: (_, _) => AddScreen(repository: repository)),
        GoRoute(path: '/list', builder: (_, _) => ListScreen(repository: repository)),
        GoRoute(path: '/stats', builder: (_, _) => StatsScreen(repository: repository)),
        GoRoute(
          path: '/edit/:id',
          builder: (_, state) =>
              EditScreen(repository: repository, idParam: state.pathParameters['id']!),
        ),
      ],
    );

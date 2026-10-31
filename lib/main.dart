import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'data/database.dart';
import 'data/expense_repository.dart';
import 'router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await openExpenseDatabase();
  runApp(ExpenseApp(repository: ExpenseRepository(database)));
}

class ExpenseApp extends StatefulWidget {
  const ExpenseApp({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  State<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends State<ExpenseApp> {
  late final GoRouter _router = buildRouter(widget.repository);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dépenses Flutter',
      debugShowCheckedModeBanner: false,
      // Thème clair / sombre selon le réglage du système.
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      // Français : sélecteur de date, libellés Material…
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: _router,
    );
  }
}

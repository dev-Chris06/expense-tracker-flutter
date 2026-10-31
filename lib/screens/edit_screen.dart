import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/expense_repository.dart';
import '../models/expense.dart';
import '../theme.dart';
import '../utils/errors.dart';
import '../widgets/expense_form.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key, required this.repository, required this.idParam});

  final ExpenseRepository repository;

  /// Id brut tel que reçu dans l'URL (/edit/:id), validé ici.
  final String idParam;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  Expense? _expense;
  bool _loading = true;
  String _error = '';

  int? get _id {
    final id = int.tryParse(widget.idParam);
    return id != null && id > 0 ? id : null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = _id;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'Cette dépense est introuvable.';
      });
      return;
    }
    try {
      final expense = await widget.repository.getById(id);
      if (!mounted) return;
      setState(() {
        _expense = expense;
        if (expense == null) _error = 'Cette dépense est introuvable.';
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger cette dépense.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final expense = _expense;

    Widget body;
    if (_loading) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: c.primary),
            const SizedBox(height: 14),
            Text('Chargement…', style: TextStyle(color: c.text)),
          ],
        ),
      );
    } else if (expense == null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error, style: TextStyle(color: c.danger)),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => context.go('/list'),
              child: Text('Retour à la liste',
                  style: TextStyle(color: c.link, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      body = ExpenseForm(
        initialExpense: expense,
        submitLabel: 'Enregistrer les modifications',
        onSubmit: (value) async {
          final updated = await widget.repository.update(expense.id, value);
          if (!updated) {
            throw const UserFacingError(
                'Cette dépense n’existe plus : elle a peut-être été supprimée.');
          }
          if (!context.mounted) return;
          // Retour à l'écran d'origine (accueil ou liste), qui se recharge seul.
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/list');
          }
        },
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('Modifier')), body: body);
  }
}

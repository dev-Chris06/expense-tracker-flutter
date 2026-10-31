import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/expense_repository.dart';
import '../models/category.dart';
import '../models/expense.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../utils/formatters.dart';
import '../utils/search.dart';
import '../widgets/app_chip.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  List<Expense> _rows = [];
  String _query = '';
  ExpenseCategory? _category;
  String _error = '';

  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    widget.repository.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final rows = await widget.repository.getAll();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _error = '';
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Chargement impossible. Réessaie.');
    }
  }

  Future<void> _remove(Expense expense) async {
    final message =
        '${expense.categorie.label} · ${formatAmount(expense.montant)} du ${formatDisplayDate(expense.date)}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la dépense ?'),
        content: Text('$message\nCette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.delete(expense.id);
    } catch (_) {
      if (mounted) setState(() => _error = 'Suppression impossible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filtered = _rows
        .where((e) => (_category == null || e.categorie == _category) && matchesQuery(e, _query))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Mes dépenses')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('search'),
              onChanged: (value) => setState(() => _query = value),
              style: TextStyle(fontSize: 16, color: c.text),
              decoration: const InputDecoration(
                hintText: 'Rechercher (catégorie, note, date, montant)',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChip(
                    label: 'Tout',
                    selected: _category == null,
                    onTap: () => setState(() => _category = null)),
                for (final category in ExpenseCategory.values)
                  AppChip(
                    label: category.label,
                    selected: _category == category,
                    onTap: () =>
                        setState(() => _category = _category == category ? null : category),
                  ),
              ],
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(_error, style: TextStyle(color: c.danger)),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _rows.isEmpty
                            ? 'Aucune dépense pour le moment.'
                            : 'Aucune dépense ne correspond à la recherche.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: c.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _ExpenseRow(
                        expense: filtered[index],
                        onDelete: () => _remove(filtered[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.onDelete});

  final Expense expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                hint: 'Ouvre la dépense pour la modifier',
                child: InkWell(
                  onTap: () => context.push('/edit/${expense.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(expense.categorie.label,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                      const SizedBox(height: 5),
                      Text(
                        '${formatDisplayDate(expense.date)}'
                        '${expense.note != null ? ' · ${expense.note}' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatAmount(expense.montant),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                Semantics(
                  label:
                      'Supprimer la dépense ${expense.categorie.label} de ${formatAmount(expense.montant)}',
                  excludeSemantics: true,
                  button: true,
                  child: TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: c.danger,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('Supprimer',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

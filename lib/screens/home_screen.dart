import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/expense_repository.dart';
import '../models/expense.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../utils/formatters.dart';
import '../utils/months.dart';
import '../widgets/updates.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MonthSummary _summary = const MonthSummary(total: 0, count: 0);
  Expense? _latest;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    // Recharge à chaque ajout, modification ou suppression.
    widget.repository.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.repository.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final summary = await widget.repository.getMonthSummary(monthKey());
      final latest = await widget.repository.getLatest();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _latest = latest;
        _error = false;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final latest = _latest;

    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const SizedBox(height: 12),
          Text(
            'VOTRE BUDGET',
            style: TextStyle(
              color: c.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suivi de dépenses',
            style: TextStyle(color: c.text, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          if (_error) ...[
            const SizedBox(height: 12),
            Text('Impossible de charger les dépenses.', style: TextStyle(color: c.danger)),
          ],
          const UpdateBanner(),
          const SizedBox(height: 26),
          Semantics(
            button: true,
            hint: 'Ouvre les statistiques du mois',
            child: Material(
              color: c.heroBackground,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.push('/stats'),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dépenses · ${formatMonthLabel(monthKey())}',
                        style: TextStyle(color: c.heroTextMuted, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatAmount(_summary.total),
                        style: TextStyle(
                          color: c.heroText,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatCount(_summary.count),
                        style: TextStyle(color: c.heroTextMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: () => context.push('/add'),
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                '＋ Ajouter une dépense',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(label: 'Toutes mes dépenses', route: '/list'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SecondaryButton(label: 'Statistiques', route: '/stats'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Dernière dépense',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text),
          ),
          const SizedBox(height: 16),
          if (latest == null)
            Text(
              'Aucune dépense pour le moment.',
              style: TextStyle(color: c.textMuted, fontSize: 14),
            )
          else
            Semantics(
              button: true,
              hint: 'Ouvre la dépense pour la modifier',
              child: Material(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push('/edit/${latest.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latest.categorie.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: c.text,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${formatDisplayDate(latest.date)}'
                                '${latest.note != null ? ' · ${latest.note}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: c.textMuted, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          formatAmount(latest.montant),
                          style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const UpdateFooter(),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return OutlinedButton(
      onPressed: () => context.push(route),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: c.surface,
        foregroundColor: c.link,
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

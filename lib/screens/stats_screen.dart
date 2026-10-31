/// Statistiques : répartition par catégorie pour un mois donné (navigable
/// avec ‹ ›) et historique des totaux mensuels. Toucher un mois de
/// l'historique l'affiche en haut.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/expense_repository.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../utils/months.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final String _currentMonth = monthKey();
  late String _month = _currentMonth;
  List<CategoryTotal> _categories = [];
  List<MonthTotal> _history = [];
  bool _error = false;

  @override
  void initState() {
    super.initState();
    widget.repository.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    widget.repository.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final month = _month;
    try {
      final categories = await widget.repository.getCategoryTotals(month);
      final history = await widget.repository.getMonthlyTotals(limit: 12);
      // Ignore une réponse arrivée après un changement de mois.
      if (!mounted || month != _month) return;
      setState(() {
        _categories = categories;
        _history = history;
        _error = false;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _selectMonth(String month) {
    setState(() => _month = month);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = _categories.fold<int>(0, (sum, row) => sum + row.total);
    final count = _categories.fold<int>(0, (sum, row) => sum + row.count);
    final maxMonthly = _history.fold<int>(0, (m, row) => math.max(m, row.total));
    final isCurrentMonth = _month.compareTo(_currentMonth) >= 0;
    final sectionStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text);
    final mutedStyle = TextStyle(color: c.textMuted, fontSize: 14);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (_error) ...[
            Text('Impossible de charger les statistiques.', style: TextStyle(color: c.danger)),
            const SizedBox(height: 14),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavButton(
                symbol: '‹',
                label: 'Mois précédent',
                onPressed: () => _selectMonth(shiftMonth(_month, -1)),
              ),
              Semantics(
                header: true,
                child: Text(formatMonthLabel(_month),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.text)),
              ),
              _NavButton(
                symbol: '›',
                label: 'Mois suivant',
                onPressed: isCurrentMonth ? null : () => _selectMonth(shiftMonth(_month, 1)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.heroBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatAmount(total),
                    style: TextStyle(color: c.heroText, fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(formatCount(count), style: TextStyle(color: c.heroTextMuted, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Par catégorie', style: sectionStyle),
          const SizedBox(height: 14),
          if (_categories.isEmpty)
            Text('Aucune dépense ce mois-ci.', style: mutedStyle)
          else
            _Panel(
              children: [
                for (final row in _categories)
                  Semantics(
                    label:
                        '${row.categorie.label} : ${formatAmount(row.total)}, ${percentOf(row.total, total)} pour cent',
                    excludeSemantics: true,
                    child: _Bar(
                      label: row.categorie.label,
                      value: '${formatAmount(row.total)} · ${percentOf(row.total, total)} %',
                      percent: percentOf(row.total, total),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 22),
          Text('Historique mensuel', style: sectionStyle),
          const SizedBox(height: 14),
          if (_history.isEmpty)
            Text('Pas encore d’historique.', style: mutedStyle)
          else
            _Panel(
              children: [
                for (final row in _history)
                  Semantics(
                    button: true,
                    selected: row.month == _month,
                    label:
                        '${formatMonthLabel(row.month)} : ${formatAmount(row.total)}, ${formatCount(row.count)}',
                    excludeSemantics: true,
                    child: Material(
                      color: row.month == _month ? c.barTrack : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _selectMonth(row.month),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: _Bar(
                            label: formatMonthLabel(row.month),
                            labelColor: row.month == _month ? c.link : null,
                            value: formatAmount(row.total),
                            percent: percentOf(row.total, maxMonthly),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.symbol, required this.label, required this.onPressed});

  final String symbol;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onPressed == null ? 0.35 : 1,
        child: Material(
          color: c.surface,
          shape: CircleBorder(side: BorderSide(color: c.border)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(child: Text(symbol, style: TextStyle(fontSize: 24, color: c.text))),
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value, required this.percent, this.labelColor});

  final String label;
  final String value;
  final int percent;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: labelColor ?? c.text, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Text(value, style: TextStyle(color: c.textMuted, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: math.max(percent, 2) / 100,
            minHeight: 8,
            backgroundColor: c.barTrack,
            color: c.primary,
          ),
        ),
      ],
    );
  }
}

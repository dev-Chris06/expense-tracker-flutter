import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../theme.dart';
import '../utils/dates.dart';
import '../utils/errors.dart';
import '../utils/validation.dart';
import 'app_chip.dart';

/// Formulaire partagé par les écrans d'ajout et de modification.
class ExpenseForm extends StatefulWidget {
  const ExpenseForm({
    super.key,
    this.initialExpense,
    required this.submitLabel,
    required this.onSubmit,
  });

  final Expense? initialExpense;
  final String submitLabel;

  /// Peut lever une [UserFacingError] dont le message sera affiché.
  final Future<void> Function(ExpenseInput value) onSubmit;

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late ExpenseCategory? _category;
  late String _date;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialExpense;
    _amount = TextEditingController(text: initial?.montant.toString() ?? '');
    _note = TextEditingController(text: initial?.note ?? '');
    _category = initial?.categorie;
    _date = initial?.date ?? todayIso();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validation = validateExpenseInput(_amount.text, _category, _date);
    if (validation.error != null) {
      setState(() => _error = validation.error);
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final note = _note.text.trim();
      await widget.onSubmit(validation.value!.copyWith(note: note.isEmpty ? null : note));
    } on UserFacingError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Enregistrement impossible. Réessaie.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isValidIsoDate(_date) ? parseIsoDate(_date) : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null) setState(() => _date = toIsoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final labelStyle = TextStyle(color: c.textMuted, fontSize: 14, fontWeight: FontWeight.w600);
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 10),
          child: Text(text, style: labelStyle),
        );

    return ListView(
      padding: const EdgeInsets.all(20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        label('Montant · FCFA'),
        TextField(
          key: const Key('amount'),
          controller: _amount,
          keyboardType: TextInputType.number,
          style: TextStyle(fontSize: 16, color: c.text),
          decoration: const InputDecoration(hintText: 'Ex. 1 500'),
        ),
        label('Catégorie'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in ExpenseCategory.values)
              AppChip(
                label: category.label,
                selected: category == _category,
                onTap: () => setState(() => _category = category),
              ),
          ],
        ),
        label('Date'),
        Semantics(
          button: true,
          label: 'Date de la dépense : ${formatDisplayDate(_date)}. Changer',
          excludeSemantics: true,
          child: Material(
            color: c.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: c.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                constraints: const BoxConstraints(minHeight: 50),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(formatDisplayDate(_date),
                          style: TextStyle(fontSize: 16, color: c.text)),
                    ),
                    Text('Changer', style: TextStyle(color: c.link, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
        label('Note · facultative'),
        TextField(
          key: const Key('note'),
          controller: _note,
          maxLength: 280,
          minLines: 3,
          maxLines: 5,
          style: TextStyle(fontSize: 16, color: c.text),
          decoration: const InputDecoration(hintText: 'Ex. déjeuner'),
        ),
        if (_error != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_error!, style: TextStyle(color: c.danger, fontSize: 14)),
            ),
          ),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              _saving ? 'Enregistrement…' : widget.submitLabel,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

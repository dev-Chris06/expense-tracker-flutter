import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/expense_repository.dart';
import '../widgets/expense_form.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter une dépense')),
      body: ExpenseForm(
        submitLabel: 'Enregistrer la dépense',
        onSubmit: (value) async {
          await repository.add(value);
          if (context.mounted) context.pushReplacement('/list');
        },
      ),
    );
  }
}

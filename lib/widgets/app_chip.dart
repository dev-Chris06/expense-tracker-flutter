import 'package:flutter/material.dart';

import '../theme.dart';

/// Pastille sélectionnable, utilisée par le sélecteur de catégorie du
/// formulaire et par les filtres de la liste (un seul style pour les deux).
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.primary : c.surface,
        shape: StadiumBorder(side: BorderSide(color: selected ? c.primary : c.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: selected ? c.onPrimary : c.text,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

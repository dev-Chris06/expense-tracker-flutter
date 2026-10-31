/// Formate un montant entier : 1500 → "1 500 FCFA" (espaces insécables).
String formatAmount(int amount) {
  final digits = amount.abs().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ' ',
      );
  return '${amount < 0 ? '-' : ''}$digits FCFA';
}

/// "3 opérations", "1 opération", "0 opération".
String formatCount(int count) => '$count opération${count > 1 ? 's' : ''}';

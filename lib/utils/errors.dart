/// Erreur dont le message est destiné à l'utilisateur et peut être affiché
/// tel quel. Les autres erreurs (techniques) sont remplacées par un message
/// générique.
class UserFacingError implements Exception {
  const UserFacingError(this.message);

  final String message;

  @override
  String toString() => message;
}

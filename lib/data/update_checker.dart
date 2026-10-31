/// Recherche de mise à jour, sur le modèle de Loady.
///
/// Chaque release GitHub (tag v*) publie un version.json à côté des APK.
/// L'app le lit via l'URL « latest » (un simple fichier statique, pas l'API
/// GitHub limitée à 60 requêtes/heure), compare avec la version installée,
/// puis ouvre l'APK dans le navigateur : l'app ne l'installe jamais elle-même.
library;

import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io' show HttpClient, HttpStatus, Platform;

import 'package:package_info_plus/package_info_plus.dart';

const _repo = 'https://github.com/dev-Chris06/expense-tracker-flutter';
final _versionUrl = Uri.parse('$_repo/releases/latest/download/version.json');

enum UpdateCheckOutcome { available, upToDate, failed, unsupported }

class UpdateCheckResult {
  const UpdateCheckResult(this.outcome, [this.version]);

  final UpdateCheckOutcome outcome;

  /// La nouvelle version, renseignée seulement si [outcome] vaut available.
  final String? version;
}

/// Version installée (versionName, sans le numéro de build).
Future<String> installedVersion() async => (await PackageInfo.fromPlatform()).version;

/// Suffixe de l'APK adapté au processeur du téléphone.
String apkAbiSuffix([Abi? abi]) => (abi ?? Abi.current()) == Abi.androidArm ? 'armv7' : 'arm64';

/// Lien direct vers l'APK d'une version publiée.
Uri apkDownloadUri(String version, [Abi? abi]) => Uri.parse(
  '$_repo/releases/download/v$version/depenses-flutter-$version-${apkAbiSuffix(abi)}.apk',
);

List<int>? _parseVersion(String value) {
  final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:\+\d+)?$').firstMatch(value.trim());
  if (match == null) return null;
  return [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
}

/// Vrai si [candidate] est strictement plus récente que [installed]
/// (major.minor.patch). Une valeur illisible n'est jamais considérée plus récente.
bool isNewerVersion(String candidate, String installed) {
  final a = _parseVersion(candidate);
  final b = _parseVersion(installed);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

Future<String?> _fetchLatestVersion() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(_versionUrl);
    request.headers.set('Cache-Control', 'no-cache');
    final response = await request.close().timeout(const Duration(seconds: 15));
    if (response.statusCode != HttpStatus.ok) return null;
    final body = await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 15));
    final data = jsonDecode(body);
    if (data is! Map) return null;
    final version = data['version'];
    return version is String && _parseVersion(version) != null ? version : null;
  } finally {
    client.close(force: true);
  }
}

/// Compare la dernière release publiée avec la version installée.
Future<UpdateCheckResult> checkForUpdate() async {
  // Les APK n'existent que pour Android.
  if (!Platform.isAndroid) return const UpdateCheckResult(UpdateCheckOutcome.unsupported);
  try {
    final latest = await _fetchLatestVersion();
    if (latest == null) return const UpdateCheckResult(UpdateCheckOutcome.failed);
    return isNewerVersion(latest, await installedVersion())
        ? UpdateCheckResult(UpdateCheckOutcome.available, latest)
        : const UpdateCheckResult(UpdateCheckOutcome.upToDate);
  } catch (_) {
    // Hors ligne ou réponse illisible : la vérification ne doit jamais gêner l'app.
    return const UpdateCheckResult(UpdateCheckOutcome.failed);
  }
}

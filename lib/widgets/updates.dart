/// Interface des mises à jour sur l'accueil :
/// - UpdateBanner : vérifie une fois par lancement et signale une nouvelle
///   version (masquable jusqu'au prochain lancement) ;
/// - UpdateFooter : version installée + vérification à la demande.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/update_checker.dart';
import '../theme.dart';

// Partagé entre les montages de l'accueil : une seule vérification
// automatique par lancement, et « Plus tard » tient jusqu'au suivant.
Future<UpdateCheckResult>? _autoCheck;
bool _dismissed = false;

Future<void> _openDownload(BuildContext context, String version) async {
  final messenger = ScaffoldMessenger.of(context);
  final launched = await launchUrl(
    apkDownloadUri(version),
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);
  if (!launched) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Impossible d’ouvrir le lien de téléchargement.')),
    );
  }
}

class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  String? _version;

  @override
  void initState() {
    super.initState();
    (_autoCheck ??= checkForUpdate()).then((result) {
      if (!mounted || _dismissed || result.outcome != UpdateCheckOutcome.available) return;
      setState(() => _version = result.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final version = _version;
    if (version == null) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.primary),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle version $version disponible',
                style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Télécharge l’APK puis ouvre-le pour mettre l’app à jour.',
                style: TextStyle(color: c.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _dismissed = true;
                      setState(() => _version = null);
                    },
                    style: TextButton.styleFrom(foregroundColor: c.textMuted),
                    child: const Text('Plus tard', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _openDownload(context, version),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: c.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Télécharger', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpdateFooter extends StatefulWidget {
  const UpdateFooter({super.key});

  @override
  State<UpdateFooter> createState() => _UpdateFooterState();
}

class _UpdateFooterState extends State<UpdateFooter> {
  late final Future<String> _installed = installedVersion();
  bool _checking = false;

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    final result = await checkForUpdate();
    if (!mounted) return;
    setState(() => _checking = false);
    final version = result.version;
    if (result.outcome == UpdateCheckOutcome.available && version != null) {
      final download = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mise à jour disponible'),
          content: Text('La version $version est disponible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Plus tard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Télécharger'),
            ),
          ],
        ),
      );
      if (download == true && mounted) await _openDownload(context, version);
      return;
    }
    final message = switch (result.outcome) {
      UpdateCheckOutcome.upToDate => 'L’application est à jour.',
      UpdateCheckOutcome.unsupported => 'Disponible uniquement dans l’application Android.',
      _ => 'Vérification impossible. Vérifie ta connexion et réessaie.',
    };
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mise à jour'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: _checking
                ? Center(
                    child: SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(color: c.link),
                    ),
                  )
                : TextButton(
                    onPressed: _check,
                    style: TextButton.styleFrom(foregroundColor: c.link),
                    child: const Text(
                      'Rechercher une mise à jour',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
          FutureBuilder<String>(
            future: _installed,
            builder: (context, snapshot) => snapshot.hasData
                ? Text(
                    'Version ${snapshot.data}',
                    style: TextStyle(color: c.textMuted, fontSize: 13),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

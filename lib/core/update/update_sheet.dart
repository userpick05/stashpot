import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'update_service.dart';

/// Shows the "update available" bottom sheet. Returns nothing — it manages its
/// own download/install lifecycle. Uses a bottom sheet rather than an
/// AlertDialog because dialogs black-screen via Impeller on some devices.
Future<void> showUpdateSheet(BuildContext context, UpdateInfo info) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    showDragHandle: true,
    builder: (_) => _UpdateSheet(info: info),
  );
}

class _UpdateSheet extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateSheet({required this.info});

  @override
  State<_UpdateSheet> createState() => _UpdateSheetState();
}

class _UpdateSheetState extends State<_UpdateSheet> {
  double _progress = 0;
  bool _downloading = false;
  String? _error;

  Future<void> _start() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });
    try {
      await UpdateService.downloadAndInstall(
        widget.info,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      // Installer launched — close the sheet.
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _downloading = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.system_update, color: scheme.primary),
              const SizedBox(width: 10),
              Text(l.updateAvailable,
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 4),
          Text(l.settingsVersion(widget.info.version),
              style: TextStyle(color: scheme.outline)),
          if (widget.info.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Text(widget.info.notes),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: scheme.error)),
            const SizedBox(height: 12),
          ],
          if (_downloading) ...[
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
            ),
            const SizedBox(height: 8),
            Text(
              _progress > 0
                  ? l.updateDownloadingPercent(
                      (_progress * 100).toStringAsFixed(0))
                  : l.updateStarting,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.commonLater),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.download),
                  label: Text(_error == null ? l.updateNow : l.commonRetry),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

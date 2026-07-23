import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Shows a saved photo full-width in a bottom sheet (tap the photo icon to open).
void showImageSheet(BuildContext context, String url) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (c, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      height: 240,
                      child: Center(child: CircularProgressIndicator()),
                    ),
              errorBuilder: (c, e, s) => SizedBox(
                height: 160,
                child: Center(
                    child: Text(AppLocalizations.of(c).imageLoadFailed)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

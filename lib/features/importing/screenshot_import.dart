import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/scanning_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/scanned_item.dart';
import '../../services/shopping_scan_service.dart';
import 'import_review_screen.dart';

/// Entry point for "add items from screenshots of another shopping app".
///
/// Only picks the images here — the reading happens inside
/// [ImportReviewScreen], which owns its own loading and error states. That
/// avoids a modal progress dialog (they black-screen via Impeller on this
/// hardware, and dismissing one from an async callback is race-prone) and gives
/// the user a Retry that doesn't lose the picked screenshots.
Future<void> startScreenshotImport(
  BuildContext context,
  WidgetRef ref, {
  required ImportDestination destination,
}) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  if (!ref.read(shoppingScanServiceProvider).isConfigured) {
    messenger.showSnackBar(SnackBar(content: Text(l.importNoAiKey)));
    return;
  }

  final List<XFile> picked;
  try {
    // limit: lets the OS picker enforce the cap, so there's no "I chose 8 and
    // it silently used 5" surprise. maxWidth/imageQuality bound the upload —
    // verified against the real screenshots to not cost any accuracy.
    picked = await ImagePicker().pickMultiImage(
      limit: ShoppingScanService.maxImages,
      maxWidth: 1280,
      imageQuality: 85,
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.commonError('$e'))));
    return;
  }
  if (picked.isEmpty) return;

  if (!context.mounted) return;

  await navigator.push(MaterialPageRoute(
    builder: (_) => ImportReviewScreen(
      images: picked.take(ShoppingScanService.maxImages).toList(),
      initialDestination: destination,
    ),
  ));
}

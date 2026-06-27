import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_version.dart';

/// A newer release advertised by version.json.
class UpdateInfo {
  final String version;
  final String apkUrl;
  final String notes;
  const UpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.notes,
  });
}

/// Checks GitHub for a newer build and installs it. Sideloaded apps can't
/// install fully silently, so the flow is: download the APK, then hand it to
/// Android's package installer (one tap by the user to confirm).
class UpdateService {
  /// Fetches version.json and returns an [UpdateInfo] if it advertises a
  /// version newer than the running build. Returns null when up to date,
  /// unreachable, or malformed — a failed check must never disrupt the app.
  static Future<UpdateInfo?> checkForUpdate() async {
    // No point checking on non-Android (we only ship sideloaded APKs).
    if (!Platform.isAndroid) return null;
    // Placeholder URL until the repo exists — skip quietly.
    if (kUpdateManifestUrl.contains('<GITHUB_USER>')) return null;
    try {
      final res = await http
          .get(Uri.parse(kUpdateManifestUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final latest = (json['version'] as String?)?.trim();
      final apkUrl = (json['apkUrl'] as String?)?.trim();
      if (latest == null || apkUrl == null || apkUrl.isEmpty) return null;
      if (!_isNewer(latest, kAppVersion)) return null;
      return UpdateInfo(
        version: latest,
        apkUrl: apkUrl,
        notes: (json['notes'] as String?)?.trim() ?? '',
      );
    } catch (e) {
      debugPrint('Update check failed: $e');
      return null;
    }
  }

  /// Downloads [info]'s APK, reporting progress in 0..1, then launches the
  /// system installer. Throws on download failure so the UI can surface it.
  static Future<void> downloadAndInstall(
    UpdateInfo info, {
    void Function(double progress)? onProgress,
  }) async {
    // Ask for "install unknown apps" up front for a cleaner prompt; if denied
    // the installer itself will still route the user to grant it.
    if (await Permission.requestInstallPackages.isDenied) {
      await Permission.requestInstallPackages.request();
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/stashpot-${info.version}.apk');

    final request = http.Request('GET', Uri.parse(info.apkUrl));
    final response = await request.send();
    if (response.statusCode != 200) {
      throw HttpException('Download failed (${response.statusCode})');
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = file.openWrite();
    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) onProgress?.call(received / total);
    }
    await sink.flush();
    await sink.close();

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('Could not open installer: ${result.message}');
    }
  }

  /// True when [latest] is a higher semver than [current]. Tolerant of
  /// differing segment counts ("1.2" vs "1.2.0") and non-numeric noise.
  static bool _isNewer(String latest, String current) {
    final a = _parts(latest);
    final b = _parts(current);
    final len = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < len; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av != bv) return av > bv;
    }
    return false;
  }

  static List<int> _parts(String v) =>
      v.split('.').map((p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0).toList();
}

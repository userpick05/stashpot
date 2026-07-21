/// Bump this when finalizing a session's changes (semver, 1.x.x).
const String kAppVersion = '1.7.0';

/// Where the app looks for OTA updates. This points at a small JSON file
/// committed to the repo's `main` branch, so it always reflects the latest
/// release without changing the app. Shape:
///   { "version": "1.2.0",
///     "apkUrl": "https://github.com/<user>/stashpot/releases/download/v1.2.0/stashpot-1.2.0.apk",
///     "notes": "What changed..." }
///
const String kUpdateManifestUrl =
    'https://raw.githubusercontent.com/userpick05/stashpot/main/version.json';

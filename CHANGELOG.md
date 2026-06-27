# Changelog

All notable changes to Stashpot. Versions track `kAppVersion` in
`lib/core/app_version.dart`.

## v1.1.1

### Fixed
- The "Added … to shopping list" snackbar from the Home **Running low?** flow
  no longer lingers/sticks on screen. The sheet now closes *before* the snackbar
  is shown (showing it first, then popping the sheet, left it stuck).

### Changed
- Bumped Android `versionCode` to 2 so this installs over v1.1.0 (sideloaded
  updates require an increasing version code).

## v1.1.0

### Added
- **Pantry search** — search field on the Pantry screen filters items by name,
  location, or category as you type.
- **Move to shopping list** — each pantry item now has a "⋮" menu with
  *Add to shopping list* (carries name, quantity, and store).
- **"Running low?" on Home** — a Home card opens a quick search of the pantry;
  tap an item to send it straight to the shopping list.
- **OTA self-update scaffolding** — release signing key, in-app update check
  against a GitHub-hosted `version.json`, download + system-installer handoff.
  *Inactive until the GitHub repo/release URL is wired in.*

### Notes
- Release builds are now signed with a stable `CN=Stashpot` key (not the debug
  key) so future OTA updates can install over each other. The first release
  install requires a one-time uninstall/reinstall (Firebase data is safe).

## v1.0.0
- Baseline: auth + shared households, pantry inventory (add/edit/scan/photo,
  expiry tracking, group by location/category), shopping list (store grouping,
  reorder, move checked → pantry), recipes (find/import/manual, add ingredients
  to list, ratings), meal planner, home dashboard, settings.

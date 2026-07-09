# Changelog

All notable changes to Stashpot. Versions track `kAppVersion` in
`lib/core/app_version.dart`.

## v1.3.0

### Added
- **Tap-to-edit quantities** — pantry quantities now show as a "×N" pill (the
  same style as the shopping list); tap it for a quick +/- editor instead of
  opening the whole item.

### Changed
- **Barcode scanning is back to a live camera preview** (mobile_scanner) —
  point at a barcode and it reads instantly, instead of the unreliable
  take-a-photo approach. Includes an "Enter manually" fallback and a friendly
  message if the camera can't start.

## v1.2.0

### Added
- **Custom pantry locations** — create your own storage locations (e.g. "Garage
  shelf") right from the item's Location picker, or manage them (rename/delete)
  in Settings → Pantry locations. They join Fridge/Freezer/Pantry/Other in the
  picker and in pantry grouping. Existing items keep their current location.
- **Remove from pantry & add to shopping** — a second action on each pantry
  item's ⋮ menu that moves it to the shopping list in one step.
- **Duplicate handling when moving shopped items to the pantry** — if an item is
  already in the pantry, you're asked per item whether to **skip** it or **add
  its quantity** to the existing one.

### Changed
- Recipe ingredients now show a **filled/solid cart icon** once they're on the
  shopping list, so it's obvious what you've already added.

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

# Changelog

All notable changes to Stashpot. Versions track `kAppVersion` in
`lib/core/app_version.dart`.

## v1.8.0

### Added
- **Traditional Chinese (繁體中文).** The whole app is now translated — 332 strings
  across every screen. It follows your phone's language automatically, and there's
  a new **Settings → Language** picker (System default / English / 繁體中文).
- **Chinese product scanning.** Photo identification now answers in your language,
  so photographing Chinese packaging gives you a Chinese item name (with Taiwan
  store hints instead of US ones). Barcode lookups ask for Chinese product names.
- **Barcode misses no longer dead-end.** When a barcode isn't in the product
  database — common for local and imported products — the app offers to identify
  it from a photo instead.
- Item categories are now auto-guessed from Chinese names too, so items moved from
  the shopping list land in the right category instead of "Other".

### Notes
- Nothing stored changed: categories, locations, units and meal types keep their
  existing values, so all existing pantry and planner data works untouched and
  English is unaffected.
- Recipe *content* from the recipe search remains English.

## v1.7.0

### Added
- **Move / swap meals on the planner.** Every planned meal now has a "move to
  another day" button. Pick a new day and the meal moves there; if that day
  already has a meal of the same type (e.g. Dinner), the two swap places instead
  of one overwriting the other.
- **Meal roulette (auto-fill).** A dice button on the planner auto-fills the next
  N days with a random assortment drawn from meals you've planned before. Pick how
  many days and which meals to fill (Breakfast / Lunch / Dinner, any combination).
  It only fills EMPTY slots so it never clobbers a meal you set on purpose, and you
  preview the picks and can re-roll before adding them to the plan.

## v1.6.0

### Added
- **Move part of a pantry item to the shopping list.** When you use a pantry
  item's "⋮" menu → "Remove from pantry & add to shopping list", you now get a
  "How many to move?" stepper. Move only some of it (e.g. 2 of your 4 dozen
  eggs) and the rest stays in the pantry; move the full amount and it behaves
  exactly like before. Undo restores both the pantry item and removes the
  shopping-list entry.

## v1.5.3

### Changed
- **New app icon** — the StashPot grocery-bag logo now shows on your home screen
  (replacing the generic Flutter icon), including an Android adaptive icon.

## v1.5.2

### Added
- **"Running low?" now handles items not yet in your pantry.** Search for
  something that doesn't match any pantry item and an "Add to shopping list"
  button appears so you can add it fresh.
- **Duplicate check on Running low adds.** If the item you're adding is
  already on the shopping list, you're asked to skip it or add it anyway.

## v1.5.1

### Fixed
- **Shopping-list photo can now use the gallery.** The "take a photo to identify"
  option on the shopping list now offers **camera *or* gallery** (like the
  pantry) — so you can add an item from a saved screenshot of something you want
  to shop for.
- **Notes no longer drop going pantry → shopping.** Adding a pantry item to the
  shopping list now carries its note (e.g. size/quantity) over, matching the
  shopping → pantry direction.

## v1.5.0

### Fixed
- **Same-name items with different sizes stay separate.** When moving a checked
  item from the shopping list to the pantry, its note (where a size like "1 gal"
  or "24-pack" lives) is now carried over, the pantry shows that note, and the
  duplicate check compares name **and** note — so two sizes of the same product
  no longer get merged into one.

### Added
- **Take a photo to add to the shopping list.** The shopping-list add sheet now
  has the same "snap a photo → identify → prefill" option as the pantry (it even
  drops the detected size/variety into the note).

## v1.4.0

### Added
- **Group the pantry by store** — a new option in the Pantry "Group by" menu.
  Splits your pantry into sections by the store each item is bought at (with an
  "Other / no store" catch-all), so you can check what you've got before a
  particular shopping trip. Pantry search now matches store names too.

## v1.3.1

### Fixed
- **Barcode scanning works on all devices again.** The live camera preview
  crashed inside the camera engine on some phones (Pixel 10 / Android 16). The
  scanner now snaps one full-resolution photo and decodes that instead, which
  never starts the crashing preview. "Enter manually" (which uses the same
  Open Food Facts lookup) remains as a fallback.

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

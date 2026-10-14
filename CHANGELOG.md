# Changelog

All notable changes to Launch-R are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

> Changes staged for the next release go here. Move them down when you cut a tag.

---

## [0.3.6] - 2026-10-14

### Added

* See-through drawer folders (Settings). Gives app drawer folders the same translucent look as home screen folders. It’s off by default, and it’s greyed out while “Match folder popup color” is on, because that setting takes priority.
* Match folder popup color (Settings, under “Dark home text”). When on, folders on the home screen, dock and app drawer use the same color as the open folder popup. It’s off by default.
* The dock now shows on each page card in the home menu, so the preview looks like your real home screen.
* Fastlane metadata folder.
* App Banner.
* Froid release!

### Changed

* AMOLED Black and White Minimal no longer force folders to be black or white; folders now use the theme’s default color options instead
* Material You now only changes the accent color (taken from your wallpaper) instead of replacing the whole theme, so Orange Factory, AMOLED Black and White Minimal keep their own surfaces and folder colors
* App drawer folders, including drawer search results, now use the open folder’s panel color by default instead of a separate drawer color. Custom folder colors are blended over the popup surface the same way the open panel does it.
* The open folder popup follows the closed folder’s style. In see-through mode the panel is translucent, and custom colors are used as-is. Its title and labels follow “Dark home text”.
* Refreshed app icon and uploaded app_icon_background
* Widgets on home menu page cards are now drawn at their real size, with their name, instead of a single small icon. Pages with a big widget no longer look empty.
* Home menu page cards are now announced with their position and default status (for example, "Home page 2 of 5, default") for screen readers.

### Fixed

* Folders looked like a different color when opened, in every theme. The closed icon and the open panel were colored by two separate calculations, and they now share one.
* Blur for folder popup giving out too much glare from apps.

---

<!--
HOW TO MAINTAIN THIS FILE

When you're ready to cut a new release:

1. Rename [Unreleased] to the new version and today's date, e.g.:
   ## [0.7.0] - 2026-07-15

2. Add a fresh empty [Unreleased] section at the top.

3. Use these section headers (only include the ones that apply):
   ### Added      — new features
   ### Changed    — changes to existing behaviour
   ### Deprecated — features to be removed in a future release
   ### Removed    — removed features
   ### Fixed      — bug fixes
   ### Security   — security-related changes

4. Keep entries short and user-facing. Write for someone reading the F-Droid
   update description, not for another developer reading the diff.

5. Commit the CHANGELOG update in the same commit as the pubspec version bump.
-->

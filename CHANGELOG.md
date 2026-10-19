# Changelog

All notable changes to Launch-R are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

> Changes staged for the next release go here. Move them down when you cut a tag.

### Added

* Hover an app over a folder in the app drawer for a moment and the folder opens as if the app were already in it. Drop it on a spot to place it there, or drop it anywhere on the panel to add it to the end. Move away and the folder closes again.
* Haptics for folders: a tick when a folder opens or closes, when you swipe or edge-flip between its pages, when you hover between apps while rearranging, and when you pick a folder color.
* Folder polish: the title and color dot fade in, the panel and color dot fade smoothly between colors, color swatches press in, apps dropped into a folder pop in with a short spring, and the panel resizes smoothly instead of jumping.
* Info sheet at bottom of settings sheet.
* App shortcuts: long-press an app to see its shortcuts (like Camera -> “Take selfie”) at the top of the menu. Only shows when Launch-R is your default launcher.

### Changed

* AMOLED Black now uses soft dark greys for settings, sheets, menus, folder panels and dialogs instead of pure black; App drawer remains pure black.

---

## [0.4.0] - 2026-10-18

### Added

* Hint in settings sheet under search telling you how "/" will show hidden apps.
* Haptic feedback when you pick up an app, folder or widget to drag it, and a lighter tap when you drop it.
* A light haptic tick each time you swipe over to another home screen page.
* Haptic feedback on the app drawer's mic, ✕ and three-dot menu buttons.
* New Gestures section in launcher settings.
* Home screen swipe left / swipe right gestures. When there’s no page to swipe to (swipe left on your last page, swipe right on your first), you can assign an action: open an app, recent apps, launcher settings, app drawer, app drawer search or the notification panel.
* Recent apps needs the Launch-R accessibility service (Android doesn’t let launchers open recents any other way). It subscribes to no events and can’t read your screen.
* Icons now pop in with a short spring when you drop them in a new spot.
* A light haptic tick when dragging to the edge of the screen flips the page, on the home screen and the app drawer.
* A light haptic tick when you drag an app, folder or widget into an empty spot on the home screen, dock or app drawer.
* Home screen and dock now show the same insert bar as the app drawer when you hold a dragged icon over the left or right edge of another icon. Drop it there to slot it in between; neighbours in that row shift over into the nearest empty spot (the middle of an icon still makes a folder).

### Changed

* App and folder icons now shrink slightly while you press them and spring back when you let go, so taps feel more responsive. Widgets are not affected.
* The app drawer's mic, ✕ and three-dot menu buttons get the same press-down effect.
* Moving apps and folders around now feels smoother, especially on slower phones.
* New app icon (all assets have been updated to match the new icon aswell).
* “Swipe up again to go home” and “Swipe up again to search” moved from Search to Gestures, under a new App drawer heading.
* Dragging an app over another app on the home screen or dock now waits a moment before showing the folder highlight, then gives a light tick when it’s ready to merge, just like the app drawer. Before, the highlight flashed on every app you dragged past.

### Fixed

* Fixed a rare case where quick back-to-back edits could leave your layout out of sync after a restart.
* Dropping an icon between others on a full dock or home row no longer throws an error; it falls back to a normal drop.

---

## [0.3.8] - 2026-10-16

### Added

* “Swipe up again to go home” setting (Settings, under “Search”). When the app drawer is fully open, swiping up on it closes the drawer and returns you to the home screen. Off by default.
* “Swipe up again to search” setting (Settings, under “Search”). When the app drawer is fully open, swiping up on it opens the keyboard so you can search. Off by default. Only one of the two swipe-up options can be on at a time.
* Voice search button in the app drawer search bar. Tap the mic to speak a search, and the results update right away. If your device has no speech recognizer, you'll see a short message instead.
* Clear button in the app drawer search bar. Once you've typed something, the mic turns into an ✕ that empties the search, brings back the full app grid and keeps the keyboard open.
* Settings to turn the search bar's mic and ✕ buttons on or off (Settings, under “Search”). Both are on by default.
* Search hidden apps by starting your search with a "/" For example, "/bank" searches all apps including hidden ones, and a lone "/" lists every hidden app. Hidden apps still stay out of normal search results.
* Suggestions and recent searches in the app drawer. Tap the search bar and, before you type anything, you'll see your most-used apps and your recent searches. Start typing and they disappear, Tap a recent search to run it again, tap its ✕ to remove it, or tap Clear to remove them all. (NOTE: If you have no history yet, you'll see the normal app grid.)
* Launch-R now remembers which apps you open. A search is only saved when you open an app from its results. Everything stays on your device, hidden apps are never suggested, and searches starting with "/" are never saved.
* Setting to turn suggestions and recent searches on or off (Settings, under “Search”). It's on by default.

### Changed

* See-through drawer folders is now on by default. If you've already changed this setting, your choice is kept.
* Tightened the spacing of the mic and three-dot menu buttons in the search bar so they sit closer together.

### Fixed

* Voice search mic no longer stops responding after a speech app fails to return a result. A stale request is now cleared, so the next tap starts fresh instead of doing nothing until Launch-R restarts.
* Voice search now checks for a speech recognizer before opening, and shows the "isn't available" message right away when none is found. This also works on Android 11 and newer, where Launch-R previously couldn't see speech apps such as FUTO Voice Input.

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

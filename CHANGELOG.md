# Changelog

All notable changes to Launch-R are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

> Changes staged for the next release go here. Move them down when you cut a tag.

### Added

* Customize-able hold animations; pick how an icon moves while you hold and drag it (Sway, Wiggle, Pulse, Bounce, Tilt) in (Settings -> Icons) with a live preview.
* Shortcuts in folders; drag a pinned shortcut onto an app, another shortcut or a folder on the home screen to group it.
* Legacy renderer; option found in (Settings -> System). Turns off Flutter's Impeller renderer, which stutters on some devices, especially with home screen widgets. Needs a restart to apply.

### TO-DO

* Allow home screen dock to utilize reccent apps when empty (option in settings default off). (to be done)
* Add option to hide action bar at top of screen when moving apps or folders in home menu. (to be done)
* Update screenshots and upload demo video or gif. (to be done)

---

## [0.4.8] - 2026-10-25

### Added 

* Loop live preview support for app drawer & home menu previews aswell as page indicator support for home menu live preview.
* Haptics for the home screen editor: widget resizing, resize handles, and the page manager.
* Sway animation when picking up and holding apps.
* Option to search for apps by package name / app id.
* Option to clear suggested apps and search history in search settings.
* Backup & restore (Settings -> System): save your settings, home screen and dock layout, folders, tags, hidden apps and history to a file, and load it back later or on another device. Widgets, pinned shortcuts, your custom font and your background image are NOT included.

### Changed

* Prevent Material you in "White Minimal" theme from changing the material you accent color darker then other themes.

---

## [0.4.6] - 2026-10-25

### Added

* Loop app drawer pages (Settings -> App drawer -> Pages): swiping past the last page of the app drawer wraps around to the first, and the other way round. Off by default. It only affects the app drawer; the home screen has its own option in Settings -> Layout.
* The live preview in (Settings -> Layout) now shows labels. Turning “Home screen labels” or “Dock labels” on or off updates the preview straight away, using the same placeholder bars as the app drawer preview.
* “Reduce animations” moved from (Settings -> Layout) to (Settings -> System).
* Haptics when you tap things in Settings: category rows, switches, option rows, back buttons, reset buttons and icon shape choices.
* Haptics when swiping through app drawer pages.


### Changed

* Dark home text & Hide status bar have their own header now called "HOME SCREEN DISPLAY" (Their location is still in appearance under Colors).
* App drawer settings (Settings -> App drawer): the grid section is now headed “APP DRAWER GRID” and sits above the live preview, with the Columns stepper directly under it. The separate “GRID” header is gone.
* “Loop pages” in Settings -> Layout is now called “Loop home screen pages” and says that it only applies to the home screen.
* App drawer and home menu have their own separate page indicators changed in thier respective settings (Layout for home menu & App drawer for app drawer).

---

## [0.4.4] - 2026-10-25

### Added

* Labels settings (Settings -> Layout): show or hide app names on the home screen, the apps screen and the dock separately. The dock labels are off by default, the other two are on.
* Page indicator style (Settings -> Layout): dots, a line, or hidden. Tapping a dot or a line segment on the home screen (or apps screen) now jumps straight to that page.
* Loop pages (Settings -> Layout): swiping past the last home page wraps around to the first, and the other way round. Off by default. While it is on, the pull-past-the-edge gestures don’t trigger because there is no edge.
* Grid steppers (Settings -> Layout): pick 3–6 columns and 4–8 rows for the home grid with a live preview and an Apply button.
* App drawer settings page (Settings -> App drawer, also in the drawer's ⋮ menu) with a live preview that shows the real number of rows and columns, labels, icon size, search bar and page indicator as you change them.
* Reduce animations (Settings -> Layout): skips transitions for a snappier feel on slower devices. The app drawer, home pages, folders, icons, home widgets, sheets and dialogs switch instantly, and the folder background blur is turned off. Off by default. It’s saved between launches and applies right away.
* Hide status bar option (Settings -> Appearance). Hides the clock, battery and signal icons while Launch-R is on screen. Off by default. Swipe down from the top edge to peek at it or pull the notification shade.
* Icon size setting in Settings -> Icons, a slider from 70% to 115% in 5% steps (default 100%) with a reset button. It’s saved between launches.
* Double tap to lock (Settings -> Gestures). Double tap an empty spot on the home screen or dock to turn the screen off. Off by default. Uses the Launch-R accessibility service (the same one as Recent apps; it still can’t read your screen) and needs Android 9 or newer.
* Indication for left and right gestures: while you pull past the first or last home page, a pill with the gesture’s icon slides in from that edge and fills with your accent color when you’ve pulled far enough to trigger it (with a small tick). Nothing shows if that side is set to “Nothing”.
* Gesture sensitivity slider in Settings -> Gestures (50%–150%). Higher means a shorter, lighter swipe triggers the home screen gestures; lower means you need to swipe further or faster.

### Changed

* Everything that only affects the app drawer now lives in its own settings page: columns, labels, remember app positions (plus a Tidy up apps button), search on open, suggestions, voice and clear buttons, and the swipe up again options. “Apps screen” is now called “App drawer” everywhere.
* Settings sheet rehaul: Launcher settings is now a short list of categories (Appearance, Text, Layout, Icons, Search, Gestures, System) and tapping one opens a sheet with just those settings. Swipe down or tap the back arrow to return to the list.
* Smoother app drawer search transition: when you tap the search bar, the app grid now fades out as the suggestions and recent searches fade in, instead of the grid vanishing instantly. Suggested apps and recent searches also glide in one after another.
* The drawer's search results now fade in and out over the grid in the same way.
* Sheet heights, title spacing and keyboard behavior is now consistent throughout the app.
* Removed about 190 lines of duplicate code


### Fixed

* The Icon size, Text size, and Gesture sensitivity sliders no longer shift when the reset button appears. Each row is now a fixed height with space always reserved for the button.
* The About row in Launcher settings now lines up with the category icons above it instead of sitting slightly to the left.
* The app drawer now stays on the page you were viewing after you search or dismiss the keyboard, instead of jumping back to the first page.
* The app grid no longer re-lays itself out while the keyboard slides up, which removes a small flicker behind the suggestions.

---

## [0.4.2] - 2026-10-20

### Added

* Hover an app over a folder in the app drawer for a moment and the folder opens as if the app were already in it. Drop it on a spot to place it there, or drop it anywhere on the panel to add it to the end. Move away and the folder closes again.
* Hover an app over a folder on the home screen or in the dock to open it, the same way as in the app drawer.
* Haptics for folders: a tick when a folder opens or closes, when you swipe or edge-flip between its pages, when you hover between apps while rearranging, and when you pick a folder color.
* Folder polish: the title and color dot fade in, the panel and color dot fade smoothly between colors, color swatches press in, apps dropped into a folder pop in with a short spring, and the panel resizes smoothly instead of jumping.
* Info sheet at bottom of settings sheet.
* App shortcuts: long-press an app to see its shortcuts (like Camera -> “Take selfie”) at the top of the menu. Only shows when Launch-R is your default launcher.
* Pinned shortcuts: apps that offer "Add to Home screen" shortcuts (Browsers, Settings & more) can now put them on your home screen. They get your icon shape with a small badge of the app they came from, open when tapped, can be dragged around or into the dock, and are removed with long-press -> Remove or the drag bar. Only works when Launch-R is your default launcher.

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

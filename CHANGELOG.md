# Changelog

## [2/11/2025]

### Added
- Movie Collections functionality
  - Added collections to movie details screen
  - View all movies in a collection including missing movies

### Changed
- Modified movie list sorting behavior
  - Removed "The" from title sorting consideration
  - Movies starting with "The" no longer grouped together
- Added new sort options in settings
  - Can now sort by title, release date, or date added

## [2/10/2025]

### Added
- Digital clock display
  - Added to main screen (bottom left)
  - Added to movie poster panel
  - Added to TV show poster panel
  - Added to season poster panel
  - Added to episode poster panel

- Added auto-sync functionality
  - Added background sync scheduling service
  - Added toggle for enabling/disabling auto-sync
  - Added time picker for scheduling daily syncs
  - Added sync status checker to view last and next sync times

- Added genre functionality
  - Added genre to tmdb sync service
  - Added genre to metadata information panels
  - Added genre searching capability in search screen

### Changed
- Modified initial focus behavior in movie list panel and TV show list panel
  - Changed focus to start on the first title instead of the alphabet bar
- Modified voice input timeout duration
- Added year to movie list view items
- Removed full sync button from settings panel
- Forced 280 dpi density for uniformity accross devices.


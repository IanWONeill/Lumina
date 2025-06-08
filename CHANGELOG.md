# Changelog

## 1.0.9 [6/08/2025]

### Changes
- Fixed new episode check breaking everything
- Fixed weird graphical bugs

## 1.0.8 [4/24/2025]

### Changes
- Cleaned up the search query
- Added error messages for syncing
- Added storage check on startup
- Fixed show names and overview updates
- Made shows and genre search ignore "the"

## 1.0.7 [4/19/2025]

### Fixes
- Fixed streams sometimes loading incorrectly

## 1.0.6 [4/16/2025]

### Fixes
- Fixed lists not updating after a sync
- Fixed anime show names being in japanese

## 1.0.5 [3/8/2025]

### Added
- Added Trakt as a list provider
- Added TVDB as a metadata provider for anime shows

## 1.0.4 [2/27/2025]

### Added
- Added an auto updater

## 1.0.3 [2/25/2025]

### Changed
- Added drama, history, crime, mystery as genre filters
  - Changed genre screen from 2 rows to 3 to better fit all the genres
- Added a few more sizes for torrentio filters

### Fixes
- Fixed torrentio filters not working with sizes below 1GB
- Fixed wrong syntax for the sql query for collections
- Fixed the duplicates that would show for some sollections

## 1.0.2 [2/19/2025]

### Added
- Torrentio integration
  - Added Torrentio support
  - Implemented customizable Torrentio stream filters
- RSS feed ticker
  - Added to home screen
  - Displays movie/TV show release feeds(customizable)
  - Add up to 3 feeds
- Database statistics
  - Added movie/TV show counter on home screen
  - Displays total movies or shows in your database
- Exit Dialog
  - Added dialog to ask if you want to exit the app

### Changed
- Enhanced Collections feature
  - Integrated Wikidata for expanded collection information
  - Note: May result in some duplicate collection entries
- Modified database cleanup
  - Items are now removed after 5 syncs if not present in Simkl lists
  - Improves database accuracy with Simkl list changes

## 1.0.1 [2/11/2025]

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

## 1.0.0 [2/10/2025]

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

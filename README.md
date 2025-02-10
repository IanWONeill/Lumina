# Lumina - Media Streamer & Library Manager 🎬

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue.svg)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20|%20iOS%20|%20Web-brightgreen.svg)](https://flutter.dev/multi-platform/)

A Flutter-based media streaming application that fetches streams from Premiumize using Orionoid and plays them. The UI is modeled after Kodi skins' list views, with potential for additional view options like poster view.


## ✨ What Makes Lumina Different?

Unlike other streaming apps such as Stremio or Syncler, Lumina is designed with a focus on simplicity, and full local control over your media library. Here's how Lumina stands out:

✅ Fully Local Metadata Storage: Unlike apps that rely on cloud services for metadata, Lumina stores all movie and show metadata locally in a folder on your device (Player_Files), making it easy to back up and restore without needing external servers.

🔐 No External Add-ons or Scrapers: Stremio and Syncler rely on third-party add-ons and scrapers to fetch sources, which can be inconsistent or require additional setup. Lumina fetches direct links via Orionoid.

🔄 Simkl Integration for Watchlist Management: Unlike Stremio, Lumina uses Simkl for managing your library, with a straightforward syncing process that pulls your planned movies and shows into the app automatically. This makes it so your library it customized to you. No more having a homescreen with 90% of stuff that isnt interesting to you.

🎥 Custom JustPlayer Integration: Lumina integrates with a modified version of JustPlayer, allowing for seamless tracking of playback progress, this modified version of justplayer is made to be the absolute simplest it could possibly be, good for those that are not tech savy.

🎮 Built with flutter/dart: Being wrote in flutter/dart allows this app to be modular in terms of what devices it will run on. other apps are generally only specific for 1 platform such as pc or android, Lumina will run on windows,android,ios,and even as a website/html. 
*some modifications will need to be made for these other platforms due to me hardcoding some android paths. this change would be very simple if someone was to do it.*


## ✨ Current Features
### 📺 Media Library Management

    Fetches a Simkl watchlist and retrieves metadata from TMDB.
    Stores metadata in a folder named Player_Files on the device's internal storage for easy backup.
    Note: Requires storage permissions for metadata management.

### 🔗 Stream Fetching & Playback

    Authenticates using Orionoid's API to fetch streaming links.
    Sends links to JustPlayer for playback on your device.

### 🎥  User Interface

    Movies Screen and TV Shows Screen displayed in a list view with posters, titles, and information.
    Mark episodes or movies as "watched" to track progress. Movies will also auto mark themselves after watching.
    Quick Navigation Bar for jumping to specific letters in your library.

### 🔍 Search Functionality

    Search your library for movies or TV shows.

### ⚙️ Settings

    Customize Orionoid search results for better more tailored files for specific qualities or languages.

### 📱 Supported Platforms

Currently tested on a ONN. Google TV 4K Pro, but should work on most Android TV devices.

Built with Flutter, Lumina theoretically supports:

    Android
    iOS
    Web
    Windows

Note: The app currently has hardcoded paths for Android. Modifications are needed for other platforms if you wanted to build for another one.

### 🛠️ Building the Project

    Set up Android Studio and Flutter.
    Run the following commands:

# Generate required files
flutter pub run build_runner build --delete-conflicting-outputs

# Build the APK
| Platform | Command |
|----------|---------|
| Android  | `flutter build apk --release` |
| iOS      | `flutter build ios --release` |
| Web      | `flutter build web --release` |
| Note: | If you want to build a debug version remove - -release |

🚀 Setup Instructions

    Grant the app storage permissions.

    Install JustPlayer on your device.
	NOTE: this app expects specific intents that were added to my custom justplayer. these intents are for tracking play progress thus is needed: https://github.com/Spark-NV/Player

    Add your API keys to the Debrid_Player/api_keys.txt file:
    Copy

    tmdb_api_key = your_key_here
    orion_app_key = your_key_here
    simkl_api_key = your_key_here

    Build your Simkl library:

        Add movies/shows to your "Plan to Watch" list.

        Optionally, import existing lists from something like trakt.
		NOTE: I might incorporate trakt in the future but dont count on it.

    Open the app and authorize Simkl and Orionoid to get the tokens so the app can interact with the 2 services.

    Use the "Sync" button to fetch new content from your Simkl watchlist.

    So the process for adding movies or shows will be you use simkl and find any movies or shows you want and add them to your plan to watch list. then in Lumina you use the sync button to have it find any new movies or tvshows you added.

    You must link your premiumize account and orionoid account in the user panel on orionoids website.

### 🤝 Contributing

Contributions are welcome! If you'd like to improve Lumina, here are some ideas:

    Add Trakt integration as an alternative to Simkl.

    Add actor searching within the preplay screen(selecting an actor would bring up all other movies/shows they are in.)

    Introduce more view options like poster view.

    Support additional debrid services.

    Add other video player options. Other options would need ways of tracking play progress.

### 📸 Screenshots

Note: These screenshots were taken using the Android Studio tablet emulator, so scaling may differ on actual Android TV devices.

![Alt text](Screenshots/Homescreen.png)
![Alt text](Screenshots/Movies_screen.png)
![Alt text](Screenshots/Pre_Play_Screen.png)
![Alt text](Screenshots/TVShows_Screen.png)
![Alt text](Screenshots/Episodes_Screen.png)

### As stated it looks different on an AndroidTV here is a pic of it running on mine:

https://i.imgur.com/2YfomT6.jpeg


### 📜 License

Distributed under the MIT License. See LICENSE for more information.
🙏 Acknowledgments

    Flutter Team for the amazing framework.
    Orionoid for their comprehensive media API.
    Simkl for watchlist management.
    TMDB for metadata.
    moneytoo for his JustPlayer

### 📌 Suggestions for improvement are welcome
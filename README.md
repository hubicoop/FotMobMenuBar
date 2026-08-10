# FotMob Menu Bar

A minimal native macOS menu bar app for following live football scores and favorite teams. It refreshes every 30 seconds while matches are live, sends goal notifications, and lets you pin a live match score to the menu bar.

## Features

- Live scores and match minutes
- Favorite team summaries with previous and upcoming fixtures
- Goal notifications for favorite teams
- Selectable live score widget in the menu bar
- Today's matches from Europe's Top 5 leagues
- Dark minimal interface
- Direct links to FotMob match pages

## Build

Requires macOS 13 or later and Swift 6. A full Xcode installation is not required.

```sh
cd ~/FotMobMenuBar
./Scripts/build-app.sh
open dist/FotMobMenuBar.app
```

Grant notification permission on first launch. The app runs exclusively in the menu bar; open the FotMob icon to search for teams and manage favorites.

## Launch at Login

After moving the app to the `Applications` folder, add it from **System Settings > General > Login Items**.

## Data Source

Data is retrieved from endpoints publicly accessible to the FotMob web client. FotMob does not provide an official public API, so these endpoints may change in the future. This project is not affiliated with or endorsed by FotMob.

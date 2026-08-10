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

## Screenshots
<img width="424" height="530" alt="Screenshot 2026-08-10 at 16 11 50" src="https://github.com/user-attachments/assets/8a3d0be9-01b5-4d0d-adb6-b517ffa95ba2" />

<img width="684" height="32" alt="Screenshot 2026-08-10 at 16 12 07" src="https://github.com/user-attachments/assets/e3aa4714-f99a-4d16-85b1-e2a2dd7893fd" />



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

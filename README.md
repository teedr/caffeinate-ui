# Caffeinate UI

A macOS menu-bar app for `/usr/bin/caffeinate`. Click the coffee cup to keep your Mac awake until you stop it, for 15 minutes, 1 hour, or 2 hours, or while a selected app is open. The cup fills in during a session. Open the menu to see when it ends or to stop it early.

For Codex from your phone, open **While App Is Open** and choose **ChatGPT**. Leave the Mac online with its lid open. Sessions work on battery or power and allow the display to sleep.

## Build and run

On macOS 13 or later with Apple’s Command Line Tools installed, build and open the app with `make run`.

The app opens in the menu bar. You can also double-click `build/Caffeinate UI.app` in Finder or copy it to Applications. Quitting Caffeinate UI ends its session.

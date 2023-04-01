# WebViewScreenSaver
[![GitHub release](https://img.shields.io/github/v/release/jwells89/webviewscreensaver)](https://github.com/jwells89/webviewscreensaver/releases)

A macOS screen saver that displays a web page or a series of web pages.

This is a fork of the [original by liquidx](https://github.com/liquidx/webviewscreensaver) that makes the following changes:
- Fixes several deprecations (e.g. replacing `NSURLConnection` with `NSURLSession`)
- Sets the webview’s user agent string to that of Safari so more pages render correctly (many sites treat the default user agent as an obsolete browser)
- New thumbnail that’s a bit more eye-catching (no retina unfortunately - a 2x thumbnail is supplied, but a bug in the screen saver prefpane prevents it from rendering)
- Minimum macOS version raised to 12.0 Monterey


## Installation

Download the latest [release](https://github.com/jwells89/webviewscreensaver/releases), unpack and double-click to install. Binary is signed and notarized so gatekeeper shouldn’t grouch at you.


## Configuration

Open up System Preferences > **Desktop and Screen Saver** > Screen Saver and **WebViewScreenSaver** should be at the end of the list.

In the addresses section fill in as many websites as you want the screensaver to cycle through and the amount of time to pause on each.

**Tip**: To edit a **selected** row, click **once** or tap **Enter** or **Tab**.

Passing in a negative time value e.g. `-1` will notify the screensaver to remain on that website indefinitely.

Need some website ideas? Check out suggestions in the [examples](examples.md) section.

Local **absolute** paths can also be used as an address with or without the `file://` schema.

E.g. `file:///Users/myUser/mySreensaver/index.html`

**Note**: If you are running **Catalina** or newer the provided path cannot reside in your personal folders which require extra permissions (this includes things like *Downloads*, *Documents* or *Desktop*) but can be anywhere else in your user's folder.

### Configuration for IT
If you are interested in scripting configuration changes, WebViewScreenSaver, like most other screensavers, makes use of the macOS `defaults` system.

This can be queried and updated via:
``` bash
defaults -currentHost read WebViewScreensaver
```
or directly *(if installed for current user or should find it in `/Library` otherwise)*
``` bash
/usr/libexec/PlistBuddy -c 'Print' ~/Library/Preferences/ByHost/WebViewScreenSaver.*
```

## License
Code is licensed under the [Apache License, Version 2.0 License](LICENSE.md).

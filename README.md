# MenuBarCalendar

A minimalist macOS menu bar app that shows your upcoming calendar events.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **Lives in the menu bar** — shows next meeting title and countdown (e.g., "Team Standup in 12m")
- **Multiple calendars** — connects to all calendars via Apple EventKit (iCloud, Google, Outlook, etc.)
- **Real-time updates** — auto-refreshes every 30 seconds and reacts to calendar changes instantly
- **Today's agenda** — dropdown lists all remaining events for the day with color-coded calendar indicators
- **Smart notifications** — configurable reminder before each event (default: 10 minutes)
- **Urgency colors** — countdown turns red (≤5 min), orange (≤15 min) for approaching events
- **No dock icon** — runs silently in the background

## Build

Requires macOS 13+ and Xcode Command Line Tools.

```bash
git clone https://github.com/adityajain07/MenuBarCalendar.git
cd MenuBarCalendar
bash build.sh
```

## Run

```bash
open build/MenuBarCalendar.app
```

On first launch, macOS will prompt for **calendar access** and **notification permission** — grant both.

## Install

```bash
cp -r build/MenuBarCalendar.app /Applications/
```

## Privacy

This app reads calendar data locally via Apple's EventKit framework. No data is sent anywhere. No API keys or accounts required.

## License

MIT

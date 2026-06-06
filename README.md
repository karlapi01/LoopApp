# Loop

A multiplayer running app for iOS where the goal isn't just distance, it's territory.

Run a closed loop anywhere in the world, and the area you enclosed becomes yours. The runner who claims the most land wins.

---

## What it does

Loop lets a group of runners share one app and compete by claiming territory. Each runner gets a unique colour when they sign up. When you finish a run that starts and ends within 50 metres of each other, the enclosed area is calculated, filled in your colour on the map, and added to your total. The leaderboard ranks everyone by how much land they've claimed.

Runs that don't close into a loop are still saved to your history, they just don't count toward the contest.

---

## File structure

### App
| File | Description |
|------|-------------|
| `RunTrackerApp.swift` | App entry point. Checks whether a user has entered the access code and selected a profile, then routes to either the login flow or the main tab view. |
| `Info.plist` | iOS configuration file. Contains the location permission descriptions required for GPS tracking. |

### Models
| File | Description |
|------|-------------|
| `Models.swift` | Data models for the app. `Activity` stores a saved run; its date, distance, duration, GPS coordinates, enclosed area, and whether it formed a closed loop. `Profile` stores a runner's name, join date, and assigned colour. |
| `TrackingManager.swift` | Handles all GPS logic during a run. Manages recording state (idle, recording, paused), collects location updates, filters out inaccurate points, calculates live distance, and runs the elapsed time timer. |
| `GeoMath.swift` | Geographic calculations. Determines whether a route forms a closed loop (within the 50 m threshold), and calculates the enclosed area in square metres using an equirectangular projection and the shoelace formula. |
| `AccessCodes.swift` | Holds the set of valid access codes for the app. Only people with a code can unlock Loop. |

### Views
| File | Description |
|------|-------------|
| `MainTabView.swift` | The root tab bar with four tabs: Record, Runners, History, and Leaderboard. Applies the warm cream theme to the tab bar appearance. |
| `EntryFlowView.swift` | The entry screens. `AccessCodeView` shows the cycling red/orange/pink login screen where users enter their code. `ProfileSetupView` lets users select an existing runner profile or create a new one. |
| `HomeView.swift` | The main recording screen. Shows a blurred map with the user's live route and a live-filling polygon in their colour. Displays distance, time, and enclosed area while recording. Start, Pause, Resume, and Stop controls. |
| `UsersView.swift` | Lists all runners on the app with their assigned colour, run count, and join date. Shows a "YOU" badge next to the active profile. Includes a log out button. |
| `HistoryView.swift` | Shows all runs saved by the current user, newest first. Closed loops show their claimed area in a yellow badge. Tapping a run opens a full map view with the route or filled polygon and animated stats. |
| `LeaderboardView.swift` | The contest screen. Shows a combined map with all claimed territories filled in each runner's colour, and a ranked list of runners sorted by total area claimed. |

### Design
| File | Description |
|------|-------------|
| `DesignSystem.swift` | Central design tokens for the whole app — the warm cream/butter-yellow/terracotta colour palette, typography helpers, layout constants, and reusable components (`DSRule`, `DSButton`, `DSCard`). |
| `Animations.swift` | All animation primitives: staggered word reveals, counting numbers, glitch effects, scroll-reveal entrance transitions, ambient opacity pulses, mechanical push transitions, and the golden scan-line that sweeps each screen on appear. |
| `ColorHex.swift` | A small extension on SwiftUI's `Color` that lets any colour be initialised from a hex string, e.g. `Color(hex: "F5C842")`. |

---

## How the contest works

1. Each runner signs in with an access code and gets a unique colour
2. Start a run from the Record tab
3. Run any route; a park, a block, a field, and return close to where you started
4. If your finish point is within 50 m of your start, the loop closes
5. The enclosed area is calculated and added to your total on the Leaderboard
6. The runner with the most total area claimed wins

---

## Tech

- Swift + SwiftUI
- SwiftData for local persistence
- CoreLocation for GPS tracking
- MapKit for map rendering, route polylines, and filled territory polygons
- Minimum iOS 17

---

## Access

The app is code-gated — users need a valid access code to unlock it. Codes are managed in `AccessCodes.swift`.

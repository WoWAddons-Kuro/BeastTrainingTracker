# Beast Training Tracker (Kuro) 1.5.0-kuro.1

Fork of Socks' Beast Training Tracker 1.5.0, renamed so it can be installed
next to the original without collisions.

### Changed
- Addon folder / TOC is `BeastTrainingTracker.Kuro`. Every global is renamed: SavedVariables are `BeastTrainingTrackerKuroDB` / `...Backup` / `...Seen`, slash commands are **`/bttk`** and `/beasttrainingkuro`, and all named frames, the LibDataBroker object and the HereBeDragons pin groups carry a `Kuro` suffix. Saved data from the original addon is **not** picked up; use Backup → Export / Import to move it over.

### Added
- **Only run on Hunters** (Settings, default on). On any other class the addon does nothing - no scans, alerts, map pins, zone tracker, pet XP bar or tooltip lines. Only the main window (locked to the Settings tab) and the minimap button stay, so the option can be turned back off. `/bttk` on a non-hunter prints a hint instead of running commands.

---

# Beast Training Tracker 1.5.0

### Added
- **Special Pets drawer:** click a pet to slide out a drawer beside the window with a rotating 3D model (drag to turn, mouse wheel to zoom) and everything about it: type, family, level, zone, attack speed, traits, respawn time, what its family can learn, what it teaches, tamed status and RareScanner timers, plus Waypoint and Mark tamed buttons. Shift-click a pet for a waypoint straight away.
- Respawn times for about 110 special pets, from the CMaNGOS Classic database. These are classic values, so WoW Forever may differ. RareScanner's live timers are shown too when it's installed.

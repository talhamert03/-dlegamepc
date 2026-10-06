# Steam achievements

The game already unlocks achievements through GodotSteam (`SteamService._on_achievement` -> `setAchievement` +
`storeStats`). Achievements earned while Steam was not running are pushed 5 s after start
(`SteamService.sync_achievements`, skips ones Steam already has).

## Steamworks setup (once)

1. App Admin -> Stats & Achievements -> Achievements: add one entry per row of
   `steam/achievements/achievements.csv` (41 rows).
   - API Name = `api_name` (must match `data/achievements.json` ids exactly; a unit test checks the format).
   - Display name / description: English as the default language, Turkish in the localisation fields.
   - Achieved icon = `<id>.jpg`, unachieved icon = `<id>_locked.jpg` (256x256, in the same folder).
   - Hidden: off (they are progression goals).
2. Publish the changes, then test with a Steam build: unlock one in game and check the Steam overlay.

## Regenerating the kit

`cd game && python3 tools/gen_steam_achievements.py` rebuilds icons and the CSV from `data/achievements.json`
(add new achievements there first).

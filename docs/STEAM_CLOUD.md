# Steam Cloud

The game mirrors its save to Steam Remote Storage itself (GodotSteam `fileWrite` / `fileRead`), so no
Auto-Cloud path rules are needed.

Steamworks partner site -> App Admin -> Steam Cloud:
- Enable Steam Cloud, byte quota per user: 5 MB, number of files per user: 5 (one save, some headroom).
- Do **not** add Auto-Cloud root paths (the game handles it; both together would fight).

Behaviour (`GameState.save_game` / `pull_cloud`):
- Local save first (with .bak1-3 rotation), then the cloud copy at most every 2 minutes and always on quit.
- On start the cloud copy wins only if it is valid (checksum) and newer than the local save by more than 5 s;
  the replaced local file is kept as `slot_0.json.before_cloud`.
- Settings -> Oyun -> Sistem has a "Steam Bulut Kayıt" switch (on by default) and a status line.
- Without Steam everything works locally as before.

Not tested on real Steam yet (needs the app id and GodotSteam in the Windows build).

# Constraints

## Foreign Key Constraints

| Foreign Key | ON DELETE | Reason |
|---|---|---|
| `match_participants.player_id` → `players.player_id` | RESTRICT | A player's match history is permanent telemetry, so a player cannot be deleted while their participation records exist. |
| `match_participants.match_id` → `matches.match_id` | CASCADE | A participation record has no meaning without its match, so removing a match removes its participant rows with it. |
| `match_modes.match_id` → `matches.match_id` | CASCADE | A match-to-mode link only describes that match, so it should disappear when the match does. |
| `match_modes.game_mode_id` → `game_modes.game_mode_id` | RESTRICT | Game modes are reference data used by historical matches, so a mode cannot be removed while any match still uses it. |

### Why each ON DELETE choice was made

**Deleting a player (RESTRICT on `match_participants.player_id`)**
This rule governs what happens when a player account is removed from the platform, for example when a user closes their account or an admin tries to clean up old players. With RESTRICT, the database refuses to delete any player who has played at least one match. The records protected by this choice are the player's own match history and, just as importantly, the match records of everyone they played against. If CASCADE were used instead, deleting one player would silently erase every participation row they had, so past matches would suddenly show fewer participants, leaderboards and averages would change after the fact, and opponents' match histories would have gaps. SET NULL is not an option either, because `player_id` is NOT NULL and a score with no player attached is meaningless. RESTRICT forces the removal of a player to be a deliberate decision, such as anonymizing the display name instead of deleting the row.

**Deleting a match (CASCADE on `match_participants.match_id`)**
This rule governs what happens when a match record is removed, such as a test match, a duplicate created by an ingestion error, or a match voided because of cheating. With CASCADE, every participant row for that match is deleted automatically. The affected records are only the rows that describe that one match, so nothing outside it is lost. Under RESTRICT, an admin would have to find and delete every participant row by hand before the match could be removed, and if that step were done in the wrong order or skipped, the invalid match would stay in the data and keep feeding bad numbers into analysis.

**Deleting a match (CASCADE on `match_modes.match_id`)**
This is the same event seen from the mode side. When a match is removed, its entries in `match_modes` are removed with it, since a row saying "this match was played in this mode" cannot exist without the match. Under RESTRICT, a voided or duplicate match could not be deleted until its mode links were cleared manually, which adds a step that exists only to satisfy the database, not to protect any real data.

**Deleting a game mode (RESTRICT on `match_modes.game_mode_id`)**
This rule governs what happens when the platform retires a game mode, for example a limited-time event mode. With RESTRICT, a mode cannot be deleted while any match references it, so historical matches keep an accurate record of how they were played. If CASCADE were used, deleting a retired mode would strip that mode from every past match, leaving matches with no mode at all and making any per-mode analysis (average duration by mode, ranked vs. casual by mode) quietly wrong. The better approach for a retired mode is to keep the row and stop assigning it to new matches.

## CHECK Constraints

**`CHECK (score >= 0)` on `match_participants.score`**
This constraint makes a negative score unstorable. A score below zero has no valid meaning in this system, so any negative value would corrupt totals, averages, and rankings. Without the check, a negative score could enter the database in several realistic ways: a bug in the game client or telemetry pipeline sending a bad value, penalty logic that subtracts points without stopping at zero, a developer using `-1` as a placeholder for "did not finish" or "no score recorded," or a simple typo during manual data entry. The CHECK constraint rejects these at insert time instead of letting them surface later as wrong statistics.

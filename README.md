<img width="860" height="564" alt="game-telemetry-erd" src="https://github.com/user-attachments/assets/0b48ea01-be24-4dd2-b3c5-3a8d1d114adf" />

# EX603GameTelemetryDatabase
Derek Campbell, Game Telemetry, A relational schema that tracks player participation, scores, and game modes across matches in a multiplayer game telemetry platform.

This platform models the backend data layer for a multiplayer game's telemetry pipeline — the system responsible for recording what happened in every match, who played in it, and how they performed. Rather than storing raw gameplay logs, it captures the structured facts a game studio actually needs for analytics: which players (players) took part in which matches (matches), what game modes each match was tagged with (game_modes via match_modes), and the outcome of each player's participation (match_participants), including their score and when they played.

The design centers on match_participants as the high-volume fact table, since every meaningful analytics question in this domain ultimately traces back to individual participation events. Matches themselves carry filtering attributes like whether they were ranked and how long they lasted, while game modes act as a flexible tagging system rather than a single fixed category, reflecting how modern games layer multiple overlapping labels (ranked, map type, seasonal events) onto the same match.

This schema needs to answer questions such as: Which players are most active, and how does their engagement trend over time? What is the average score per game mode, and do ranked matches produce different score distributions than casual ones? How many distinct players participate in a given match, and which combinations of game modes see the highest player turnout? Answering these requires efficient joins between the fact table and its surrounding dimension/reference tables, which is exactly what the primary keys, foreign keys, and constraints in this schema are built to support.

## Schema

The database has five tables. Three store core entities, and two connect them.

| Table | What it stores |
|---|---|
| `players` | One row per player account, identified by `player_id` with a display name. |
| `matches` | One row per match, including its name, whether it was ranked, and how long it lasted in minutes. |
| `game_modes` | Reference list of game modes a match can be tagged with. |
| `match_participants` | One row per player per match, recording the player's score and when they played. This is the main fact table. |
| `match_modes` | Junction table linking matches to game modes. |

See the [ERD](schema/erd.png), the full [SQL definition](schema/schema.sql), and the [constraint rationale](schema/constraints.md).

### Design decisions worth noticing

**`match_participants` is the center of the design.** Almost every analytics question (top scorers, player activity, match turnout) comes back to who played in which match and how they did, so that information lives in one high-volume table instead of being spread across players and matches. It uses its own surrogate key, `participant_id`, so each participation record can be referenced directly.

**Matches and game modes are many-to-many.** A match can carry more than one mode tag, and a mode is shared by many matches, so the relationship is stored in `match_modes` rather than as a single column on `matches`. Its primary key is the composite `(match_id, game_mode_id)`, which prevents the same mode from being attached to the same match twice.

**Delete rules protect history but clean up dependents.** Deleting a match cascades to its participant and mode rows, because those rows describe only that match. Deleting a player or a game mode is restricted while any match references them, so historical results are never silently erased. The reasoning for each rule is in `constraints.md`.

**Scores cannot be negative.** A `CHECK (score >= 0)` constraint blocks bad values from the game client or ingestion pipeline before they reach analysis.

**Ranked status is a flag, not a mode.** `is_ranked` is a boolean on `matches` with a default of `FALSE`, since every match is either ranked or not. Game modes are kept separate because they are an open-ended list that can grow over time.

**`played_at` is stored per participant.** The timestamp sits on `match_participants` rather than `matches`, so each player's participation is recorded with its own time, which supports activity analysis per player.

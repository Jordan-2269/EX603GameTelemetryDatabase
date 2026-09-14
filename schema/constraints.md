players

PRIMARY KEY: player_id — uniquely identifies each player; required for match_participants to reference a specific player.
NOT NULL: display_name — a player record with no identifying name is not usable for reporting or display.

matches

PRIMARY KEY: match_id — uniquely identifies each match; required for match_participants and match_modes to reference a specific match.
NOT NULL: match_name — a match needs a human-readable label for lookup and reporting.
NOT NULL: is_ranked, duration_minutes — these are required filtering attributes for the producer role; leaving them null would break filtering/aggregation queries that rely on them.

match_participants

PRIMARY KEY: participant_id — uniquely identifies each participation event, since a player can appear in many matches and a match has many players.
FOREIGN KEY: player_id → players.player_id
ON DELETE RESTRICT — this is the high-volume fact table your aggregate stats and leaderboards depend on. If a player were deleted, cascading would silently erase historical match results, corrupting analytics that depend on complete event history. Blocking the delete forces an explicit decision (e.g., anonymize the player record) rather than losing data by accident.
FOREIGN KEY: match_id → matches.match_id
ON DELETE CASCADE — a participation row only has meaning in the context of a specific match. If the match itself is deleted, its participant rows have no independent purpose and should be removed automatically to avoid orphaned records.
NOT NULL: played_at, score — every recorded participation event must have a timestamp and a metric value, since these are the fields being aggregated.

game_modes

PRIMARY KEY: game_mode_id — uniquely identifies each mode/category.
NOT NULL, UNIQUE: mode_name — mode names should be distinct and always present so catalog entries stay meaningful and non-duplicated.

match_modes

PRIMARY KEY (composite): (match_id, game_mode_id) — prevents the same match from being tagged with the same mode twice, while still allowing a match to have multiple modes and a mode to apply to multiple matches.
FOREIGN KEY: match_id → matches.match_id
ON DELETE CASCADE — this is a pure junction row; if the match is deleted, its mode associations are meaningless and should disappear with it.
FOREIGN KEY: game_mode_id → game_modes.game_mode_id
ON DELETE RESTRICT — game_modes is a reference/catalog table. Deleting a mode still linked to existing matches would silently break historical categorization; the delete should be blocked until the mode is reassigned or unlinked.

<img width="860" height="564" alt="game-telemetry-erd" src="https://github.com/user-attachments/assets/0b48ea01-be24-4dd2-b3c5-3a8d1d114adf" />

# EX603GameTelemetryDatabase
Derek Campbell, Game Telemetry, A relational schema that tracks player participation, scores, and game modes across matches in a multiplayer game telemetry platform.

This platform models the backend data layer for a multiplayer game's telemetry pipeline — the system responsible for recording what happened in every match, who played in it, and how they performed. Rather than storing raw gameplay logs, it captures the structured facts a game studio actually needs for analytics: which players (players) took part in which matches (matches), what game modes each match was tagged with (game_modes via match_modes), and the outcome of each player's participation (match_participants), including their score and when they played.

The design centers on match_participants as the high-volume fact table, since every meaningful analytics question in this domain ultimately traces back to individual participation events. Matches themselves carry filtering attributes like whether they were ranked and how long they lasted, while game modes act as a flexible tagging system rather than a single fixed category, reflecting how modern games layer multiple overlapping labels (ranked, map type, seasonal events) onto the same match.

This schema needs to answer questions such as: Which players are most active, and how does their engagement trend over time? What is the average score per game mode, and do ranked matches produce different score distributions than casual ones? How many distinct players participate in a given match, and which combinations of game modes see the highest player turnout? Answering these requires efficient joins between the fact table and its surrounding dimension/reference tables, which is exactly what the primary keys, foreign keys, and constraints in this schema are built to support.

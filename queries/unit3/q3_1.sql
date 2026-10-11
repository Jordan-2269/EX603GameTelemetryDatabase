-- ============================================================
-- Task 3.1: Establish what the data contains
-- Dataset: ex603_gaming (Multiplayer Game Telemetry / Live Ops)
--   producers = matches, events = match_participants, actors = players
-- ============================================================


-- ------------------------------------------------------------
-- Requirement 1: Find active, highly rated producers.
-- Question: Which ranked matches drew the most players?
--   (Theme filter from the appendix: is_ranked = 1 AND player_count >= 8.
--    is_ranked is a BOOLEAN in PostgreSQL, so "= 1" is written as
--    "= TRUE". Sorted by player_count, highest first, first ten only.)
-- What it told me: 9 matches qualify (Match_01, 02, 04, 05 with 16
--   players; Match_08 and 10 with 14; Match_11 with 10; Match_13 and 14
--   with 8). LIMIT 10 returns all of them.
-- ------------------------------------------------------------
SELECT match_id,
       match_label,
       server_region,
       player_count
FROM matches
WHERE is_ranked = TRUE
  AND player_count >= 8
ORDER BY player_count DESC, match_label
LIMIT 10;


-- ------------------------------------------------------------
-- Requirement 2: Find all possible event statuses.
-- Question: What values appear in the participation status column?
-- What it told me: there are three statuses, not two. Besides
--   'finished' (156) and 'abandoned' (34), there is 'contested' (10).
--   Any rate that only counts finished vs. abandoned leaves out the
--   contested rows, so they need to be handled deliberately.
-- ------------------------------------------------------------
SELECT DISTINCT participation_status
FROM match_participants
ORDER BY participation_status;


-- ------------------------------------------------------------
-- Requirement 3a: Filter events using a numeric range.
-- Question: Which participations scored between 20 and 40 points?
-- What it told me: 76 of the 200 participations fall in this range.
-- ------------------------------------------------------------
SELECT participation_id,
       player_id,
       match_id,
       score
FROM match_participants
WHERE score BETWEEN 20 AND 40
ORDER BY score DESC;


-- ------------------------------------------------------------
-- Requirement 3b: Filter events using an explicit list with IN.
-- Question: Which participations ended because of a server-side or
--   network problem rather than the player's own choice?
-- What it told me: 20 participations ended with 'Network timeout'
--   or 'Server restart'.
-- ------------------------------------------------------------
SELECT participation_id,
       player_id,
       match_id,
       participation_status,
       disconnect_reason
FROM match_participants
WHERE disconnect_reason IN ('Network timeout', 'Server restart')
ORDER BY disconnect_reason, participation_id;


-- ------------------------------------------------------------
-- Requirement 4a: Find producers whose names match a text pattern (LIKE).
-- Question: Which matches have a label in the Match_10 to Match_19 range?
-- What it told me: Match_10 through Match_15 (6 matches).
--   Note: in LIKE, "_" is a wildcard for any single character, so it
--   is escaped here to match a literal underscore.
-- ------------------------------------------------------------
SELECT match_id,
       match_label
FROM matches
WHERE match_label LIKE 'Match\_1%'
ORDER BY match_label;


-- ------------------------------------------------------------
-- Requirement 4b: Identify records where a reason is missing (NULL),
--   and replace it with a readable label using COALESCE.
-- Question: For every participation, why did the player disconnect?
-- What it told me: 166 rows have no disconnect_reason. All of them are
--   'finished' or 'contested', which is expected (they did not
--   disconnect). All 34 'abandoned' rows do have a reason.
-- ------------------------------------------------------------
SELECT participation_id,
       participation_status,
       disconnect_reason,
       COALESCE(disconnect_reason, 'No reason provided') AS disconnect_reason_label
FROM match_participants
ORDER BY participation_id;

-- Just the missing ones, counted by status:
SELECT participation_status,
       COUNT(*) AS rows_missing_reason
FROM match_participants
WHERE disconnect_reason IS NULL
GROUP BY participation_status
ORDER BY participation_status;


-- ------------------------------------------------------------
-- Requirement 5: Make the results easier to understand.
-- Question: For each participation, who played which match, when in
--   the day did they join, how much XP did they earn, and how good
--   was their score, in plain language?
-- What it told me: each row now reads as a sentence a non-SQL reader
--   can follow (e.g. "Player_14, Match_01, Evening, Good score,
--   Completed the match").
-- ------------------------------------------------------------
SELECT mp.participation_id,
       p.player_name,
       m.match_label,
       mp.joined_at,
       CASE
           WHEN EXTRACT(HOUR FROM mp.joined_at) BETWEEN 5 AND 11  THEN 'Morning'
           WHEN EXTRACT(HOUR FROM mp.joined_at) BETWEEN 12 AND 16 THEN 'Afternoon'
           WHEN EXTRACT(HOUR FROM mp.joined_at) BETWEEN 17 AND 21 THEN 'Evening'
           ELSE 'Night'
       END                                    AS time_of_day,
       mp.score,
       mp.xp_multiplier,
       ROUND(mp.score * mp.xp_multiplier, 2)  AS xp_earned,
       CASE
           WHEN mp.score = 0   THEN 'No score'
           WHEN mp.score < 15  THEN 'Low score'
           WHEN mp.score < 30  THEN 'Good score'
           ELSE 'High score'
       END                                    AS score_category,
       CASE mp.participation_status
           WHEN 'finished'  THEN 'Completed the match'
           WHEN 'abandoned' THEN 'Left early'
           WHEN 'contested' THEN 'Result under review'
           ELSE 'Unknown status'
       END                                    AS outcome
FROM match_participants mp
JOIN players p ON p.player_id = mp.player_id
JOIN matches m ON m.match_id  = mp.match_id
ORDER BY mp.participation_id;


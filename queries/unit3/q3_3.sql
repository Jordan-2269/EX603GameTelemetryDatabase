-- ============================================================
-- Task 3.3: Hand the team a corrected query
-- Dataset: ex603_gaming
--
-- Two-step question:
--   Which players were involved in disputed events?
--   Step 1: find the participations whose status is 'contested'.
--   Step 2: return the players who took part in them.
--
-- Expected answer (all three versions): 7 players
--   Player_01, 03, 05, 09, 16, 24, 25
-- ============================================================


-- ------------------------------------------------------------
-- Version 1: Subquery with IN
-- Question: Which players have at least one contested participation?
-- Result: 7 rows.
-- ------------------------------------------------------------
SELECT player_id,
       player_name,
       region
FROM players
WHERE player_id IN (
    SELECT player_id
    FROM match_participants
    WHERE participation_status = 'contested'
)
ORDER BY player_id;


-- ------------------------------------------------------------
-- Version 2: Common Table Expression (WITH) + JOIN
-- Question: Which players have at least one contested participation?
-- Result: 7 rows.
--   DISTINCT is required here: players 5 and 16 have more than one
--   contested participation, and without it the JOIN returns them
--   more than once (10 rows instead of 7).
-- ------------------------------------------------------------
WITH contested_players AS (
    SELECT DISTINCT player_id
    FROM match_participants
    WHERE participation_status = 'contested'
)
SELECT p.player_id,
       p.player_name,
       p.region
FROM players p
JOIN contested_players c ON c.player_id = p.player_id
ORDER BY p.player_id;


-- ------------------------------------------------------------
-- Version 3: Correlated subquery with EXISTS
-- Question: Which players have at least one contested participation?
-- Result: 7 rows.
--   For each player, EXISTS checks whether any matching contested
--   row exists. It stops at the first match, so it never duplicates.
-- ------------------------------------------------------------
SELECT p.player_id,
       p.player_name,
       p.region
FROM players p
WHERE EXISTS (
    SELECT 1
    FROM match_participants mp
    WHERE mp.player_id = p.player_id
      AND mp.participation_status = 'contested'
)
ORDER BY p.player_id;


-- ------------------------------------------------------------
-- Proof the rows match (not just the counts).
-- Question: Is there any row in one version that is missing from
--   another?
-- Method: EXCEPT ALL in both directions. EXCEPT ALL also compares
--   duplicate counts, so a version that returned a player twice
--   would show up here.
-- Result: every column is 0, so all three return identical rows.
-- ------------------------------------------------------------
WITH v1 AS (
    SELECT player_id, player_name, region
    FROM players
    WHERE player_id IN (SELECT player_id FROM match_participants
                        WHERE participation_status = 'contested')
),
v2 AS (
    SELECT p.player_id, p.player_name, p.region
    FROM players p
    JOIN (SELECT DISTINCT player_id FROM match_participants
          WHERE participation_status = 'contested') c
      ON c.player_id = p.player_id
),
v3 AS (
    SELECT p.player_id, p.player_name, p.region
    FROM players p
    WHERE EXISTS (SELECT 1 FROM match_participants mp
                  WHERE mp.player_id = p.player_id
                    AND mp.participation_status = 'contested')
)
SELECT
    (SELECT COUNT(*) FROM (SELECT * FROM v1 EXCEPT ALL SELECT * FROM v2) x) AS in_v1_not_v2,
    (SELECT COUNT(*) FROM (SELECT * FROM v2 EXCEPT ALL SELECT * FROM v1) x) AS in_v2_not_v1,
    (SELECT COUNT(*) FROM (SELECT * FROM v1 EXCEPT ALL SELECT * FROM v3) x) AS in_v1_not_v3,
    (SELECT COUNT(*) FROM (SELECT * FROM v3 EXCEPT ALL SELECT * FROM v1) x) AS in_v3_not_v1,
    (SELECT COUNT(*) FROM v1) AS v1_rows,
    (SELECT COUNT(*) FROM v2) AS v2_rows,
    (SELECT COUNT(*) FROM v3) AS v3_rows;


-- ============================================================
-- When the three would NOT be equivalent
-- ============================================================

-- ------------------------------------------------------------
-- Break 1: Duplicates.
-- If the CTE version drops DISTINCT, the JOIN repeats a player once
-- per contested participation, while IN and EXISTS still return
-- each player once.
-- Result: 10 rows instead of 7 (player 5 appears 3 times, 16 twice).
-- ------------------------------------------------------------
WITH contested_rows AS (
    SELECT player_id                    -- no DISTINCT
    FROM match_participants
    WHERE participation_status = 'contested'
)
SELECT p.player_id, p.player_name
FROM players p
JOIN contested_rows c ON c.player_id = p.player_id
ORDER BY p.player_id;


-- ------------------------------------------------------------
-- Break 2: NULLs with the negated form (NOT IN vs NOT EXISTS).
-- Question: Which players have never recruited anyone?
-- players.recruited_by is nullable. NOT IN compares player_id against
-- every value in the list; when the list contains a NULL, each
-- comparison is UNKNOWN, so NOT IN returns no rows at all.
-- Result: NOT IN returns 0 rows; NOT EXISTS returns the correct 17.
-- ------------------------------------------------------------
SELECT COUNT(*) AS never_recruited_not_in        -- 0 (wrong)
FROM players
WHERE player_id NOT IN (SELECT recruited_by FROM players);

SELECT COUNT(*) AS never_recruited_not_exists    -- 17 (correct)
FROM players p
WHERE NOT EXISTS (
    SELECT 1 FROM players r WHERE r.recruited_by = p.player_id
);

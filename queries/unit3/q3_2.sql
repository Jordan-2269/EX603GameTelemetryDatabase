-- ============================================================
-- Task 3.2: Find the bug
-- Dataset: ex603_gaming
-- ============================================================


-- ============================================================
-- PART A: The rows that vanished (NULL and three-valued logic)
-- Nullable column used: match_participants.disconnect_reason
--   (declared NULL "by design" in the schema). The dataset already
--   contains NULLs here (166 of 200 rows), so no rows were inserted.
-- ============================================================

-- ------------------------------------------------------------
-- Part A, step 1: Confirm the table total and how many NULLs exist.
-- Question: How many participations are there, and how many have no
--   disconnect reason?
-- Result: 200 total; 166 have a NULL disconnect_reason.
-- ------------------------------------------------------------
SELECT COUNT(*)                                              AS total_rows,
       COUNT(*) FILTER (WHERE disconnect_reason IS NULL)     AS null_reason_rows
FROM match_participants;


-- ------------------------------------------------------------
-- Part A, step 2: The buggy query (inequality on a nullable column).
-- Question: How many participations did NOT end with the player
--   quitting?
-- Result: 27 rows. That is clearly wrong: most participations
--   finished normally, so the answer should be far larger.
-- ------------------------------------------------------------
SELECT COUNT(*) AS not_player_quit
FROM match_participants
WHERE disconnect_reason <> 'Player quit';


-- ------------------------------------------------------------
-- Part A, step 3: Count what the first query silently left out.
-- Question: Do "not Player quit" + "Player quit" add up to the total?
-- Result: 27 + 7 = 34, not 200. The missing 166 rows are exactly the
--   NULL rows: NULL <> 'Player quit' evaluates to UNKNOWN, and WHERE
--   only keeps rows that are TRUE, so they were dropped with no error.
-- ------------------------------------------------------------
SELECT
    (SELECT COUNT(*) FROM match_participants
      WHERE disconnect_reason <> 'Player quit')        AS not_player_quit,   -- 27
    (SELECT COUNT(*) FROM match_participants
      WHERE disconnect_reason = 'Player quit')         AS player_quit,       -- 7
    (SELECT COUNT(*) FROM match_participants
      WHERE disconnect_reason IS NULL)                 AS silently_omitted,  -- 166
    (SELECT COUNT(*) FROM match_participants)          AS table_total;       -- 200


-- ------------------------------------------------------------
-- Part A, step 4: Repair the query.
-- Question (same as step 2): How many participations did NOT end with
--   the player quitting?
-- Result: 193 rows (27 + 166). 193 + 7 = 200, so every row is
--   now accounted for.
-- ------------------------------------------------------------

-- Fix 1: explicit IS NULL
SELECT COUNT(*) AS not_player_quit
FROM match_participants
WHERE disconnect_reason <> 'Player quit'
   OR disconnect_reason IS NULL;

-- Fix 2: COALESCE turns NULL into a real value before comparing
SELECT COUNT(*) AS not_player_quit
FROM match_participants
WHERE COALESCE(disconnect_reason, 'No reason provided') <> 'Player quit';


-- ============================================================
-- PART B: The alias that did not exist yet
-- SQL is written SELECT ... FROM ... WHERE, but evaluated
-- FROM -> WHERE -> SELECT -> ORDER BY. The alias is created in
-- SELECT, so WHERE cannot see it yet.
-- ============================================================

-- ------------------------------------------------------------
-- Part B, step 1: The buggy query (alias referenced in WHERE).
-- Question: Which participations earned more than 50 XP?
-- Error (verbatim):
--   [42703] ERROR: column "xp_earned" does not exist
--   (paste the exact message DataGrip shows, including Position)
-- ------------------------------------------------------------
SELECT participation_id,
       score,
       xp_multiplier,
       ROUND(score * xp_multiplier, 2) AS xp_earned
FROM match_participants
WHERE xp_earned > 50;


-- ------------------------------------------------------------
-- Part B, step 2a: Rewrite 1, repeat the expression in WHERE.
-- Question: Which participations earned more than 50 XP?
-- Result: 20 rows.
-- ------------------------------------------------------------
SELECT participation_id,
       score,
       xp_multiplier,
       ROUND(score * xp_multiplier, 2) AS xp_earned
FROM match_participants
WHERE ROUND(score * xp_multiplier, 2) > 50
ORDER BY xp_earned DESC;   -- ORDER BY runs after SELECT, so the alias works here


-- ------------------------------------------------------------
-- Part B, step 2b: Rewrite 2, wrap it in a CTE so the alias becomes
--   a real column that the outer WHERE can see.
-- Question: Which participations earned more than 50 XP?
-- Result: 20 rows (same as 2a).
-- ------------------------------------------------------------
WITH participation_xp AS (
    SELECT participation_id,
           score,
           xp_multiplier,
           ROUND(score * xp_multiplier, 2) AS xp_earned
    FROM match_participants
)
SELECT *
FROM participation_xp
WHERE xp_earned > 50
ORDER BY xp_earned DESC;


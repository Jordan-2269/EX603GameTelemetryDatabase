-- ============================================================
-- Task 5.3: Join performance and execution plans
-- ============================================================


-- ------------------------------------------------------------
-- Part A1: Row counts of the two source tables.
-- Question: How many matches and how many game modes are there?
-- Result: matches = 15, game_modes = 5.
-- ------------------------------------------------------------
SELECT (SELECT COUNT(*) FROM matches)    AS match_rows,
       (SELECT COUNT(*) FROM game_modes) AS game_mode_rows;


-- ------------------------------------------------------------
-- Part A2: CROSS JOIN (Cartesian product).
-- Question: What does every possible match x game mode pairing look like?
-- Result: 75 rows (15 matches x 5 modes).
-- ------------------------------------------------------------
SELECT m.match_label,
       gm.mode_name
FROM matches m
CROSS JOIN game_modes gm
ORDER BY m.match_label, gm.mode_name;


-- ------------------------------------------------------------
-- Part A3: Show the CROSS JOIN count equals the product of the two counts.
-- Question: Does the Cartesian product have exactly matches x modes rows?
-- Result: match_rows = 15, game_mode_rows = 5, expected = 75,
--   cross_join_rows = 75, counts_match = true.
-- ------------------------------------------------------------
SELECT (SELECT COUNT(*) FROM matches)                                   AS match_rows,
       (SELECT COUNT(*) FROM game_modes)                                AS game_mode_rows,
       (SELECT COUNT(*) FROM matches) * (SELECT COUNT(*) FROM game_modes) AS expected_rows,
       (SELECT COUNT(*) FROM matches CROSS JOIN game_modes)             AS cross_join_rows,
       (SELECT COUNT(*) FROM matches) * (SELECT COUNT(*) FROM game_modes)
         = (SELECT COUNT(*) FROM matches CROSS JOIN game_modes)         AS counts_match;


-- ------------------------------------------------------------
-- Part A4: A useful Cartesian product: the mode coverage grid.
-- Question: For every match and every game mode, is that mode enabled?
-- Result: 75 rows: 25 'Enabled' (the match_modes rows) and 50 'Not enabled'.
--   Match_13, Match_14 and Match_15 show 'Not enabled' for all 5 modes.
-- ------------------------------------------------------------
SELECT m.match_label,
       gm.mode_name,
       CASE WHEN mm.match_id IS NULL THEN 'Not enabled' ELSE 'Enabled' END AS mode_status
FROM matches m
CROSS JOIN game_modes gm
LEFT JOIN match_modes mm ON mm.match_id = m.match_id
                        AND mm.mode_id  = gm.mode_id
ORDER BY m.match_label, gm.mode_name;


-- ------------------------------------------------------------
-- Part B: Execution plan for the Task 5.1 three-table join.
-- Question: How does PostgreSQL plan to join players, match_participants
--   and matches, and how long does it actually take?
-- EXPLAIN ANALYZE runs the query; safe here because it is a read-only SELECT.
-- ------------------------------------------------------------
EXPLAIN ANALYZE
SELECT p.player_name,
       p.gamertag,
       m.match_label,
       m.server_region,
       mp.joined_at,
       mp.participation_status
FROM match_participants mp
JOIN players p ON p.player_id = mp.player_id
JOIN matches m ON m.match_id  = mp.match_id
ORDER BY m.match_label, mp.joined_at;

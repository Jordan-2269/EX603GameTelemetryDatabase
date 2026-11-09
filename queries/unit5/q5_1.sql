-- ============================================================
-- Task 5.1: Connect producers to their data
-- ============================================================


-- ------------------------------------------------------------
-- Requirement 1: Join three tables (actor, event, producer).
-- Question: Who played in each match, which match was it, and when
--   did they join?
-- Result: 200 rows, one per participation.
-- ------------------------------------------------------------
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


-- ------------------------------------------------------------
-- Requirement 2a: Producer to catalog through the junction table.
-- Question: Which matches are tagged with the Survival game mode, and
--   how often are their participations abandoned?
-- Result: 5 rows: Match_02, Match_03, Match_05, Match_10, Match_11.
--   Two of the Assignment 4 outliers (Match_02, Match_11) are Survival
--   matches, but so is Match_10, which has 0 abandons. Survival alone
--   does not explain high failure rates.
-- ------------------------------------------------------------
WITH match_stats AS (
    SELECT match_id,
           COUNT(*) AS total_events,
           ROUND(100.0 * SUM(CASE WHEN participation_status = 'abandoned' THEN 1 ELSE 0 END)
                 / COUNT(*), 1) AS abandon_rate_pct
    FROM match_participants
    GROUP BY match_id
)
SELECT m.match_label,
       m.server_region,
       gm.mode_name,
       mm.enabled_on,
       ms.total_events,
       ms.abandon_rate_pct
FROM matches m
JOIN match_modes mm      ON mm.match_id = m.match_id
JOIN game_modes  gm      ON gm.mode_id  = mm.mode_id
LEFT JOIN match_stats ms ON ms.match_id = m.match_id
WHERE gm.mode_name = 'Survival'
ORDER BY ms.abandon_rate_pct DESC;


-- ------------------------------------------------------------
-- Requirement 2b: All tags for the Assignment 4 outliers.
-- Question: Which game modes are the three high-abandon matches
--   (Match_02, Match_09, Match_11) tagged with?
-- Result: 6 rows. Match_02 has 3 tags, Match_09 has 1, Match_11 has 2.
--   No single tag is shared by all three.
-- ------------------------------------------------------------
SELECT m.match_label,
       gm.mode_name,
       gm.mode_description
FROM matches m
JOIN match_modes mm ON mm.match_id = m.match_id
JOIN game_modes  gm ON gm.mode_id  = mm.mode_id
WHERE m.match_label IN ('Match_02', 'Match_09', 'Match_11')
ORDER BY m.match_label, gm.mode_name;


-- ------------------------------------------------------------
-- Requirement 3: Self join on the producer table.
-- Question: How does each Assignment 4 outlier compare with the other
--   matches hosted on the same server region?
-- Result: 5 rows (Match_02 vs 06 and 11, Match_09 vs 04, Match_11 vs 02
--   and 06). Every APAC and EU peer is also above the 15% high-volume
--   baseline, and activity levels are similar (14-21 events). The
--   shared trait is the server region, not volume.
-- ------------------------------------------------------------
WITH match_stats AS (
    SELECT match_id,
           COUNT(*) AS total_events,
           ROUND(100.0 * SUM(CASE WHEN participation_status = 'abandoned' THEN 1 ELSE 0 END)
                 / COUNT(*), 1) AS abandon_rate_pct
    FROM match_participants
    GROUP BY match_id
)
SELECT m1.match_label        AS outlier_match,
       m1.server_region,
       m1.is_ranked          AS outlier_ranked,
       s1.total_events       AS outlier_events,
       s1.abandon_rate_pct   AS outlier_abandon_pct,
       m2.match_label        AS peer_match,
       m2.is_ranked          AS peer_ranked,
       s2.total_events       AS peer_events,
       s2.abandon_rate_pct   AS peer_abandon_pct
FROM matches m1
JOIN matches m2          ON m2.server_region = m1.server_region   -- self join: same region
                        AND m2.match_id     <> m1.match_id        -- but not the same match
LEFT JOIN match_stats s1 ON s1.match_id = m1.match_id
LEFT JOIN match_stats s2 ON s2.match_id = m2.match_id
WHERE m1.match_label IN ('Match_02', 'Match_09', 'Match_11')
ORDER BY m1.match_label, m2.match_label;

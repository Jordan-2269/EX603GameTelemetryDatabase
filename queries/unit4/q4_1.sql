-- ============================================================
-- Task 4.1, Question 1: Platform-wide summary of the score metric
-- Plain language: Across every match participation, how many events are there,
-- what are the total/average/min/max scores, and how many different players appear?
-- ============================================================
SELECT
    COUNT(*)                   AS event_count,
    SUM(score)                 AS total_score,
    ROUND(AVG(score), 2)       AS avg_score,
    MIN(score)                 AS min_score,
    MAX(score)                 AS max_score,
    COUNT(DISTINCT player_id)  AS distinct_players
FROM match_participants;

-- Follow-up (data quality): the minimum score is 0. Which statuses produce zero scores?
SELECT
    participation_status,
    COUNT(*)                                AS events,
    COUNT(*) FILTER (WHERE score = 0)       AS zero_score_events,
    ROUND(AVG(score), 2)                    AS avg_score
FROM match_participants
GROUP BY participation_status
ORDER BY events DESC;


-- ============================================================
-- Task 4.1, Question 2: Event count and average score per match (producer)
-- Plain language: Which matches have the most participation, and how do their
-- average scores compare? Sorted from most events to fewest.
-- LEFT JOIN keeps matches that have zero events, so they aren't silently dropped.
-- ============================================================
SELECT
    m.match_id,
    m.match_label,
    COUNT(mp.participation_id)  AS event_count,
    ROUND(AVG(mp.score), 2)     AS avg_score
FROM matches m
LEFT JOIN match_participants mp ON mp.match_id = m.match_id
GROUP BY m.match_id, m.match_label
ORDER BY event_count DESC, m.match_id;


-- ============================================================
-- Task 4.1, Question 3: Abandon rate, only for matches with enough volume to trust
-- Plain language: Among matches with at least 10 participations, what share of
-- participations were abandoned?
-- Threshold = 10: active matches average about 15 events. Below 10, a single
-- abandon moves the rate by more than 10 percentage points (e.g. Match_04 has
-- 6 events, so 2 abandons = 33%), which is noise, not performance.
-- ============================================================
SELECT
    m.match_id,
    m.match_label,
    COUNT(*)                                                     AS event_count,
    COUNT(*) FILTER (WHERE mp.participation_status = 'abandoned') AS abandoned_events,
    ROUND(100.0 * COUNT(*) FILTER (WHERE mp.participation_status = 'abandoned')
          / COUNT(*), 1)                                         AS abandon_rate_pct,
    ROUND(AVG(mp.score), 2)                                      AS avg_score
FROM matches m
JOIN match_participants mp ON mp.match_id = m.match_id
GROUP BY m.match_id, m.match_label
HAVING COUNT(*) >= 10
ORDER BY abandon_rate_pct DESC, event_count DESC;


-- ============================================================
-- Task 4.1, Question 4: Performance by server region and ranked/unranked
-- Plain language: For each server region, how do ranked and unranked matches
-- compare on volume, score, and abandon rate? One row per region x ranked combination.
-- ============================================================
SELECT
    m.server_region,
    CASE WHEN m.is_ranked THEN 'Ranked' ELSE 'Unranked' END     AS match_type,
    COUNT(*)                                                     AS event_count,
    COUNT(DISTINCT mp.player_id)                                 AS distinct_players,
    ROUND(AVG(mp.score), 2)                                      AS avg_score,
    MIN(mp.score)                                                AS min_score,
    MAX(mp.score)                                                AS max_score,
    ROUND(100.0 * COUNT(*) FILTER (WHERE mp.participation_status = 'abandoned')
          / COUNT(*), 1)                                         AS abandon_rate_pct
FROM matches m
JOIN match_participants mp ON mp.match_id = m.match_id
GROUP BY m.server_region, m.is_ranked
ORDER BY m.server_region, match_type;


-- ------------------------------------------------------------
-- Task 4.2, Part A: Conditional aggregation (two numbers in one pass)
-- Question: For each match, how many participations were there in total,
--   and how many of them were abandoned?
-- Result: 15 rows (one per match). Both counts come from one pass over
--   match_participants. CASE inside SUM separates the abandoned rows, so the
--   query needs no WHERE clause.
--   Outliers: Match_11 (5 of 16, 31.3%), Match_09 (4 of 14, 28.6%) and
--   Match_04 (2 of 6, 33.3%, but low volume) have the highest abandon rates.
--   Match_10 has 0 abandons in 19 events. Match_14 and Match_15 have no events.
-- ------------------------------------------------------------
SELECT m.match_id,
       m.match_label,
       COUNT(mp.participation_id)                                          AS total_events,
       SUM(CASE WHEN mp.participation_status = 'abandoned' THEN 1 ELSE 0 END) AS abandoned_events,
       ROUND(100.0 * SUM(CASE WHEN mp.participation_status = 'abandoned' THEN 1 ELSE 0 END)
             / NULLIF(COUNT(mp.participation_id), 0), 1)                   AS abandon_rate_pct
FROM matches m
LEFT JOIN match_participants mp ON mp.match_id = m.match_id
GROUP BY m.match_id, m.match_label
ORDER BY abandon_rate_pct DESC NULLS LAST, total_events DESC;


-- ------------------------------------------------------------
-- Task 4.2, Part B: Regional subtotals and a platform grand total
-- Question: For each server region, how many participations and abandons
--   were there, and what are the totals for the whole platform?
-- Result: 6 rows: 5 regional subtotal rows (row_type = 'Region subtotal')
--   and 1 grand total row (row_type = 'GRAND TOTAL', server_region = 'ALL REGIONS').
--   No per-match detail rows appear.
--   Grand total: 200 events, 34 abandoned, 17.0%. EU (30.0%) and APAC (24.5%)
--   are above the platform rate. NA has 0 abandons.
-- ------------------------------------------------------------
SELECT CASE WHEN GROUPING(m.server_region) = 1 THEN 'GRAND TOTAL'
            ELSE 'Region subtotal' END                                      AS row_type,
       CASE WHEN GROUPING(m.server_region) = 1 THEN 'ALL REGIONS'
            ELSE m.server_region END                                        AS server_region,
       COUNT(*)                                                             AS total_events,
       SUM(CASE WHEN mp.participation_status = 'abandoned' THEN 1 ELSE 0 END) AS abandoned_events,
       ROUND(100.0 * SUM(CASE WHEN mp.participation_status = 'abandoned' THEN 1 ELSE 0 END)
             / COUNT(*), 1)                                                 AS abandon_rate_pct,
       ROUND(AVG(mp.score), 2)                                              AS avg_score
FROM matches m
JOIN match_participants mp ON mp.match_id = m.match_id
GROUP BY GROUPING SETS ((m.server_region), ())
ORDER BY GROUPING(m.server_region), m.server_region;


-- ------------------------------------------------------------
-- Task 4.2, Part C: Two-step pipeline (baseline for high-volume matches)
-- Question: Among matches with at least 15 participations, what is the
--   typical abandon rate and average score? This is the baseline to judge
--   high-volume matches against.
-- Step 1 (CTE): summarize each match: events, abandons, rate, avg score.
-- Step 2: keep only high-volume matches (>= 15 events, about the platform
--   average of 15.4 per active match) and aggregate them into one baseline row.
-- Result: 1 row. 8 high-volume matches, 145 events, 22 abandoned.
--   Pooled abandon rate 15.2%; average of the per-match rates 15.7%.
-- ------------------------------------------------------------
WITH match_summary AS (
    SELECT m.match_id,
           m.match_label,
           COUNT(*)                                                             AS total_events,
           SUM(CASE WHEN mp.participation_status = 'abandoned' THEN 1 ELSE 0 END) AS abandoned_events,
           100.0 * SUM(CASE WHEN mp.participation_status = 'abandoned' THEN 1 ELSE 0 END)
                 / COUNT(*)                                                     AS abandon_rate_pct,
           AVG(mp.score)                                                        AS avg_score
    FROM matches m
    JOIN match_participants mp ON mp.match_id = m.match_id
    GROUP BY m.match_id, m.match_label
)
SELECT COUNT(*)                                                     AS high_volume_matches,
       SUM(total_events)                                            AS total_events,
       SUM(abandoned_events)                                        AS abandoned_events,
       ROUND(100.0 * SUM(abandoned_events) / SUM(total_events), 1)  AS pooled_abandon_rate_pct,
       ROUND(AVG(abandon_rate_pct), 1)                              AS avg_of_match_rates_pct,
       ROUND(AVG(avg_score), 2)                                     AS avg_match_score
FROM match_summary
WHERE total_events >= 15;

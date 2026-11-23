-- ============================================================
-- Task 6.3: Build the reporting patterns
-- ============================================================


-- ------------------------------------------------------------
-- Task 6.3, Part A: Top N per category (top 3 scores per match).
-- Question: What are the three highest-scoring participations in each
--   match, and how far is each one behind that match's best score?
-- Ties at third place: RANK() is used, so if two participations tie for
--   third, both are kept and that match shows four rows. Two players with
--   the same score earned the same place, and cutting one of them by an
--   arbitrary tie-breaker (as ROW_NUMBER would) would be unfair on a
--   leaderboard. In this data no match has a tie at third place.
-- FIRST_VALUE uses the default frame, which is correct here: the first
--   row of the partition is always inside the frame. (LAST_VALUE would
--   need ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING.)
-- Result: 39 rows: 13 matches with events x 3 participations each.
-- ------------------------------------------------------------
WITH ranked AS (
    SELECT m.match_label,
           p.player_name,
           mp.joined_at,
           mp.score,
           RANK()        OVER (PARTITION BY mp.match_id ORDER BY mp.score DESC) AS score_rank,
           FIRST_VALUE(mp.score)
                         OVER (PARTITION BY mp.match_id ORDER BY mp.score DESC) AS match_best_score
    FROM match_participants mp
    JOIN matches m ON m.match_id  = mp.match_id
    JOIN players p ON p.player_id = mp.player_id
)
SELECT match_label,
       score_rank,
       player_name,
       score,
       match_best_score,
       ROUND(score - match_best_score, 2) AS behind_best
FROM ranked
WHERE score_rank <= 3
ORDER BY match_label, score_rank, player_name;


-- ------------------------------------------------------------
-- Task 6.3, Part B: Period over period (month over month).
-- Question: Is the platform getting better or worse each month, in
--   participation and in abandon rate?
-- NULLIF prevents division by zero in the percent change. The
--   month_check column confirms each month directly follows the previous
--   one; LAG counts rows, so a missing month would make it compare the
--   wrong months.
-- Result: 12 rows (January to December 2023), all 'consecutive'.
--   Abandon rate by month: 23.8, 19.0, 27.3, 0.0, 11.8, 25.0, 11.8, 16.7,
--   18.8, 11.1, 14.3, 18.8 (%). Largest swing: March 27.3% -> April 0.0%.
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT DATE_TRUNC('month', joined_at)::DATE                              AS month,
           COUNT(*)                                                          AS events,
           SUM(CASE WHEN participation_status = 'abandoned' THEN 1 ELSE 0 END) AS abandoned,
           ROUND(100.0 * SUM(CASE WHEN participation_status = 'abandoned' THEN 1 ELSE 0 END)
                 / COUNT(*), 1)                                              AS abandon_rate_pct
    FROM match_participants
    GROUP BY DATE_TRUNC('month', joined_at)::DATE
),
with_prev AS (
    SELECT month,
           events,
           abandoned,
           abandon_rate_pct,
           LAG(month)            OVER (ORDER BY month) AS prev_month,
           LAG(events)           OVER (ORDER BY month) AS prev_events,
           LAG(abandon_rate_pct) OVER (ORDER BY month) AS prev_abandon_rate_pct
    FROM monthly
)
SELECT month,
       events,
       prev_events,
       ROUND(100.0 * (events - prev_events) / NULLIF(prev_events, 0), 1) AS events_pct_change,
       abandon_rate_pct,
       prev_abandon_rate_pct,
       abandon_rate_pct - prev_abandon_rate_pct                          AS abandon_rate_change_pts,
       CASE
           WHEN prev_month IS NULL                          THEN 'first month'
           WHEN prev_month + INTERVAL '1 month' = month     THEN 'consecutive'
           ELSE 'GAP: missing month(s) before this one'
       END                                                               AS month_check
FROM with_prev
ORDER BY month;


-- ------------------------------------------------------------
-- Task 6.3, Part B (check): List any calendar month with no events at all.
-- Question: Are there any months between the first and last event with
--   zero participations?
-- Result: 0 rows. Every month from January to December 2023 has data, so
--   the LAG comparisons above compare true neighbouring months.
-- ------------------------------------------------------------
SELECT gs::DATE AS missing_month
FROM generate_series(
         (SELECT DATE_TRUNC('month', MIN(joined_at)) FROM match_participants),
         (SELECT DATE_TRUNC('month', MAX(joined_at)) FROM match_participants),
         INTERVAL '1 month') AS gs
WHERE NOT EXISTS (
    SELECT 1
    FROM match_participants mp
    WHERE DATE_TRUNC('month', mp.joined_at) = gs
);


-- ------------------------------------------------------------
-- Task 6.3 / 6.4 support: Quarter over quarter abandon rate.
-- Question: Is the failure problem getting better or worse across the
--   year's four quarters?
-- Result: 4 rows. Q1 22.6% (12 of 53), Q2 14.6% (7 of 48),
--   Q3 15.7% (8 of 51), Q4 14.6% (7 of 48).
-- ------------------------------------------------------------
WITH quarterly AS (
    SELECT DATE_TRUNC('quarter', joined_at)::DATE                            AS quarter_start,
           COUNT(*)                                                          AS events,
           SUM(CASE WHEN participation_status = 'abandoned' THEN 1 ELSE 0 END) AS abandoned
    FROM match_participants
    GROUP BY DATE_TRUNC('quarter', joined_at)::DATE
)
SELECT quarter_start,
       events,
       abandoned,
       ROUND(100.0 * abandoned / events, 1)                                   AS abandon_rate_pct,
       ROUND(100.0 * abandoned / events, 1)
         - LAG(ROUND(100.0 * abandoned / events, 1)) OVER (ORDER BY quarter_start) AS change_pts
FROM quarterly
ORDER BY quarter_start;

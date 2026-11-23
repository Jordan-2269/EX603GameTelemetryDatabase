-- ============================================================
-- Task 6.2: Compare each row to its neighbors
-- ============================================================


-- ------------------------------------------------------------
-- Task 6.2, Part A: Row to row (LAG / LEAD / delta) for one producer.
-- Question: For Match_11, is each participation's score going up or down
--   compared with the one before it?
-- The window runs over every match (PARTITION BY match_id), and the outer
--   query then keeps only Match_11 so the trend is easy to read.
-- Result: 16 rows. The first row has no previous score and the last has
--   no next score. Largest drop: 22.35 -> 0.00 (delta -22.35) on
--   2023-03-04, the first of four abandons in a row between March and
--   June. Scores mostly recover from July onward (one more abandon on
--   2023-10-01).
-- ------------------------------------------------------------
WITH ordered AS (
    SELECT m.match_label,
           mp.participation_id,
           mp.joined_at,
           mp.participation_status,
           mp.score,
           LAG(mp.score)  OVER w              AS prev_score,
           LEAD(mp.score) OVER w              AS next_score,
           mp.score - LAG(mp.score) OVER w    AS delta_from_prev
    FROM match_participants mp
    JOIN matches m ON m.match_id = mp.match_id
    WINDOW w AS (PARTITION BY mp.match_id ORDER BY mp.joined_at, mp.participation_id)
)
SELECT match_label,
       joined_at,
       participation_status,
       prev_score,
       score,
       next_score,
       delta_from_prev
FROM ordered
WHERE match_label = 'Match_11'
ORDER BY joined_at;


-- ------------------------------------------------------------
-- Task 6.2, Part B: Cumulative and smoothed (running total + moving average).
-- Question: How is the platform doing over time, in total and on a recent
--   average, and how close does each quarter get to its target?
-- Target: 50 participations per quarter.
-- Moving window: 14 rows (active days). Events land on only 155 of the
--   year's days, so 14 rows cover roughly a month of calendar time and
--   about 18 participations, enough to smooth out single bad days.
-- Result: 155 rows, one per day with activity. Quarter totals against
--   the 50 target: Q1 53 (106%), Q2 48 (96%), Q3 51 (102%), Q4 48 (96%).
-- ------------------------------------------------------------
WITH daily AS (
    SELECT CAST(joined_at AS DATE)                                          AS play_date,
           COUNT(*)                                                         AS events,
           SUM(CASE WHEN participation_status = 'abandoned' THEN 1 ELSE 0 END) AS abandoned
    FROM match_participants
    GROUP BY CAST(joined_at AS DATE)
)
SELECT play_date,
       events,
       abandoned,
       -- running total for the whole year
       SUM(events) OVER (ORDER BY play_date
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS running_events_ytd,
       -- running total that restarts each quarter, compared to the target
       SUM(events) OVER (PARTITION BY DATE_TRUNC('quarter', play_date)
                         ORDER BY play_date
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS running_events_qtd,
       50                                                                   AS quarter_target,
       ROUND(100.0 * SUM(events) OVER (PARTITION BY DATE_TRUNC('quarter', play_date)
                                       ORDER BY play_date
                                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
             / 50, 1)                                                       AS pct_of_quarter_target,
       -- 14-row moving averages
       ROUND(AVG(events) OVER (ORDER BY play_date
                               ROWS BETWEEN 13 PRECEDING AND CURRENT ROW), 2) AS moving_avg_events_14rows,
       ROUND(100.0 * SUM(abandoned) OVER (ORDER BY play_date
                                          ROWS BETWEEN 13 PRECEDING AND CURRENT ROW)
             / SUM(events) OVER (ORDER BY play_date
                                 ROWS BETWEEN 13 PRECEDING AND CURRENT ROW), 1) AS moving_abandon_rate_pct_14rows
FROM daily
ORDER BY play_date;

-- ROWS vs RANGE: with ROWS, rows that share the same ORDER BY value are
--   added to the frame one at a time, so a running total climbs row by
--   row in an arbitrary order among the ties. With RANGE, tied rows are
--   "peers" and all enter the frame together, so every tied row shows the
--   same, already-complete total. (Grouping by day above means each date
--   appears once, so here both give the same result.)


-- ------------------------------------------------------------
-- Task 6.2, Part C: Where the series stops (gap detection).
-- Question: Which matches went quiet for a long time and then started
--   again, and how long was each gap?
-- Threshold: more than 60 days. The typical (median) gap between a
--   match's participations is about 17 days, so 60+ days is well over
--   three times normal.
-- The window function runs in the CTE; the WHERE in the outer query keeps
--   only the gaps (a window result cannot be filtered with WHERE or HAVING
--   in the same query, because the window is computed after them).
-- Result: 11 rows. The longest is Match_09: no participation from
--   2023-01-05 to 2023-04-28 (112.6 days). Next: Match_12 (106.7 days),
--   Match_05 (93.0), Match_11 (89.5).
-- ------------------------------------------------------------
WITH with_prev AS (
    SELECT m.match_label,
           mp.joined_at,
           LAG(mp.joined_at) OVER (PARTITION BY mp.match_id
                                   ORDER BY mp.joined_at) AS prev_joined_at
    FROM match_participants mp
    JOIN matches m ON m.match_id = mp.match_id
)
SELECT match_label,
       prev_joined_at                                                   AS last_event_before_gap,
       joined_at                                                        AS first_event_after_gap,
       ROUND(EXTRACT(EPOCH FROM (joined_at - prev_joined_at)) / 86400, 1) AS gap_days
FROM with_prev
WHERE joined_at - prev_joined_at > INTERVAL '60 days'
ORDER BY gap_days DESC;

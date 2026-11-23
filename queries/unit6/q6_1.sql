-- ============================================================
-- Task 6.1: Compute across a window without collapsing
-- ============================================================


-- ------------------------------------------------------------
-- Task 6.1, Question 1a: Each event next to its producer's average (window).
-- Question: Is each participation's score unusual for the match it was
--   played in?
-- Result: 200 rows, one per participation. Every row keeps its own score
--   and also shows its match's average and how far it sits from it.
--   Abandoned participations (score 0) stand out as the largest
--   negative differences.
-- ------------------------------------------------------------
SELECT mp.participation_id,
       m.match_label,
       mp.joined_at,
       mp.participation_status,
       mp.score,
       ROUND(AVG(mp.score) OVER (PARTITION BY mp.match_id), 2)              AS match_avg_score,
       ROUND(mp.score - AVG(mp.score) OVER (PARTITION BY mp.match_id), 2)   AS diff_from_match_avg
FROM match_participants mp
JOIN matches m ON m.match_id = mp.match_id
ORDER BY m.match_label, mp.joined_at;


-- ------------------------------------------------------------
-- Task 6.1, Question 1b: The same average with GROUP BY, for comparison.
-- Question: What is the average score for each match?
-- Result: 13 rows, one per match that has events. The 200 individual
--   participations are gone: you can no longer see which events were
--   unusual, who played them, or when. (Match_14 and Match_15 have no
--   events, so they do not appear.)
-- ------------------------------------------------------------
SELECT m.match_label,
       COUNT(*)                 AS events,
       ROUND(AVG(mp.score), 2)  AS match_avg_score
FROM match_participants mp
JOIN matches m ON m.match_id = mp.match_id
GROUP BY m.match_label
ORDER BY m.match_label;


-- ------------------------------------------------------------
-- Task 6.1, Question 2: Rank producers three ways.
-- Question: For a match leaderboard by number of participations, how do
--   ROW_NUMBER, RANK and DENSE_RANK treat matches with the same count?
-- Result: 15 rows. Ties in the output:
--   Match_05 and Match_07 (18 events): ROW_NUMBER 4 and 5, RANK 4 and 4,
--     DENSE_RANK 4 and 4. The next match (Match_12) gets RANK 6 but
--     DENSE_RANK 5.
--   Match_02 and Match_11 (16 events), Match_01 and Match_13 (11 events),
--     and Match_14 and Match_15 (0 events) are also tied.
--   ROW_NUMBER breaks ties by match_id, so the lower ID always "wins".
-- ------------------------------------------------------------
WITH match_counts AS (
    SELECT m.match_id,
           m.match_label,
           COUNT(mp.participation_id) AS event_count
    FROM matches m
    LEFT JOIN match_participants mp ON mp.match_id = m.match_id
    GROUP BY m.match_id, m.match_label
)
SELECT match_label,
       event_count,
       ROW_NUMBER() OVER (ORDER BY event_count DESC, match_id) AS row_number_rank,
       RANK()       OVER (ORDER BY event_count DESC)           AS rank_with_gaps,
       DENSE_RANK() OVER (ORDER BY event_count DESC)           AS dense_rank_no_gaps
FROM match_counts
ORDER BY event_count DESC, match_id;


-- ------------------------------------------------------------
-- Task 6.1, Question 3: Sort producers into four bands with NTILE(4).
-- Question: Which matches fall into the top, upper-middle, lower-middle
--   and bottom quarter by number of participations?
-- Result: 15 rows in bands of 4, 4, 4 and 3.
--   Band 1: Match_06 (21), Match_08 (20), Match_10 (19), Match_05 (18)
--   Band 2: Match_07 (18), Match_12 (17), Match_02 (16), Match_11 (16)
--   Band 3: Match_09 (14), Match_03 (13), Match_01 (11), Match_13 (11)
--   Band 4: Match_04 (6), Match_14 (0), Match_15 (0)
--   Boundary problem: Match_05 and Match_07 both have 18 events, but
--   NTILE puts Match_05 in band 1 and Match_07 in band 2. NTILE fills
--   bands by row count, not by value, so a tie can be split purely by
--   the tie-breaker (here, match_id).
-- ------------------------------------------------------------
WITH match_counts AS (
    SELECT m.match_id,
           m.match_label,
           COUNT(mp.participation_id) AS event_count
    FROM matches m
    LEFT JOIN match_participants mp ON mp.match_id = m.match_id
    GROUP BY m.match_id, m.match_label
)
SELECT match_label,
       event_count,
       NTILE(4) OVER (ORDER BY event_count DESC, match_id) AS activity_band
FROM match_counts
ORDER BY activity_band, event_count DESC, match_id;

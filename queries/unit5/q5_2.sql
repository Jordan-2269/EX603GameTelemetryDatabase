-- ============================================================
-- Task 5.2: Find records that joins may exclude
-- ============================================================


-- ------------------------------------------------------------
-- Part A1: LEFT JOIN (keeps every producer).
-- Question: How many participations has every match had, including
--   matches that have never had one?
-- Result: 15 rows. Match_14 and Match_15 appear with 0 events.
-- ------------------------------------------------------------
SELECT m.match_id,
       m.match_label,
       COUNT(mp.participation_id) AS event_count
FROM matches m
LEFT JOIN match_participants mp ON mp.match_id = m.match_id
GROUP BY m.match_id, m.match_label
ORDER BY event_count, m.match_id;


-- ------------------------------------------------------------
-- Part A2: The same query with INNER JOIN.
-- Question: Same as A1, but only matches that have at least one event.
-- Result: 13 rows. Match_14 and Match_15 are missing.
-- ------------------------------------------------------------
SELECT m.match_id,
       m.match_label,
       COUNT(mp.participation_id) AS event_count
FROM matches m
JOIN match_participants mp ON mp.match_id = m.match_id
GROUP BY m.match_id, m.match_label
ORDER BY event_count, m.match_id;


-- ------------------------------------------------------------
-- Part A3: Count of producers excluded by the inner join.
-- Question: How many matches does the inner join drop?
-- COUNT(DISTINCT match_id) counts each match once, no matter how many
--   events it has.
-- Result: left_join_producers = 15, inner_join_producers = 13,
--   excluded_by_inner_join = 2.
-- ------------------------------------------------------------
SELECT l.left_join_producers,
       i.inner_join_producers,
       l.left_join_producers - i.inner_join_producers AS excluded_by_inner_join
FROM (SELECT COUNT(DISTINCT m.match_id) AS left_join_producers
      FROM matches m
      LEFT JOIN match_participants mp ON mp.match_id = m.match_id) l
CROSS JOIN
     (SELECT COUNT(DISTINCT m.match_id) AS inner_join_producers
      FROM matches m
      JOIN match_participants mp ON mp.match_id = m.match_id) i;


-- ------------------------------------------------------------
-- Part B1: RIGHT JOIN that returns the same records as the A1 LEFT JOIN.
-- Question: Same as A1, written with the tables swapped and RIGHT JOIN.
-- Result: 15 rows, identical to A1.
-- ------------------------------------------------------------
SELECT m.match_id,
       m.match_label,
       COUNT(mp.participation_id) AS event_count
FROM match_participants mp
RIGHT JOIN matches m ON mp.match_id = m.match_id
GROUP BY m.match_id, m.match_label
ORDER BY event_count, m.match_id;


-- ------------------------------------------------------------
-- Part B2: Verify the LEFT and RIGHT JOIN results really match.
-- Question: Is any row in one result missing from the other?
-- Method: EXCEPT ALL in both directions (also compares duplicate counts).
-- Result: 0 rows, so the two queries return exactly the same records.
-- ------------------------------------------------------------
(
    SELECT m.match_id, COUNT(mp.participation_id) AS event_count
    FROM matches m
    LEFT JOIN match_participants mp ON mp.match_id = m.match_id
    GROUP BY m.match_id
    EXCEPT ALL
    SELECT m.match_id, COUNT(mp.participation_id)
    FROM match_participants mp
    RIGHT JOIN matches m ON mp.match_id = m.match_id
    GROUP BY m.match_id
)
UNION ALL
(
    SELECT m.match_id, COUNT(mp.participation_id)
    FROM match_participants mp
    RIGHT JOIN matches m ON mp.match_id = m.match_id
    GROUP BY m.match_id
    EXCEPT ALL
    SELECT m.match_id, COUNT(mp.participation_id)
    FROM matches m
    LEFT JOIN match_participants mp ON mp.match_id = m.match_id
    GROUP BY m.match_id
);


-- ------------------------------------------------------------
-- Part B3: FULL OUTER JOIN (unmatched records from both sides).
-- Question: Which matches have no events, and which events have no match?
-- Result: 202 rows: 200 matched, 2 matches without events
--   (Match_14, Match_15), 0 events without a match.
-- ------------------------------------------------------------
SELECT m.match_id,
       m.match_label,
       mp.participation_id,
       mp.match_id AS event_match_id,
       CASE
           WHEN mp.participation_id IS NULL THEN 'Match with no events'
           WHEN m.match_id IS NULL          THEN 'Event with no match'
           ELSE 'Matched'
       END AS join_status
FROM matches m
FULL OUTER JOIN match_participants mp ON mp.match_id = m.match_id
ORDER BY join_status DESC, m.match_id, mp.participation_id;

-- Summary of B3: one row per join status.
-- Result: Matched = 200, Match with no events = 2. No "Event with no match" row.
SELECT CASE
           WHEN mp.participation_id IS NULL THEN 'Match with no events'
           WHEN m.match_id IS NULL          THEN 'Event with no match'
           ELSE 'Matched'
       END      AS join_status,
       COUNT(*) AS row_count
FROM matches m
FULL OUTER JOIN match_participants mp ON mp.match_id = m.match_id
GROUP BY 1
ORDER BY row_count DESC;


-- ------------------------------------------------------------
-- Part C1: Producers with no events, using NOT EXISTS.
-- Question: Which matches have never had a single participation?
-- Result: 2 rows: Match_14 (NA), Match_15 (SA).
-- ------------------------------------------------------------
SELECT m.match_id,
       m.match_label,
       m.server_region,
       m.scheduled_on,
       m.player_count,
       m.is_ranked
FROM matches m
WHERE NOT EXISTS (
    SELECT 1
    FROM match_participants mp
    WHERE mp.match_id = m.match_id
)
ORDER BY m.match_id;


-- ------------------------------------------------------------
-- Part C2: Producers with no events, using EXCEPT.
-- Question: Same as C1: which match IDs never appear in the event table?
-- Result: 2 rows: match_id 14 and 15, the same producers as C1.
-- ------------------------------------------------------------
SELECT match_id FROM matches
EXCEPT
SELECT match_id FROM match_participants
ORDER BY match_id;

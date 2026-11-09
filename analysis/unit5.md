5_1 Write up
1. What feature could use the three-table join?
A match history page for players and support staff: each row shows the player's name and gamertag, the match they played, its server region, when they joined, and whether they finished or abandoned. Support could use it to look up "which players were affected by the Match_11 crashes", and Live Ops could filter it by region to see who keeps hitting failures.

2. Why is the junction table important for Question 2?
A match can have several game modes and each mode belongs to many matches. Match_02 alone has three. match_modes stores each pairing as its own row, so finding "all Survival matches" is a simple join and filter. Without it, the modes would have to be stored as a list inside one column on matches, such as 'CTF, Survival, Ranked Duel'. Then you'd need text matching to find a mode (which is slow and error-prone: a typo or different spelling breaks it), you couldn't enforce that the mode actually exists, and you'd have nowhere to store per-pairing facts like enabled_on.

5_2 Write up
1. Which producers were excluded by the inner join?
Two: Match_14 (match_id 14) and Match_15 (match_id 15).

2. What does it mean when a producer has no events? Possible explanations.
What the data shows: both matches exist in the schedule, are ranked, have platforms assigned, and are among the smaller matches (capacity 8 and 6). Neither has a single participation, and neither has any game mode assigned. Every match that has events, except Match_13, has at least one mode.
What would need further investigation: the data can't say why. Possible explanations include a match that was scheduled but cancelled, a match that never went live because it wasn't fully configured (the missing game modes point this way), a lobby nobody joined, or a telemetry pipeline that failed to record its events. Telling these apart needs server logs or the Live Ops team's records.

3. How could an inner-join-only report mislead leadership?
It shows only matches that worked well enough to record activity, so failures to launch become invisible. For example, an inner-join report shows NA with 0% abandons and looks like the best region. But half of NA's matches (Match_14) never ran at all. The platform looks like it has 13 matches when it actually scheduled 15, which overstates how well scheduling turns into play.

4. Why identify producers that were never active?
They are scheduled capacity (servers, slots, and possibly money) that delivered nothing. They may also be a symptom of a setup or pipeline problem that could affect future matches too. A failure rate only measures matches that started. Matches that never started are a separate, completely hidden failure.

5. What action could leadership take?
Ask Live Ops to check the history of Match_14 and Match_15: were they cancelled, misconfigured, or not recorded? If missing game-mode configuration is the cause, add a check that blocks a match from being scheduled without at least one mode. Make "scheduled vs. actually played" a standing metric on the dashboard, built with a LEFT JOIN, so matches that never run are counted instead of quietly dropped.

5_3 Write up
1. When a Cartesian product is useful on your platform.
The mode coverage grid (Part A4): crossing every match with every game mode lists every combination that could exist, and a LEFT JOIN to match_modes marks which ones actually do. It shows that Match_13, Match_14, and Match_15 have no modes at all, which links to the inactive-match finding from Task 5.2. A Cartesian product usually means an error when it's accidental: a missing or wrong ON condition between match_participants and players would pair every one of the 200 events with all 30 players, giving 6,000 rows of wrong results. That's easy to miss, because the query still runs without errors.

2. Which join algorithms did PostgreSQL choose?
Name the nodes in your plan, for example: "Two Hash Joins, one joining match_participants to players and one joining the result to matches, with a Sort on top."

3. What information in the plan explains those choices?
Point to these parts of your plan:

Seq Scan on every table. The tables are tiny (200, 30, and 15 rows), so reading them whole is cheaper than using an index.
rows= estimates. The planner knows the tables are small, so building an in-memory hash table on the smaller side (players, matches) and probing it with the 200 events is cheap.
Indexes. players and matches have primary-key indexes, but the foreign-key columns match_participants.player_id and match_id have no index. PostgreSQL doesn't create those automatically. That rules out an efficient index-based Nested Loop driven from the event side.
actual time and Execution Time from ANALYZE. Expect well under a millisecond, which supports the "small tables, cheap plan" explanation.
4. Why understand the chosen join algorithms?
They explain why a query is fast or slow, so you can fix the right thing. A query that's slow because of a Seq Scan on a huge table needs an index; one that's slow because a hash table spills to disk needs more memory or a filter. Without reading the plan you'd be guessing. It also catches mistakes: an unexpected Nested Loop with a huge row count is often the first sign of a missing join condition.

5. What changes would make another algorithm more appropriate?

Growth: match_participants is the fact table and will grow fastest. At millions of rows, the Seq Scan on it and the final Sort are the parts that get slower. The Sort could spill to disk ("external merge" in the plan).
Filtering + indexes: if the report filters to one match or one player (for example a player's match history page), adding indexes on match_participants(match_id) and (player_id) would let PostgreSQL use a Nested Loop with Index Scans, touching only the matching rows.
Pre-sorted data: if both sides were already sorted on the join key, for example via indexes, PostgreSQL might choose a Merge Join, which also avoids part of the final sort.

5_4 Reflection
In my execution plan, PostgreSQL joined the three tables using hash joins over sequential scans. That makes sense today: the tables hold only 200, 30 and 15 rows, so reading each one in full and building a small in-memory hash table is cheaper than using an index. Several changes could make a different algorithm better.

The biggest is growth in match_participants. At millions of rows, hash joins still suit a full report, but the sequential scan and the final sort become the slow steps. If the hash table or sort no longer fits in memory, PostgreSQL has to spill to disk, which is far slower.

The number of matching records matters as much as size. Most real reports filter, for example to one player's match history. If match_participants had indexes on player_id and match_id, which PostgreSQL does not create automatically for foreign keys, the planner could switch to a nested loop with index scans and read only the few matching rows instead of the whole table.

If both inputs were already sorted on the join key, for example through indexes, a merge join could become the cheapest option and would also remove the separate sort.

Finally, the planner relies on table statistics. After a large data load, outdated statistics could make it misjudge row counts and choose the wrong algorithm, so running ANALYZE keeps its choices accurate.

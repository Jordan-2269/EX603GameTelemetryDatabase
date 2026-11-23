# Unit 6: Window Functions and Analytics

Queries: [`q6_1.sql`](../queries/unit6/q6_1.sql) · [`q6_2.sql`](../queries/unit6/q6_2.sql) · [`q6_3.sql`](../queries/unit6/q6_3.sql)

## Task 6.1: Compute across a window without collapsing

**1. A question that needs each row next to its group's average**

*"Which individual participations scored far below what is normal for their own match?"*

The window version (`AVG(score) OVER (PARTITION BY match_id)`) returns all 200
participations, each with its own score, its match's average, and the difference.
The GROUP BY version returns only 13 rows, one average per match. It can tell us
that Match_11's average is low, but not *which* participations pulled it down,
who played them, or when. Answering the question needs both the individual row
and the group's average on the same line, and GROUP BY can only give one or the
other. In our data the window version immediately shows that the biggest
negative differences are the abandoned participations, recorded with a score of 0.

**2. A platform feature that would use the ranking, and which function**

Feature: a **"most active matches" leaderboard** on the Live Ops dashboard, ranking
matches by number of participations.

It should use **`RANK()`**. Match_05 and Match_07 both have 18 participations, so
they deserve the same place. `ROW_NUMBER()` would put Match_05 above Match_07
only because it has the lower ID, which is arbitrary, and it would look like a
real difference. `RANK()` gives both 4th place, and the next match is shown as
6th, so a reader can still see that five matches are ahead of it. `DENSE_RANK()`
would call that match 5th, which understates how many are ahead. Tie handling
decides who counts as equal: here, two matches with identical activity should
never be presented as better or worse than each other.

The NTILE(4) query shows the same problem in a different form: Match_05 lands in
band 1 and Match_07 in band 2 despite the identical count, because NTILE splits
by row count, not by value.

## Task 6.2: Compare each row to its neighbors

**1. What a large delta tells someone, and what to do**

In Match_11 the largest delta is **-22.35**, when a score of 22.35 is followed by
an abandoned participation scored 0 (2023-03-04). On this platform a large
negative delta is usually not a player having a bad game: it marks a
participation that ended early. Four abandons in a row followed in Match_11
between March and June. A Live Ops engineer seeing a large drop, especially
several in a row, should check that match's server logs for crashes or restarts
around those timestamps before treating it as a player-skill issue.

**2. Why a running total answers what a plain SUM cannot**

A plain SUM gives one number at the end, for example Q4 = 48 participations
against a target of 50. A running total shows *the path*: on which day each
quarter passed the target, and whether a quarter was on pace or fell behind
mid-way. Q1 and Q3 passed 50 (106% and 102%); Q2 and Q4 finished at 96%. Only
the running total lets someone notice mid-quarter that they are behind and act
before it is over.

**3. Why the moving-average window is 14 rows**

Events happen on only 155 of the year's days, about 1.3 per active day. A 7-row
window would average only around 9 participations, so one bad day would swing
the abandon rate sharply. A 14-row window covers about 18 participations and
roughly a month of calendar time, which smooths single bad days but still
reacts within weeks. A much larger window (for example 60 rows) would hide real
changes. Because the window counts rows, not days, 14 rows can span more than
14 calendar days whenever days have no events.

**4. What the gap means on this platform**

The longest gap is **Match_09: no participation for 112.6 days** (2023-01-05 to
2023-04-28). Ten other gaps exceed 60 days, against a typical gap of about 17
days.

This is most likely **a real stop in activity for that match, not a data quality
problem.** The platform as a whole recorded events in every month and on 155
different days, including throughout January to April, so the recording
pipeline was working while Match_09 was silent. What the data cannot tell us is
*why* the match stopped: whether it was taken offline, removed from the
matchmaking rotation, or simply not chosen by players. That needs Live Ops'
scheduling records. The response would be to confirm with Live Ops whether
Match_09 was intentionally paused.

## Task 6.3: Build the reporting patterns

**1. The feature top-N would power, and why three**

A **"Top 3 scores" podium on each match's page**, showing the three best players
and how far behind the leader each one is (using `FIRST_VALUE`).

Three is the right number for this platform. Matches have about 15
participations each, so a top 10 would list most of the players and stop
meaning "best". A top 1 hides how close the competition was. Three keeps the
recognition exclusive while still showing a race. With `RANK()`, a tie at third
shows both players, so nobody is cut by an arbitrary tie-breaker.

**2. What a large month-over-month change means, and what to do**

The largest swing is March (27.3% abandoned) to April (0.0%). Both months had
only 11 participations, so a few events move the rate a lot: April's 0% is
probably partly luck, not proof that a fix worked. A large month-over-month
change should trigger a check, not a celebration or an alarm: compare it with
the 14-row moving abandon rate from Task 6.2. If the moving rate confirms a
sustained rise, the infrastructure on-call should review that month's crash and
timeout logs by region. If it is a one-month spike on a small month, note it and
watch the next month.

## Reflection

Window functions keep every row while adding a value calculated from related
rows. A question that is easy with a window function but awkward with GROUP BY
alone is: *"For each match, did each participation score higher or lower than
the one before it, and where do abandons happen several times in a row?"*

With `LAG(score) OVER (PARTITION BY match_id ORDER BY joined_at)` this is one
query: every participation keeps its own row and gains the previous score next
to it, so the delta and the runs of consecutive zeros in Match_11 are visible
directly.

GROUP BY cannot answer it, because it collapses each match into a single row.
It can report Match_11's average score or its number of abandons, but not the
order they happened in. The question depends on the relationship between
neighbouring rows, and that relationship is exactly what grouping throws away.
Without window functions I would have to join the table to itself, matching
each participation to the latest earlier participation in the same match,
which needs a correlated subquery to find "the previous one". That is longer,
harder to read, slower on a large table, and easy to get wrong when two
participations share a timestamp. The window function states the intent
directly: same match, in time order, look one row back.

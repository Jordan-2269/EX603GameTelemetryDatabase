<img width="860" height="564" alt="game-telemetry-erd" src="https://github.com/user-attachments/assets/0b48ea01-be24-4dd2-b3c5-3a8d1d114adf" />

# EX603 Game Telemetry Database

**A PostgreSQL database and SQL analysis of a multiplayer game's match telemetry: who played, how they scored, and why matches fail.**

**Author:** Derek Campbell · EX603 Data and Algorithms for Scalable Systems

## Contents

1. [The domain](#the-domain)
2. [Database overview](#database-overview)
3. [Query catalogue](#query-catalogue)
4. [Technical highlights](#technical-highlights)
5. [Findings and recommendations](#findings-and-recommendations)
6. [Limitations and future improvements](#limitations-and-future-improvements)
7. [Video presentation](#video-presentation)
8. [How to run it](#how-to-run-it)

## The domain

This project models the backend data layer of a multiplayer game's telemetry pipeline: the system that records what happened in every match, who played in it, and how they performed. Rather than storing raw gameplay logs, it captures the structured facts a game studio needs for analytics: which players took part in which matches, which game modes each match was tagged with, and the outcome of every participation, including the score, how long it lasted, and whether the player finished or abandoned it.

The central business question for this platform is **reliability**. A dashboard reported a failure rate that nobody trusted, so the analysis set out to measure the real rate, find which matches and regions are behind it, uncover matches that ordinary reports hide, and answer the question leadership cares about most: *is the platform getting better, and what should the team do next quarter?*

Along the way the platform must answer questions such as: How many participations end in abandonment, and why? Which matches and server regions fail most? Which scheduled matches never ran at all? How is activity and reliability trending month to month and quarter to quarter?

## Database overview

The ERD is shown at the top of this page. The analysis runs on the **Unit 3 reference dataset**, [`data/gaming.sql`](data/gaming.sql), which creates the tables and loads one year (2023) of sample telemetry. The tables used in the analysis:

| Table | Role | What it stores |
|---|---|---|
| `match_participants` | **Event (fact) table**, 200 rows | One row per player per match: `joined_at`, `left_at`, `score`, `duration_min`, `participation_status` (finished / abandoned / contested) and `disconnect_reason`. |
| `matches` | **Producer**, 15 rows | One row per match: label, `server_region`, `scheduled_on`, `player_count` capacity, `is_ranked`. |
| `players` | **Actor**, 30 rows | One row per player: name, gamertag, home `region`, `recruited_by` (self-reference), `is_active`. |
| `game_modes` | **Catalog**, 5 rows | Capture the Flag, Deathmatch, Survival, Ranked Duel, Time Trial. |
| `match_modes` | **Junction**, 25 rows | Which game modes are enabled on which matches (many-to-many). |
| `match_platforms` | Multivalued attribute | Which platforms (PC, PlayStation, Xbox, Switch, mobile) each match runs on. |

The theme metric is **`score`**, and a "failure" is a participation with `participation_status = 'abandoned'`.

My original schema design from Assignment 2 is kept in [`schema/`](schema/): [ERD](schema/erd.png), [SQL definition](schema/schema.sql) and [constraint rationale](schema/constraints.md).

<details>
<summary>Design decisions from the original Assignment 2 schema</summary>

**`match_participants` is the center of the design.** Almost every analytics question (top scorers, player activity, match turnout) comes back to who played in which match and how they did, so that information lives in one high-volume table instead of being spread across players and matches. It uses its own surrogate key so each participation record can be referenced directly.

**Matches and game modes are many-to-many.** A match can carry more than one mode tag, and a mode is shared by many matches, so the relationship is stored in `match_modes` rather than as a single column on `matches`. Its composite primary key prevents the same mode from being attached to the same match twice.

**Delete rules protect history but clean up dependents.** Deleting a match cascades to its participant and mode rows, because those rows describe only that match. Deleting a player or a game mode is restricted while any match references them, so historical results are never silently erased.

**Scores cannot be negative.** A `CHECK (score >= 0)` constraint blocks bad values from the game client or ingestion pipeline before they reach analysis.

**Ranked status is a flag, not a mode.** `is_ranked` is a boolean on `matches`, since every match is either ranked or not. Game modes are kept separate because they are an open-ended list that can grow over time.

**The timestamp is stored per participant.** It sits on `match_participants` rather than `matches`, so each player's participation is recorded with its own time, which supports activity analysis per player.

</details>

## Query catalogue

SQL files live in [`queries/`](queries/), one folder per unit. Every query is headed by a comment naming the task it answers and the question it asks in plain language.

### Unit 3: Filtering, debugging and subqueries

| File | Task | Business question |
|---|---|---|
| [`q3_1.sql`](queries/unit3/q3_1.sql) | 3.1 Establish what the data contains | Which ranked matches drew the most players? What participation statuses exist? Which participations scored 20 to 40 points, or ended for server-side reasons? Why did each player disconnect, including missing reasons? |
| [`q3_2.sql`](queries/unit3/q3_2.sql) | 3.2 Find the bug | How many participations did *not* end with the player quitting, and why does a naive filter get this wrong when the reason is NULL? |
| [`q3_3.sql`](queries/unit3/q3_3.sql) | 3.3 Hand the team a corrected query | Which players have at least one contested participation (written with IN, a CTE + JOIN, and EXISTS), and do all three versions return exactly the same rows? |

### Unit 4: Aggregation and summaries

| File | Task | Business question |
|---|---|---|
| [`q4_1.sql`](queries/unit4/q4_1.sql) | 4.1 Platform summary | What are the count, total, average, minimum and maximum scores, and how many distinct players appear? Which statuses produce zero scores? |
| [`q4_1.sql`](queries/unit4/q4_1.sql) | 4.1 Per-match breakdown | Which matches have the most participation, and how do their average scores compare? |
| [`q4_1.sql`](queries/unit4/q4_1.sql) | 4.1 Volume threshold (HAVING) | Among matches with at least 10 participations, which have the highest abandon rates? |
| [`q4_1.sql`](queries/unit4/q4_1.sql) | 4.1 Two dimensions | How do volume, score and abandon rate vary by server region and ranked vs. unranked play? |
| [`q4_2.sql`](queries/unit4/q4_2.sql) | 4.2A Conditional aggregation | For each match, how many participations were there in total and how many were abandoned, in a single pass? |
| [`q4_2.sql`](queries/unit4/q4_2.sql) | 4.2B Subtotals and grand total | What are the participation and abandon totals per server region and for the whole platform? |
| [`q4_2.sql`](queries/unit4/q4_2.sql) | 4.2C Two-step pipeline (CTE) | What abandon rate should we expect from a high-volume match, as a baseline for judging matches? |

### Unit 5: Joins and query patterns

| File | Task | Business question |
|---|---|---|
| [`q5_1.sql`](queries/unit5/q5_1.sql) | 5.1 Three-table join | Who played in each match, which match was it, and when did they join? |
| [`q5_1.sql`](queries/unit5/q5_1.sql) | 5.1 Junction table | Which matches carry the Survival game mode, and which modes are the high-failure matches tagged with? |
| [`q5_1.sql`](queries/unit5/q5_1.sql) | 5.1 Self join | How does each high-failure match compare with the other matches on the same server region? |
| [`q5_2.sql`](queries/unit5/q5_2.sql) | 5.2A/B Outer joins | How many matches does an inner join silently drop, and do LEFT, RIGHT and FULL OUTER joins confirm which ones? |
| [`q5_2.sql`](queries/unit5/q5_2.sql) | 5.2C NOT EXISTS and EXCEPT | Which scheduled matches have never had a single participation? |
| [`q5_3.sql`](queries/unit5/q5_3.sql) | 5.3A CROSS JOIN | What does every match x game mode combination look like, and which are actually enabled? |
| [`q5_3.sql`](queries/unit5/q5_3.sql) | 5.3B EXPLAIN ANALYZE | How does PostgreSQL execute the three-table join, and which part will slow down as data grows? |

### Unit 6: Window functions and analytics

| File | Task | Business question |
|---|---|---|
| [`q6_1.sql`](queries/unit6/q6_1.sql) | 6.1 Partitioned average | Is each participation's score unusual for its own match? (Window vs. GROUP BY.) |
| [`q6_1.sql`](queries/unit6/q6_1.sql) | 6.1 Ranking and NTILE | How should a "most active matches" leaderboard rank ties, and how do matches split into four activity bands? |
| [`q6_2.sql`](queries/unit6/q6_2.sql) | 6.2A LAG / LEAD | Within one match, is each score going up or down compared with the previous one? |
| [`q6_2.sql`](queries/unit6/q6_2.sql) | 6.2B Running total and moving average | How is the platform doing over time, and how close does each quarter get to its participation target? |
| [`q6_2.sql`](queries/unit6/q6_2.sql) | 6.2C Gap detection | Which matches went quiet for a long time, and for how long? |
| [`q6_3.sql`](queries/unit6/q6_3.sql) | 6.3A Top N per category | What are the top three scores in each match? |
| [`q6_3.sql`](queries/unit6/q6_3.sql) | 6.3B Period over period | Is the platform getting better or worse month over month and quarter over quarter? |

### Analysis write-ups

| Unit | Write-up | Finding / memo |
|---|---|---|
| 1–2 | [`unit1.md`](analysis/unit1.md), [`unit2.md`](analysis/unit2.md) | |
| 3 | | [`unit3-finding.md`](analysis/unit3-finding.md) |
| 4 | [`unit4.md`](analysis/unit4.md) | [`unit4-finding.md`](analysis/unit4-finding.md) |
| 5 | [`unit5.md`](analysis/unit5.md) | [`unit5-finding.md`](analysis/unit5-finding.md) |
| 6 | [`unit6.md`](analysis/unit6.md) | [`unit6-finding.md`](analysis/unit6-finding.md) (closing memo) |

Result screenshots are collected in [`screenshots.md`](screenshots.md).

## Technical highlights

**1. Conditional aggregation: several answers in one pass** ([`q4_2.sql`](queries/unit4/q4_2.sql), Part A)
`SUM(CASE WHEN participation_status = 'abandoned' THEN 1 ELSE 0 END)` next to `COUNT(*)` gives total and failed participations per match in a single scan of the event table, with no WHERE clause. Two separate filtered queries would read the table twice and need a join to line the results up.

**2. GROUPING SETS: subtotals and a grand total together** ([`q4_2.sql`](queries/unit4/q4_2.sql), Part B)
`GROUP BY GROUPING SETS ((server_region), ())` returns one row per region plus a platform-wide total, labelled with `GROUPING()`. The regional director gets the comparison and the benchmark in one result, without 200 detail rows.

**3. Outer joins, NOT EXISTS and EXCEPT: finding what reports hide** ([`q5_2.sql`](queries/unit5/q5_2.sql))
An inner join silently drops matches with no activity. A LEFT JOIN, confirmed by both `NOT EXISTS` and `EXCEPT`, showed two scheduled matches that never ran. Equivalence between the LEFT and RIGHT JOIN versions was proven with `EXCEPT ALL` in both directions rather than assumed.

**4. Window functions: comparing rows without collapsing them** ([`q6_2.sql`](queries/unit6/q6_2.sql), [`q6_3.sql`](queries/unit6/q6_3.sql))
`LAG()` puts each month or quarter next to the one before it to measure the trend. Running totals (`ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`) track progress against a quarterly target, and a 14-row moving average smooths out noisy days. A `generate_series` check confirms no months are missing, because LAG compares rows, not dates.

**5. Reading the execution plan** ([`q5_3.sql`](queries/unit5/q5_3.sql), Part B)
`EXPLAIN ANALYZE` on the three-table join showed how PostgreSQL chose its join algorithms for small tables and identified the event-table scan and the final sort as the parts that will slow down as data grows. Indexes on `match_participants(match_id)` and `(player_id)` are the first fix for filtered reports.

## Findings and recommendations

**1. The failure problem improved, then stalled.**
The abandon rate fell from **22.6% in Q1 to 14.6% in Q2**, then stayed flat at about 15% for the rest of 2023 (15.7% in Q3, 14.6% in Q4). Activity was steady at 48 to 53 participations per quarter, so the improvement is not explained by fewer people playing. ([`q6_3.sql`](queries/unit6/q6_3.sql), [`unit6-finding.md`](analysis/unit6-finding.md))

**2. The remaining failures are regional and technical.**
**EU (30%)** and **APAC (25%)** servers abandon far more often than the platform's 17%, while North America had none. 27 of the 34 abandons were network timeouts, server restarts or client crashes, not players quitting. The worst matches are Match_11 (31%), Match_09 (29%) and Match_02 (25%). ([`q4_2.sql`](queries/unit4/q4_2.sql), [`q5_1.sql`](queries/unit5/q5_1.sql), [`unit4-finding.md`](analysis/unit4-finding.md))

**3. Two scheduled matches never ran, and standard reports hide them.**
Match_14 and Match_15 have no participations, and neither has a game mode configured. Because of them, an inner-join report makes North America look like the most reliable region, when half of its matches never happened. ([`q5_2.sql`](queries/unit5/q5_2.sql), [`unit5-finding.md`](analysis/unit5-finding.md))

**Recommendations for next quarter**
- Focus infrastructure work on the **EU and APAC servers**, starting with Match_11, Match_09 and Match_02, and set a target of a **quarterly abandon rate below 12%**.
- Track reliability with the **quarterly and 14-day moving rates**, not single months, which swing too much on small numbers to act on.
- Have Live Ops confirm whether **Match_14 and Match_15** were cancelled, left unconfigured or not recorded, then relaunch or remove them. Require at least one game mode before a match can be scheduled.

## Limitations and future improvements

**Small sample.** The dataset holds 200 participations over one year, so a single month can contain as few as 11. That is why the monthly abandon rate swings from 27% in March to 0% in April. Conclusions are therefore drawn from quarterly figures and a 14-row moving average rather than individual months.

**Causes are not in the data.** The data shows *when* and *where* participations fail and the recorded disconnect reason, but not the underlying technical cause of a crash or timeout, or why a match stopped being played. Server logs, Live Ops scheduling records and more months of data would confirm the causes and show whether the 15% plateau holds.

## Video presentation

▶️ **[Watch the presentation](VIDEO_LINK_HERE)** (3–5 minutes): the business question, three representative queries including a Unit 6 window function, the key findings, and one limitation.

## How to run it

Requires PostgreSQL 14 or later and the `psql` command-line client.

```bash
# 1. Clone the repository
git clone https://github.com/Jordan-2269/EX603GameTelemetryDatabase.git
cd EX603GameTelemetryDatabase

# 2. Create the database and load the schema and data
createdb ex603_gaming
psql -d ex603_gaming -f data/gaming.sql

# 3. Run a query file, for example the Unit 6 trend analysis
psql -d ex603_gaming -f queries/unit6/q6_3.sql
```

Or run a single query directly:

```bash
psql -d ex603_gaming -c "SELECT participation_status, COUNT(*) FROM match_participants GROUP BY participation_status;"
```

Re-running `data/gaming.sql` is safe: it drops and recreates every table first. If your PostgreSQL user needs a host or username, add `-h localhost -U your_user` to the commands above.

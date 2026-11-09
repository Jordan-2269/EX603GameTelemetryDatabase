# Recommendations: Matches That Fail vs. Matches That Never Started

Our analysis found two groups of problem matches. They look similar in a
summary report, but they are different problems and need different responses.

## Group 1: Matches that fail often

**Match_11, Match_09 and Match_02**

| Match | Region | Participations | Abandoned |
|---|---|---|---|
| Match_11 | APAC | 16 | 31% |
| Match_09 | EU | 14 | 29% |
| Match_02 | APAC | 16 | 25% |

A typical busy match loses about **15%** of its participations. These three
lose roughly **twice that**.

**What the data shows:** these matches are popular. Players are showing up,
and the matches are being let down by technical problems. Nearly all of
their abandons come from client crashes, network timeouts and server
restarts, not from players choosing to leave. The problem also follows
the **server region**, not the game mode: every APAC and EU match is above
the 15% benchmark, while matches with the same game modes in other regions
perform well (Match_10 in North America has no abandons at all).

**Recommendation: fix reliability in the APAC and EU server regions.**
1. Ask the infrastructure team to review the APAC and EU servers, starting
   with the hosts for Match_11 and Match_02 (repeated crashes and timeouts).
2. Compare their setup with Match_10's North American setup, which has no
   failures.
3. Set a target: bring every busy match below the 15% benchmark, and
   track it monthly.

**Why this matters:** every abandoned match is a real player whose game
ended early, and every one of them is recorded with a score of zero.

## Group 2: Matches that never started

**Match_14 (North America) and Match_15 (South America)**

**What the data shows:** both matches are on the schedule, with platforms
assigned, but **no player has ever taken part in either one**. They are also
the only matches that are both unplayed and set up without any game mode.

**What the data cannot tell us:** *why* they never ran. They may have been
cancelled, left unfinished during setup, never joined by anyone, or played
without the results being recorded. Answering this needs Live Ops' records,
not more analysis.

**Recommendation: find out what happened, then decide whether these matches
should exist at all.**
1. Ask Live Ops to confirm the status of Match_14 and Match_15.
2. Depending on the answer:
   - **Cancelled:** remove them from the schedule so they stop appearing
     as capacity we don't have.
   - **Not fully set up:** finish the setup and relaunch them, and add a
     rule that a match cannot be scheduled without at least one game mode.
   - **Played but not recorded:** treat it as a data problem and have the
     engineering team check the reporting pipeline.
3. Add "scheduled vs. actually played" to the leadership dashboard so
   matches that never run are counted instead of quietly disappearing.

**Why this matters:** standard reports leave these matches out entirely,
because they have no activity to report. North America, for example, looks
like our most reliable region, but half of its matches never ran.

## The difference, in one line

**Group 1 is a quality problem:** players are there, and we are letting them
down. Fix the servers.
**Group 2 is a delivery problem:** no players were affected, but we don't
know why the matches never happened. Investigate before acting.

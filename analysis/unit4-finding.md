# Match Reliability: What the Data Shows

## The true failure rate

**17% of match participations end in abandonment: 34 of 200.**

Most of these failures are technical, not players choosing to leave:

| Cause | Abandons |
|---|---|
| Network timeout | 12 |
| Server restart | 8 |
| Client crash | 7 |
| Player quit | 7 |

27 of 34 abandons (79%) come from network, server, or client problems that the team can fix.

Every abandoned participation is recorded with a score of 0. This means the
platform's average score understates how well players actually perform: about
one in six scores is a zero caused by a technical failure, not by skill.

## How it varies across matches

The abandon rate ranges from **0%** to over **30%** depending on the match.

- **Best:** Match_10, with 0 abandons out of 19 participations.
- **Worst with real volume:** Match_11 (31%), Match_09 (29%), Match_02 (25%).
- **Typical busy match:** among matches with 15 or more participations, about **15%** of participations are abandoned. That is the benchmark to judge matches against.

By server region, **EU (30%)** and **APAC (25%)** are well above the platform
rate of 17%, while **NA has no abandons**.

Two matches, **Match_14** and **Match_15**, were scheduled but have no
participation recorded at all.

## The three matches to investigate

1. **Match_11 (31% abandoned, 5 of 16).** It has the highest failure rate of any
   match with meaningful volume, about double the benchmark. 4 of its 5 abandons
   are technical: 2 client crashes, a network timeout, and a server restart.
2. **Match_09 (29% abandoned, 4 of 14).** All 4 of its abandons are technical
   (2 client crashes, a timeout, and a restart). None were players quitting.
   This is an unranked EU match, in the region with the highest failure rate.
3. **Match_02 (25% abandoned, 4 of 16).** 3 of its 4 abandons are network
   timeouts. This repeated cause points to a connection problem on its server
   (APAC) rather than random bad luck.

**For comparison:** Match_10 (NA, 0% abandoned) is the model to learn from:
what is its server setup doing differently?

**Not on the list:** Match_04 has the highest raw rate (33%), but that comes from
only 2 abandons out of 6 participations. That is too few to tell a real problem
from chance, so it should be watched rather than investigated.

## What we would need next

- Abandon rates by **platform** (PlayStation, Xbox, PC, mobile, Switch), to see whether client crashes cluster on one device.
- The **average score with abandoned participations excluded**, to get a true measure of player performance.
- An explanation for why Match_14 and Match_15 have **no participation**.

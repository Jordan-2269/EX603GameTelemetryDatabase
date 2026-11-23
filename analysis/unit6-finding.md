# Is the Platform Getting Better? Closing Memo

**To:** Leadership team
**Covers:** All match participations recorded in 2023 (200 participations, 15 scheduled matches)

## Short answer

**The failure problem got better early in the year, then stopped improving.**
The share of participations that end in abandonment fell from **22.6% in the
first quarter to about 15%** and has stayed there for the rest of the year. The
remaining failures are concentrated in two server regions, and most of them are
technical, which means they are fixable.

## 1. Is the failure problem getting better or worse?

| Quarter | Participations | Abandoned | Abandon rate |
|---|---|---|---|
| Q1 (Jan–Mar) | 53 | 12 | **22.6%** |
| Q2 (Apr–Jun) | 48 | 7 | 14.6% |
| Q3 (Jul–Sep) | 51 | 8 | 15.7% |
| Q4 (Oct–Dec) | 48 | 7 | 14.6% |

*Source: quarter-over-quarter query, `queries/unit6/q6_3.sql`.*

- **Better after Q1:** the abandon rate dropped by 8 percentage points between Q1 and Q2.
- **Flat since:** Q2, Q3 and Q4 are all within about one point of 15%. The second half of the year (15.2%) is better than the first half (18.8%), but the improvement has stalled rather than continued.
- **Monthly numbers are noisy.** Individual months range from 0% (April) to 27% (March), but those months had only 11 participations each, so a handful of events moves the rate a lot. The quarterly view and the 14-day moving rate are the reliable signals. *(Monthly and moving-average queries: `q6_3.sql` Part B, `q6_2.sql` Part B.)*
- **Activity is steady:** each quarter delivered between 48 and 53 participations against a target of 50, so the improvement is not explained by fewer people playing. *(Running totals: `q6_2.sql` Part B.)*

## 2. Where the remaining failures come from

- **Region:** abandonment is highest on **EU (30%)** and **APAC (25%)** servers, against a platform rate of 17%. North America had none. *(Regional subtotals: `queries/unit4/q4_2.sql` Part B; same-region comparison: `queries/unit5/q5_1.sql` Requirement 3.)*
- **Cause:** 27 of the 34 abandons were network timeouts, server restarts or client crashes. Only 7 were players choosing to quit. *(Task 4.3 finding.)*
- **Worst matches:** Match_11 (31%), Match_09 (29%) and Match_02 (25%). In Match_11, four participations in a row were abandoned between March and June. *(Row-to-row comparison: `q6_2.sql` Part A.)*
- **Matches that never ran:** Match_14 and Match_15 have never had a participation. *(`queries/unit5/q5_2.sql` Part C.)*

## 3. What the team should do next quarter

1. **Target the 15% plateau with a reliability fix in EU and APAC.** The early-year improvement shows the rate can move. The next gain has to come from the regions where failures concentrate. Have the infrastructure team review the servers behind Match_11, Match_09 and Match_02 first, using the crash and timeout timestamps.
2. **Set a measurable goal:** bring the quarterly abandon rate **below 12%**, tracked monthly with the 14-day moving abandon rate rather than single-month figures, which swing too much to act on.
3. **Resolve Match_14 and Match_15.** Confirm with Live Ops whether they were cancelled, left unconfigured (neither has a game mode) or not recorded, and remove or relaunch them.
4. **Ask about long silences.** Match_09 had no participation for 112 days (January to April) while the rest of the platform kept recording, so this was a real stop for that match, not lost data. Live Ops should confirm whether it was paused on purpose. *(Gap detection: `q6_2.sql` Part C.)*

## What this analysis cannot tell us

The data shows *when* and *where* participations fail, but not the underlying
technical cause of each crash or timeout, or why a match stopped being played.
Server logs and Live Ops' scheduling records are needed to confirm the causes
before investing in a fix.

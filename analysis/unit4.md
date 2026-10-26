#############################################################################################################

4_1 Write up

Who acts on the per-match breakdown: the Live Ops or match-operations manager who schedules matches and chooses which servers or modes to fix or retire.
What the average hides: the 34 zero scores from abandoned participations pull avg_score down. A match with many abandons looks like "low-scoring players" when the real problem is reliability. The average also hides the spread, so you'd want the median and percentiles next (for example PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY score)) and the average excluding abandoned rows.
What the count hides: event_count counts participations, not people. One very active player can make a match look busy, so compare it with COUNT(DISTINCT player_id). An inner join also makes matches 14 and 15 disappear entirely, and the Q2 LEFT JOIN shows them with 0 events.
What you'd want next: score distribution per match, abandon rate broken down by disconnect_reason, and the per-player view.

#############################################################################################################

4_2 Write up

Part A, the two questions side by side: "How much activity did each match have?" (total_events) and "How much of that activity failed?" (abandoned_events). Name the outliers: Match_11 and Match_09 have high abandon rates with real volume, and Match_10 has none.
Part B: the reader is the regional director. The region rows show how each region compares. Only the grand total gives the platform-wide 17.0% abandon rate, which is the benchmark that makes "EU is at 30%" meaningful. It supports a decision like "which regions are worse than the platform and need server investment first".
Part C: the pipeline answers: "What abandon rate and score should we expect from a high-volume match?" Any busy match well above about 15% is underperforming, for example Match_11 at 31.3%.

#############################################################################################################

Reflection

Conditional aggregation lets one query answer several questions at once. In Part A, a single grouped query over match_participants produced both the total events and the abandoned events for every match. The database read each row once and, as it went, added it to the total and, if its status was 'abandoned', to the failure count. The alternative is two queries: one counting all rows per match, and a second with WHERE participation_status = 'abandoned'. That reads the table twice and then needs a join to put the two results side by side. A match with zero abandons would also quietly disappear from the second query unless the join is written carefully.

On 200 rows the difference is invisible. At a million rows it matters for three reasons. First, cost: the expensive part of a query is usually reading the data, so two passes roughly double the I/O and the run time, and every additional metric would add another pass. Second, consistency: if new events arrive between the two queries, the totals and the failure counts describe slightly different data, so the rate calculated from them can be wrong. One pass gives a single consistent snapshot. Third, simplicity: one query is easier to read, review, and keep correct than several queries stitched together with joins.

#############################################################################################################

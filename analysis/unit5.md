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

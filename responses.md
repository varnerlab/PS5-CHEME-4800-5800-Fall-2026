# PS5 written responses

Answer all three questions. Each question has two parts, (a) and (b). Replace
the line `TODO: Write your response.` with your answers, labeled (a) and (b).
One to three sentences per part is enough. Give the numbers you use from the
files in `outputs/`. Keep the blank line after each question; the checker uses
it to find your answer.

1. **What did the screen learn?**
   Use `screen-summary.csv` and `posteriors.png`. They show one screen of 480
   experiments, run as 20 blocks of 24 wells on all 20 conditions. A condition's
   true success fraction is the fraction of the 37 alcohols it fluorinates in at
   least 50% yield.
   - **(a)** The group picks the condition with the highest probability of being
     best. Report the pick, its probability of being best, its number of
     experiments, and its true success fraction. Is it the best condition?
   - **(b)** The two best conditions differ by one alcohol in 37. From their true
     success fractions, how many extra failed runs per 100 alcohols would the
     group expect if it chose the second-best? Use their experiment counts and
     their probabilities of being best to explain why 480 experiments cannot
     reliably tell these two conditions apart.

   TODO: Write your response.

2. **What do reaction blocks cost?**
   Use `plate-sizes.csv` and `gap-loss.png`. Each Thompson sampling row
   averages 100 screens of 480 experiments; the equal-split row is computed from
   the true success fractions. The gap loss of a screen is the number of extra
   failed runs you expect from running the conditions it chose instead of the
   best condition every time.
   - **(a)** Report the days and the mean gap loss for blocks of 1, 24, 96, and
     480 wells, and the gap loss of the equal split, which runs every condition
     on 24 alcohols.
   - **(b)** Each well draws its own samples from the posteriors as they stand at
     the start of its block. Use this to explain why one 480-well block loses as
     much as the equal split, and why 24-well blocks lose about as much as
     running one reaction at a time.

   TODO: Write your response.

3. **PBSF is banned.**
   When PBSF converts an alcohol to its fluoride, it releases
   perfluorobutanesulfonate, the anion of PFBS (perfluorobutane sulfonic acid). In
   January 2020, the European Union added PFBS and its salts to its REACH
   Candidate List of substances of very high concern. Suppose the company bans
   PBSF after the first screen, which leaves the 16 conditions that use one of the
   other four sulfonyl fluorides. Use `pbsf-ban.csv` and `conditions.csv`.
   - **(a)** From the first screen, report the number of the 480 experiments that
     used a PBSF-free condition; the most experiments any one PBSF-free condition
     got; and the PBSF-free condition with the highest probability of being best
     among the 16, with that probability. Explain, from how Thompson sampling
     chooses conditions, why the first screen says little about which PBSF-free
     condition is best.
   - **(b)** From the new 16-condition screen, report its pick and that
     condition's true success fraction. Give the cost of the ban as extra failed
     runs per 100 alcohols, compared with the PBSF condition with the highest true
     success fraction.

   TODO: Write your response.

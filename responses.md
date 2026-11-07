# PS5 written responses

Answer all three questions. Each question has two parts, (a) and (b). Replace
the line `TODO: Write your response.` with your answers, labeled (a) and (b). A
short paragraph per part is enough. Copy every number you use from the files in
`outputs/`. The README section [The three
studies](README.md#the-three-studies) describes how each file is made; question
1 uses study 1, question 2 uses study 2, and question 3 uses study 3. Keep the
blank line after each question; the checker uses it to find your answer.

1. **What did the company learn from the main screen?**
   Use `screen-summary.csv` and `posteriors.png` from study 1. Both describe the
   main screen: 480 experiments on all 20 conditions, run as 20 blocks of 24
   wells. A condition's true success fraction (column `true_success_fraction`) is
   the fraction of the 37 alcohols that the condition fluorinates in at least 50%
   yield. The best
   condition is the one with the highest true success fraction. The company
   cannot see the true success fractions, so its pick is the condition with the
   highest probability of being best (column `probability_best`).
   - **(a)** Report the company's pick, its probability of being best, its number
     of experiments, and its true success fraction. Is the pick the best
     condition? If not, name the best condition and give its true success
     fraction.
   - **(b)** Find the two conditions with the highest true success fractions;
     the best condition fluorinates one more of the 37 alcohols in at least 50%
     yield than the second-best. Suppose the company made the second-best
     condition its default instead of the best. On average, how many more of every 100
     new alcohols would fail (give less than 50% yield)? Then, for each of the
     two conditions, report its number of experiments and its probability of
     being best, and find its posterior in `posteriors.png`. Use the experiment
     counts, the probabilities of being best, and the two posteriors to explain
     why 480 experiments cannot reliably tell the two conditions apart.

   TODO: Write your response.

2. **What do reaction blocks cost?**
   Use `plate-sizes.csv` from study 2. In `plate-sizes.csv`, each row with
   `strategy` equal to `thompson` averages 100 Thompson sampling screens of 480
   experiments, all with the block size in `wells_per_block`; each block takes 2
   days. The row with `strategy` equal to `equal_split` is the baseline that runs
   every condition on exactly 24 alcohols; its `mean_successes` is computed from
   the true success fractions, not simulated.
   - **(a)** For blocks of 1, 24, 96, and 480 wells, report the days the screen
     takes (column `days`) and its mean number of successes out of 480
     experiments (column `mean_successes`). Also report the mean number of
     successes for the equal split.
   - **(b)** In a block, the company draws a new sample from every posterior for
     each well, using the posteriors as they stand at the start of the block, and
     the posteriors update only after the whole block. Use these facts to explain
     two results: (i) one 480-well block gets about as many successes as the
     equal split; (ii) 24-well blocks get about as many successes as 1-well
     blocks, which run one reaction at a time.

   TODO: Write your response.

3. **What would a PBSF ban cost?**
   When PBSF (perfluorobutanesulfonyl fluoride) fluorinates an alcohol, the
   reaction releases perfluorobutanesulfonate, the anion of PFBS
   (perfluorobutane sulfonic acid). In January 2020, the European Union added
   PFBS and its salts to the Candidate List of substances of very high concern
   under its chemicals regulation, REACH (Registration, Evaluation, Authorisation
   and Restriction of Chemicals). Suppose the company bans PBSF after the main
   screen. That leaves the 16 PBSF-free conditions, which use 3-Cl, PyFluor,
   3-CF3, or 3-NO2. The company then runs a new screen on only these 16
   conditions: 480 experiments, as 20 blocks of 24 wells. Use `pbsf-ban.csv` from
   study 3 and `conditions.csv`. In `pbsf-ban.csv`, the columns that start with
   `main_screen_` come from the main screen, and the columns that start with
   `new_screen_` come from the new screen. Both probability-of-being-best columns
   compare each condition with the other 15 PBSF-free conditions only.
   - **(a)** From the main screen, report (i) how many of the 480 experiments
     used a PBSF-free condition, (ii) the most experiments any one PBSF-free
     condition got, and (iii) the PBSF-free condition with the highest
     probability of being best, with that probability and its true success
     fraction. Then explain why the main screen says little about which PBSF-free
     condition is best. Base your explanation on how Thompson sampling chooses
     which condition to run.
   - **(b)** Report the new screen's pick (the condition with the highest
     `new_screen_probability_best`) and the pick's true success fraction. Then
     give the cost of the ban: on average, how many more of every 100 new
     alcohols would fail with the new screen's pick than with the best condition
     from question 1, which uses PBSF?

   TODO: Write your response.

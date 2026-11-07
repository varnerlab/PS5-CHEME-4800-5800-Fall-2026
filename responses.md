# PS5 written responses

Write one or two short paragraphs per question, and give the numbers you use
from the files in `outputs/`. The README section [Run the
screens](README.md#run-the-screens) describes each file. Replace each line
`TODO: Write your response.` with your answer, and keep the blank line after
each question, so that the checker can find your answer.

1. **Why can't the main screen tell the two best conditions apart?** In
   `screen-summary.csv`, find the company's pick and the best condition (the
   condition with the highest `true_success_fraction`). Compare their
   experiments, their probabilities of being best, and their posteriors in
   `posteriors.png`. Why can't 480 experiments reliably separate the two
   conditions?

   TODO: Write your response.

2. **Why do 24-well blocks cost so little?** In `plate-sizes.csv`, compare
   `mean_successes` for blocks of 1, 24, and 480 wells and for the equal split.
   In a block, every well samples from the posteriors as they stand at the start
   of the block. Use this fact to explain why one 480-well block does no better
   than the equal split, but 24-well blocks do about as well as 1-well blocks.

   TODO: Write your response.

3. **Why does the main screen say little about the PBSF-free conditions?** When
   PBSF fluorinates an alcohol, the reaction releases the anion of
   perfluorobutane sulfonic acid (PFBS), which the European Union lists as a
   substance of very high concern. Suppose the company bans PBSF after the main
   screen. In `pbsf-ban.csv`, compare how many experiments the PBSF-free
   conditions got in the main screen (`main_screen_experiments`) and in the new
   screen (`new_screen_experiments`). Use the way Thompson sampling chooses
   conditions to explain the difference. Then find the new screen's pick (the
   condition with the highest `new_screen_probability_best`). How many more of
   every 100 new alcohols would fail with the new screen's pick than with the
   best condition?

   TODO: Write your response.

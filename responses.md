# PS5 written responses

Write one or two short paragraphs per question, and give the numbers you use
from the files in `outputs/`. The README section [Run the
screens](README.md#run-the-screens) describes each file. Replace each line
`TODO: Write your response.` with your answer, and keep the blank line after
each question, so that the checker can find your answer.

1. **Why can't the main screen tell the two best conditions apart?** In
   `screen-summary.csv`, find the company's pick (the condition with the
   highest `probability_best`) and the best condition (the condition with the
   highest `true_success_fraction`). Give each condition's experiments,
   probability of being best, and true success fraction. Then use the two
   posteriors in `posteriors.png` to explain why 480 experiments cannot tell
   which of the two conditions is better.

   TODO: Write your response.

2. **Why do 24-well blocks give about as many successes as 1-well blocks?** In
   `plate-sizes.csv`, compare `mean_successes` for blocks of 1, 24, and 480
   wells and for the equal split. In a block, every well uses the counts from
   the start of the block. Use this fact to explain why one 480-well block does
   no better than the equal split. Then explain why 24-well blocks do about as
   well as 1-well blocks.

   TODO: Write your response.

3. **Why does the main screen say little about the PBSF-free conditions?** When
   PBSF fluorinates an alcohol, the reaction releases the anion of
   perfluorobutane sulfonic acid (PFBS). The European Union lists PFBS as a
   substance of very high concern. Suppose the company bans PBSF after the main
   screen. In `pbsf-ban.csv`, compare `main_screen_experiments` with
   `new_screen_experiments` for the 16 PBSF-free conditions. Use the way
   Thompson sampling chooses each run to explain the difference. Then find the
   new screen's pick (the condition with the highest
   `new_screen_probability_best`). How many more of every 100 new alcohols
   would fail with this pick than with the best condition from question 1?

   TODO: Write your response.

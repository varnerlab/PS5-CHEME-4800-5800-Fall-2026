# Problem Set 5 (PS5): One fluorination condition for many alcohols

A chemical company works as a contract research organization (CRO): it makes
compounds to order for drug discovery clients. Many orders are alkyl fluorides,
which are high-value targets in drug development. Each order specifies a starting alcohol
and asks the CRO to synthesize a small amount of that alcohol's fluoride to test. The company makes each fluoride
by **deoxyfluorination**: this reaction replaces the alcohol's hydroxyl –OH group with a
–F (fluorine) group under basic conditions. The company uses sulfonyl fluorides as the fluorinating reagents, which are inexpensive and,
unlike the traditional reagent diethylaminosulfur trifluoride (DAST), thermally
stable.

Problem Set 5 (PS5) is due: __11:59 PM ET, Saturday, November 21, 2026__. Released November 7, 2026.

## The question

Clients send the company a steady stream of orders, each for the fluoride of a
new alcohol. The company can run each alcohol conversion under any of 20 reaction
**conditions**; a condition is one sulfonyl fluoride paired with one base. However, no single
condition seems to work for every alcohol. The company wants one default condition for new alcohols, so it asks:

> **Which of the 20 conditions fluorinates the most alcohols, and how can the
> company find that condition without wasting many runs on poor conditions?**

Each **experiment**, or run, fluorinates the next alcohol in the queue with a condition the company chooses;
the company cannot choose which alcohol comes next. A run is a **success** if
the yield of the deoxyfluorination reaction is at least 50%, which gives enough product to fill the order.
Otherwise the run is a **failure**. The company wants as many
successes as possible while it learns which condition is best.

We'll explore this question using a **binary Bernoulli bandit**:

- Each of the 20 conditions is an arm.
- Each run pulls one arm: the run uses that arm's condition on the next alcohol in the company's order queue.
- The reward is `1` for a success and `0` for a failure.
- Each arm's success probability is the fraction of alcohols that its condition
  fluorinates in at least 50% yield. The company does not know these
  probabilities; it learns them from the rewards. We'll model these success probabilities using beta distributions, which are updated each time new results arrive.

You will use Thompson sampling to choose the arm for each run, with the runs
grouped in 24-well reaction blocks (24 reactions run at once, as in the company's lab), and use the results to pick the default
condition. With the same tools, you will also measure what larger reaction
blocks cost, and what a potential ban on one of the sulfonyl fluoride compounds, perfluorobutanesulfonyl
fluoride (PBSF), could cost the company.

## Setup

Use Julia `1.12.7`. Open this folder in VS Code, open a terminal, and run:

```bash
julia --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate()'
julia --startup-file=no --project=. check_submission.jl
```

The first command installs the packages. The second runs the
48 tests, which fail until you finish Parts 1 and 2.

Write your code in [src/Compute.jl](src/Compute.jl) and your answers in
[responses.md](responses.md). Do not edit any other files, with one exception: if you put
helper functions in a new file in `src/`, add that file to [Include.jl](Include.jl), so that `Compute.jl` can use the helper functions.

## Materials and Methods

The reaction data come from a published paper (Nielsen et al., 2018; see
[Sources](#sources)). Its authors ran all 20 conditions on 37 structurally
different alcohols, from simple primary, secondary, and tertiary alcohols to
drugs such as metronidazole and abiraterone: 740 reactions in all.

Every reaction is run the same way. The alcohol is dissolved in tetrahydrofuran
(THF) so that its starting concentration is 0.4 M. The amounts of sulfonyl
fluoride and base are given in equivalents (equiv), the moles of reagent per mole
of alcohol: each reaction uses 1.1 equiv of sulfonyl fluoride and 1.5 equiv of
base, so their starting concentrations are 0.44 M and 0.60 M. The mixture reacts
at room temperature for 48 h. The sulfonyl fluoride converts the hydroxyl –OH group on the alcohol into a
sulfonate ester and releases fluoride, which then replaces the sulfonate. The 20
conditions pair each of 5 sulfonyl fluorides with each of 4 bases. PS5 uses the paper's short
label for each reagent:

| Label | Full name | Type |
|---|---|---|
| 3-Cl | 4-chlorobenzenesulfonyl fluoride | sulfonyl fluoride |
| PyFluor | pyridine-2-sulfonyl fluoride | sulfonyl fluoride |
| 3-CF3 | 4-(trifluoromethyl)benzenesulfonyl fluoride | sulfonyl fluoride |
| 3-NO2 | 4-nitrobenzenesulfonyl fluoride | sulfonyl fluoride |
| PBSF | perfluorobutanesulfonyl fluoride | sulfonyl fluoride |
| DBU | 1,8-diazabicyclo[5.4.0]undec-7-ene | amidine base |
| MTBD | 7-methyl-1,5,7-triazabicyclo[4.4.0]dec-5-ene | guanidine base |
| BTMG | 2-*tert*-butyl-1,1,3,3-tetramethylguanidine | guanidine base |
| BTPP | *tert*-butylimino-tri(pyrrolidino)phosphorane | phosphazene base |

In 3-Cl, 3-CF3, and 3-NO2, the 3 is the paper's compound number (not a ring
position).

The **yield** is the percent of the alcohol converted to the alkyl fluoride,
measured by fluorine-19 nuclear magnetic resonance (¹⁹F NMR) spectroscopy of the
crude reaction mixture. The 50% cutoff for a success is our choice, not the
paper's.

PS5 uses the paper's yields to simulate the company's experiments. For each
experiment, the simulator draws one of the 37 alcohols at random and looks up
that alcohol's measured yield under the chosen condition.

Calling `screen = load_screen()` ([src/Data.jl](src/Data.jl)) loads the paper's
data into `screen`, which has these fields:

| Field | Meaning |
|---|---|
| `screen.yields` | The 37 × 20 yield table, in percent: one row per alcohol, one column per condition. |
| `screen.conditions` | The name of each condition, such as `"PBSF/BTMG"`, in column order. |
| `screen.sulfonyl_fluorides`, `screen.bases` | The sulfonyl fluoride and the base of each column. |
| `screen.alcohols`, `screen.smiles` | The alcohol IDs (`s1` to `s37`) and their structures as SMILES (Simplified Molecular Input Line Entry System) strings, a text code for molecules. |

Each condition has a number, `a`, which is its column in `screen.yields`:

| Sulfonyl fluoride | DBU | MTBD | BTMG | BTPP |
|---|---|---|---|---|
| 3-Cl | 1 | 2 | 3 | 4 |
| PyFluor | 5 | 6 | 7 | 8 |
| 3-CF3 | 9 | 10 | 11 | 12 |
| 3-NO2 | 13 | 14 | 15 | 16 |
| PBSF | 17 | 18 | 19 | 20 |

For example, condition 19 is PBSF/BTMG, and its yields are in column 19.

The **true success fraction** of condition $a$, written $\theta_a$, is the
fraction of the 37 alcohols that condition $a$ fluorinates in at least 50%
yield. For example, condition 1 (3-Cl/DBU) gives at least 50% yield on 4 of the
37 alcohols, so the true success fraction of condition 1 is 4/37, about 0.11.

Each simulated run draws one of the 37 alcohols with equal chance. So $\theta_a$
is also the probability that one run with condition $a$ succeeds. The company
never sees $\theta_a$, only whether each run succeeded. You compute $\theta_a$ in
Part 1.

The simulator is the function `run_reaction(yields, a, rng)`
([src/Lab.jl](src/Lab.jl)). For condition `a`, `run_reaction` draws the alcohol with
`i = rand(rng, 1:37)` and returns `1` if `yields[i, a] >= 50.0` and `0` otherwise.

Your two Thompson sampling functions, `my_thompson_sampling` and
`plate_thompson_sampling`, never see the yield table. Instead, both functions
take the **world** as the first argument. The world is a function that runs one
experiment: `world(a)` returns the reward of one run with condition `a`. The
supplied code makes the world in one line:

```julia
rng = MersenneTwister(5825); # one random number generator for the agent and the world
world = a -> run_reaction(screen.yields, a, rng); # world(a) runs one experiment with condition a
```

The agent and the world share one generator, and each function draws its random
numbers in the order its description gives. So every correct solution gets
exactly the same numbers.

## Part 1: Thompson sampling, one reaction at a time

Before any runs, the company believes every success fraction from 0 to 1 is
equally likely: the **prior** $\text{Beta}(1,1)$. After $S(a)$ successes and
$F(a)$ failures with condition $a$, the company's updated belief, the **posterior**, is
$\text{Beta}(1+S(a),1+F(a))$. The posterior is a curve over 0 to 1 that peaks
near the observed success fraction and gets narrower as runs add up. Thompson
sampling draws one sample from each condition's posterior and runs the condition
with the largest sample.

Implement in [src/Compute.jl](src/Compute.jl):

1. **`success_fractions(yields; cutoff = 50.0)`:** returns the true success
   fraction $\theta_a$ of each condition (column).
2. **`my_thompson_sampling(world, K, T; rng, α, β)`:** plays `T` rounds of
   Thompson sampling on `K` arms and returns the actions, the rewards, and the
   counts `S` and `F`. This is the function from Task 3 of the L10d lab, with
   the same arguments and results.

The description above each function in [src/Compute.jl](src/Compute.jl) gives
the exact order of the random draws, the inputs it must reject, and the error to
throw. Test with:

```bash
julia --startup-file=no --project=. testme_part_1.jl
```

## Part 2: Reaction blocks, and choosing a condition

Each reaction runs for 48 h. Choosing one reaction, waiting for its result, and
then choosing the next would take two days per experiment. So the company runs a
24-well **reaction block** (a plate): it chooses the condition of every well
before any result in the block comes back, and the results arrive together, one
block every two days. In a block, the company draws a new sample from every
posterior for each well, using the posteriors as they stand at the start of the
block, and runs the condition with the largest sample in that well. Each well
gets its own samples, so different wells can get different conditions. The
counts update only after the whole block. A **screen** is a
series of blocks run one after another.

At the end of a screen, the company picks a condition. A condition's
**probability of being best** is the chance, given the posteriors, that its true
success fraction is the highest of all. To estimate this probability, draw one sample from
every posterior many times and count how often each condition has the largest
sample. **The company's pick is the condition with the highest probability of
being best.**

Implement in [src/Compute.jl](src/Compute.jl):

1. **`plate_thompson_sampling(world, K, plates, wells; rng, α, β)`:** plays
   `plates` blocks of `wells` experiments each and returns the same four results
   as `my_thompson_sampling`.
2. **`probability_best(S, F, N; rng, α, β)`:** estimates each condition's
   probability of being best from the counts, using `N` sets of posterior
   samples.

When both functions are done, run:

```bash
julia --startup-file=no --project=. testme_part_2.jl
julia --startup-file=no --project=. runscreen.jl
```

## The three studies

The script `runscreen.jl` uses your four functions and the simulator to run
three studies. It prints the picks and writes the reports to the `outputs/`
directory. The three questions in [responses.md](responses.md) use these
reports, one study per question. All three studies use these terms:

- **Experiment**, or run: one well. The simulator draws one of the 37 alcohols
  at random, and the reward is 1 if the well's condition gives at least 50%
  yield on that alcohol, and 0 if not.
- **Reaction block**: a set of wells whose conditions are all chosen at the
  start and whose results all arrive 2 days (48 h) later.
- **Screen**: a series of blocks with 480 experiments in all, run by Thompson
  sampling. A screen starts from the prior, $\text{Beta}(1,1)$, for every
  condition, and it uses no results from any other screen. At the end,
  `probability_best` gives each condition's probability of being best, and the
  condition with the highest one is the screen's **pick**.
- **Best condition**: the condition with the highest true success fraction,
  $\mu^\star$. The company cannot see the true success fractions. The reports
  show them so you can judge the company's choices.
- **Gap** of condition $a$: $\Delta(a)=\mu^\star-\theta_a$, the average number
  of successes per experiment that condition $a$ gives up compared with the best
  condition.
- **Gap loss** of a screen: $G(T)=\sum_{t=1}^{T}\Delta(a_t)$, the sum of the
  gaps of the conditions used in the screen's experiments. The gap loss is the expected number of
  extra failed experiments compared with using the best condition in every
  experiment.

| Study | Conditions | Screens | Wells per block | Reports | Question |
|---|---|---|---|---|---|
| 1. Main screen | All 20 | 1 | 24 | `screen-summary.csv`, `posteriors.png` | 1 |
| 2. Block size | All 20 | 100 for each block size | 1, 6, 24, 96, or 480 | `plate-sizes.csv`, `gap-loss.png` | 2 |
| 3. PBSF ban | The 16 without PBSF | 1 new screen, plus the counts from study 1 | 24 | `pbsf-ban.csv` | 3 |

One more report, `conditions.csv`, comes from the yield table, not from a
screen. The file has one row per condition, with these columns: `condition`,
`sulfonyl_fluoride`, and `base`; `alcohols_at_or_above_cutoff`, the number of the
37 alcohols that the condition fluorinates in at least 50% yield; `alcohols`,
which is 37; `true_success_fraction`; and `gap`.

### Study 1: the main screen

Study 1 is the screen the company runs: one screen on all 20 conditions, as 20
blocks of 24 wells, for 480 experiments over 40 days. After the last block,
`probability_best` uses 10,000 sets of samples, and the pick becomes the
company's default condition for new alcohols. Reports:

- `screen-summary.csv`: one row per condition, with these columns: `experiments`
  (the number of wells that used the condition), `successes`, `failures`,
  `posterior_mean` (the mean of the condition's posterior), `probability_best`,
  and `true_success_fraction`.
- `posteriors.png`: the posteriors after the 480 experiments, for the six
  conditions with the most experiments and for the condition with the lowest
  true success fraction. A dashed line marks each condition's true success
  fraction.

### Study 2: block size

A larger block finishes a screen in fewer days, but the posteriors update less
often. To measure this trade-off, the script runs screens on all 20 conditions
with five block sizes. Every screen has 480 experiments:

| Wells per block | Blocks | Days | Function |
|---|---|---|---|
| 1 | 480 | 960 | `my_thompson_sampling` (one reaction at a time) |
| 6 | 80 | 160 | `plate_thompson_sampling` |
| 24 | 20 | 40 | `plate_thompson_sampling` (the main screen's setup) |
| 96 | 5 | 10 | `plate_thompson_sampling` |
| 480 | 1 | 2 | `plate_thompson_sampling` |

The results of one screen depend on which alcohols the simulator happens to
draw. So for each block size, the script runs 100 screens, each with different
random draws, and averages the results of the 100 screens. Each screen's pick uses `probability_best`
with 2,000 sets of samples.

The comparison also has a baseline with no learning, the **equal split**: run
every condition on 24 alcohols, 20 × 24 = 480 experiments. The equal split's gap loss is 24
times the sum of the 20 gaps, computed from the true success fractions rather
than simulated. Reports:

- `plate-sizes.csv`: one row per block size, with `strategy` equal to
  `thompson`, then one row for the equal split, with `strategy` equal to
  `equal_split`. The columns are `wells_per_block`, `blocks`, and `days`;
  `mean_successes`, the successes per screen; `mean_gap_loss`, the gap loss
  after all 480 experiments; `pick_is_best`, the fraction of screens whose pick
  is the best condition; and `pick_in_top_two`, the fraction whose pick is the
  best or the second-best condition. Each Thompson sampling row averages its 100
  screens. The equal-split row fills in only `mean_successes` and
  `mean_gap_loss`.
- `gap-loss.png`: the mean gap loss after each of the 480 experiments, with one
  curve for each block size and a dashed straight line for the equal split.

### Study 3: the PBSF ban

Suppose that after the main screen the company bans PBSF. When PBSF fluorinates
an alcohol, the reaction releases the anion of perfluorobutane sulfonic acid (PFBS), which
the European Union lists as a substance of very high concern; question 3 gives
the details. Without PBSF, 16 conditions remain: columns 1–16, which use 3-Cl,
PyFluor, 3-CF3, or 3-NO2. The script looks for the best of these 16 in two ways:

1. **From the main screen's counts.** The script keeps the main screen's counts for the
   16 PBSF-free conditions, drops the 4 PBSF conditions, and runs
   `probability_best` on the 16 (10,000 sets of samples). This step takes no new
   experiments.
2. **From a new screen.** The script runs a new screen on the 16 PBSF-free conditions
   only: 20 blocks of 24 wells, 480 experiments over 40 days. Like every screen,
   the new screen starts again from the prior. The new screen's pick is the condition with the highest
   probability of being best among the 16 (10,000 sets of samples).

Report:

- `pbsf-ban.csv`: one row per PBSF-free condition. The three columns that start
  with `main_screen_` give the condition's experiments, posterior mean, and
  probability of being best among the 16, from the main screen's counts. The
  three columns that start with `new_screen_` give the same numbers from the new
  screen. The last column is the condition's `true_success_fraction`.

## Check and submit

Run the checker:

```bash
julia --startup-file=no --project=. check_submission.jl
```

The checker runs the 48 tests, checks that you answered all three questions, and
writes `MANIFEST.txt`, a record of your results and files. It also deletes the
old reports in `outputs/` and, if every test passes, makes new ones as
`runscreen.jl` does. It does not submit anything.

Zip the whole folder, including `MANIFEST.txt` and `outputs/`, as
`CHEME-4800-5800-PS5-<netid>.zip` (for example,
`CHEME-4800-5800-PS5-abc123.zip`) and upload it to Canvas. If some tests still
fail at the deadline, submit anyway for partial credit. See
[RUBRIC.md](RUBRIC.md) for the grading scale.

## Policies

- **Revisions:** Submit something by the deadline, even if it does not run. You
  may then revise and resubmit until the end of the semester; your highest score
  counts. No initial submission means a score of `0` and no revisions.
- **Reference solution:** Released after the deadline. Use it to understand and
  debug your work; copying it results in a score of `0`.
- **Collaboration and AI:** Discuss ideas with classmates, but do not share code
  or solutions. You may use Julia documentation, AI tools, and internet
  resources. You must be able to explain your code.

## Sources

The yields come from **Nielsen, Ahneman, Riera, and Doyle (2018),
"Deoxyfluorination with Sulfonyl Fluorides: Navigating Reaction Space with
Machine Learning," Journal of the American Chemical Society, 140(15), 5004–5008**
([DOI: 10.1021/jacs.8b01523](https://doi.org/10.1021/jacs.8b01523)). We use the
table as published in the repository of **Wang et al. (2024), "Identifying
general reaction conditions by bandit optimization," Nature, 626, 1025–1033**
([DOI: 10.1038/s41586-024-07021-y](https://doi.org/10.1038/s41586-024-07021-y)),
which used bandit methods to find general reaction conditions. Thompson sampling
comes from **Thompson (1933), "On the likelihood that one unknown probability
exceeds another in view of the evidence of two samples," Biometrika, 25(3–4),
285–294** ([DOI: 10.1093/biomet/25.3-4.285](https://doi.org/10.1093/biomet/25.3-4.285)).

The data file is shared under the MIT license; see
[THIRD_PARTY_NOTICES.txt](THIRD_PARTY_NOTICES.txt). The company and its stream
of orders are made up for this problem set. The [data
notes](data/README.md) describe the file and its column order.

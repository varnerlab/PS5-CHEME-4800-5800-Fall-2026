# Problem Set 5 (PS5): One fluorination condition for many alcohols

A medicinal chemistry group makes many alkyl fluorides, which are high-value
targets in drug development. It makes each one from the matching alcohol by
**deoxyfluorination**: the reaction replaces the alcohol's –OH group with –F. The
group uses sulfonyl fluorides, which are inexpensive and, unlike the traditional
reagent DAST, thermally stable.

Every reaction is run the same way: the alcohol, a sulfonyl fluoride (1.1 equiv),
and a base (1.5 equiv) in THF (0.4 M) at room temperature for 48 h. The sulfonyl
fluoride turns the –OH into a sulfonate ester and releases fluoride, which then
replaces the sulfonate. A **condition** is one of 5 sulfonyl fluorides (3-Cl,
PyFluor, 3-CF3, 3-NO2, PBSF) paired with one of 4 bases (DBU, MTBD, BTMG, BTPP):
20 conditions in all. These are the paper's labels; the [data
notes](data/README.md) give the full names. The **yield** is the percent of the
alcohol converted to the alkyl fluoride, measured by ¹⁹F NMR of the crude reaction
mixture. A run is a **success** if the yield is at least 50%; the 50% cutoff is
our choice, not the paper's.

Project chemists send the group a steady stream of alcohols. Each experiment
fluorinates the next alcohol in the queue with a condition the group chooses. A
success gives enough product to carry the compound forward; a failure wastes the
run. The group cannot choose which alcohol comes next, only the condition. It
wants as many successes as possible while it learns which condition works on the
most alcohols. That condition then becomes its default for new alcohols.

This is a binary Bernoulli bandit, as in Week 10: the 20 conditions are the arms,
the incoming alcohol is the random part of the world, and each run's reward is 1
for a success and 0 for a failure. You will write Thompson sampling, run it in
24-well reaction blocks, use the results to choose a condition, and find what a
ban on PBSF costs.

Problem Set 5 (PS5) is due: __11:59 PM ET, Saturday, November 21, 2026__. Released November 7, 2026.

## Setup

Use Julia `1.12.7`. Open this folder in VS Code, open a terminal, and run:

```bash
julia --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate()'
julia --startup-file=no --project=. check_submission.jl
```

The first command installs the packages. The second runs the
48 tests, which fail until you finish Parts 1 and 2.

Write your code in [src/Compute.jl](src/Compute.jl) and your answers in
[responses.md](responses.md). Edit no other file, with one exception: if you put
helper functions in a new file in `src/`, add it to [Include.jl](Include.jl),
which shows an example.

The data loader, `load_screen`, and the simulator, `run_reaction`, are already
written in [src/Data.jl](src/Data.jl) and [src/Lab.jl](src/Lab.jl). Do not change
those files.

## Materials and Methods

The yields come from a published screen (Nielsen et al., 2018; see
[Sources](#sources)) that ran all 20 conditions on 37 structurally different
alcohols, from simple primary, secondary, and tertiary alcohols to drugs such as
metronidazole and abiraterone: 740 reactions. In PS5, the published yields stand
in for the lab. In a real campaign, each experiment would use a new alcohol, but
we have yields for only these 37. So the simulator draws one of the 37 at random
for each experiment, with repeats allowed, and looks up its measured yield under
the chosen condition. A repeated alcohol gives the same yield: the simulation has
no run-to-run noise.

Calling `screen = load_screen()` ([src/Data.jl](src/Data.jl)) returns:

| Field | Meaning |
|---|---|
| `screen.yields` | The 37 × 20 yield table, in percent: one row per alcohol, one column per condition. |
| `screen.conditions` | The name of each condition, such as `"PBSF/BTMG"`, in column order. |
| `screen.sulfonyl_fluorides`, `screen.bases` | The sulfonyl fluoride and the base of each column. |
| `screen.alcohols`, `screen.smiles` | The alcohol IDs (`s1` to `s37`) and their structures as SMILES strings, a text code for molecules. |

**Condition `a` is column `a` of `screen.yields`.** Columns 1–4 use 3-Cl, 5–8
PyFluor, 9–12 3-CF3, 13–16 3-NO2, and 17–20 PBSF. Within each group of four, the
bases are DBU, MTBD, BTMG, and BTPP, in that order. For example, column 19 is
PBSF/BTMG.

The **true success fraction** $\theta_a$ of condition $a$ is the fraction of the
37 alcohols on which it gives a yield of at least 50%. Because the simulator
draws every alcohol with the same chance, $\theta_a$ is also the success
probability of one run with condition $a$. Only we know it; the group sees only
the reward of each run.

The simulator `run_reaction(yields, a, rng)` ([src/Lab.jl](src/Lab.jl)) runs one
experiment with condition `a`: it draws one alcohol, `i = rand(rng, 1:37)`, and
returns `1` if `yields[i, a] >= 50.0` and `0` otherwise. As in the L10d lab, the
bandit functions never see the table. They take the **world**, a function that
runs one experiment: `world(a)` returns the reward of one run with condition `a`.
The supplied code makes the world in one line:

```julia
rng = MersenneTwister(5825); # one random number generator for the agent and the world
world = a -> run_reaction(screen.yields, a, rng); # world(a) runs one experiment with condition a
```

The agent and the world share one generator, and each function draws its random
numbers in the order its description gives. So every correct solution gets
exactly the same numbers.

## Part 1: Thompson sampling, one reaction at a time

Before any runs, the group believes every success fraction from 0 to 1 is equally
likely: the **prior** $\text{Beta}(1,1)$. After $S(a)$ successes and $F(a)$
failures with condition $a$, its updated belief, the **posterior**, is
$\text{Beta}(1+S(a),1+F(a))$. The posterior is a curve over 0 to 1 that peaks near
the observed success fraction and gets narrower as runs add up. Thompson sampling
draws one sample from each condition's posterior and runs the condition with the
largest sample.

Implement in [src/Compute.jl](src/Compute.jl):

1. **`success_fractions(yields; cutoff = 50.0)`:** returns the true success
   fraction $\theta_a$ of each condition (column).
2. **`my_thompson_sampling(world, K, T; rng, α, β)`:** plays `T` rounds of
   Thompson sampling on `K` arms and returns the actions, the rewards, and the
   counts `S` and `F`. This is the function from Task 3 of the L10d lab, with the
   same arguments and results.

The description above each function in [src/Compute.jl](src/Compute.jl) gives
the exact order of the random draws, the inputs it must reject, and the error to
throw. Test with:

```bash
julia --startup-file=no --project=. testme_part_1.jl
```

## Part 2: Reaction blocks, and choosing a condition

Each reaction runs for 48 h. Choosing one reaction, waiting for its result, and
then choosing the next would take two days per experiment. So the group runs a
24-well **reaction block** (a plate): it chooses the condition of every well
before any result in the block comes back, and the results arrive together, one
block every two days. In a block, each well draws its own samples from the
posteriors as they stand at the start of the block, so different wells can get
different conditions. The counts update after the whole block.

After the screen, the group picks a condition. A condition's **probability of
being best** is the chance, given the posteriors, that its true success fraction
is the highest of all. To estimate it, draw one sample from every posterior many
times and count how often each condition has the largest sample. **The group's
pick is the condition with the highest probability of being best.**

Implement in [src/Compute.jl](src/Compute.jl):

1. **`plate_thompson_sampling(world, K, plates, wells; rng, α, β)`:** plays
   `plates` blocks of `wells` experiments each and returns the same four results
   as `my_thompson_sampling`.
2. **`probability_best(S, F, N; rng, α, β)`:** estimates each condition's
   probability of being best from the counts, using `N` sets of posterior samples.

When both functions are done, run:

```bash
julia --startup-file=no --project=. testme_part_2.jl
julia --startup-file=no --project=. runscreen.jl
```

The script `runscreen.jl` runs three things. First, the main screen: 20 blocks of
24 wells (480 experiments, 40 days) on all 20 conditions, then `probability_best`
with 10,000 sets of samples. Second, 100 new screens of 480 experiments for each
block size: 1, 6, 24, 96, and 480 wells per block. Third, a new screen on the 16
conditions without PBSF. It prints the picks of the main and PBSF-free screens and
writes these files to the `outputs/` directory:

| File | Contents |
|---|---|
| `conditions.csv` | Each condition's reagents, the number of the 37 alcohols it fluorinates in at least 50% yield, its true success fraction, and its gap (below). |
| `screen-summary.csv` | The main screen: each condition's experiments, successes, failures, posterior mean, probability of being best, and true success fraction. |
| `posteriors.png` | The posteriors of the six most-run conditions and of the condition with the lowest true success fraction, after the main screen, each with a dashed line at its true success fraction. |
| `plate-sizes.csv` | For each block size, averaged over 100 screens: days, successes, gap loss (below), the fraction of screens whose pick is the best condition, and the fraction whose pick is one of the two best. The last row, computed rather than simulated, is the equal split, which runs every condition on 24 alcohols. |
| `gap-loss.png` | The mean gap loss after each experiment for each block size and for the equal split. |
| `pbsf-ban.csv` | For each PBSF-free condition: experiments, posterior mean, and probability of being best among the 16, from the main screen and from the new screen; and its true success fraction. |

The **gap** of condition $a$, $\Delta(a)=\mu^\star-\theta_a$, is the average
number of successes per run it gives up compared with the best condition, whose
true success fraction is $\mu^\star$. The **gap loss** of a screen,
$G(T)=\sum_{t=1}^{T}\Delta(a_t)$, adds up the gap of the condition used in each
run. It is the expected number of extra failed runs compared with always using the
best condition.

Use these files to answer the three questions in [responses.md](responses.md).

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
`CHEME-4800-5800-PS5-<netid>.zip` (for example, `CHEME-4800-5800-PS5-abc123.zip`)
and upload it to Canvas. If some tests still fail at the deadline, submit anyway
for partial credit. See [RUBRIC.md](RUBRIC.md) for the grading scale.

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
[THIRD_PARTY_NOTICES.txt](THIRD_PARTY_NOTICES.txt). The medicinal chemistry group
and its stream of alcohols are made up for this problem set. The
[data notes](data/README.md) describe the file and its column order.

# PS5 instructor notes

The student task is fixed: write Thompson sampling for the binary Bernoulli bandit,
run it on a published deoxyfluorination screen (20 conditions, 37 alcohols), extend
it to 24-well reaction blocks, choose a condition by its probability of being
best, and see what a PBSF ban costs. Parts 1–2 require four functions
(`success_fractions`, `my_thompson_sampling`, `plate_thompson_sampling`,
`probability_best`) and three written responses, graded out of four points using
48 tests. There is no Advanced track. `my_thompson_sampling` is the L10d Task 3
function, with the lab's name, arguments, and results; class ran out of time
before Task 3, so students write it here. Its lab solution is public, and that is
acceptable. The loader and the simulator, `run_reaction`, are supplied. The design
is recorded in [DESIGN.md](DESIGN.md) and the build plan in [plans/](plans/); both
are local files, ignored by Git, because DESIGN.md lists the ideas expected in the
answers.

## Reviewing the assignment

- Read [the problem statement](../README.md), [rubric](../RUBRIC.md), and
  [questions](../responses.md).
- Inspect the reference reports in [reference/](reference/):
  [posteriors](reference/posteriors.png) and the CSV tables.
- The local, Git-ignored [reference solution](../solution/README.md) contains
  completed code, sample written responses, and the reference numbers.
- [The student ZIP](artifacts/PS5-CHEME-4800-5800-Fall-2026-student.zip)
  contains starter code and data, with no instructor files, outputs, or solutions.

Release is Saturday, November 7, 2026. The initial submission deadline is
11:59 PM ET on Saturday, November 21, 2026. No commit, push, tag, GitHub release,
or Canvas upload is performed by these scripts.

Students download the **Source code (zip)** of the tagged GitHub release
`ps5-cheme-4800-5800-2026.1` of `varnerlab/PS5-CHEME-4800-5800-Fall-2026`;
`.gitattributes` keeps instructor material out of that archive. Pushing the tag
runs the [release Action](../.github/workflows/release-ps5.yml), which runs
[validate_release.py](validate_release.py) on the source archive and creates a
**draft** release with the [release notes](release-notes.md). That validator
needs no reference solution; run it locally with
`python3 instructor/validate_release.py` before tagging (it needs a committed
Git tree). Review and publish the draft, then post the
[Canvas description](canvas-assignment-description.html), which links to the
same tag. Later corrections use a new tag.

## Reproducing the checks

To run the reference solution directly from the assignment root:

```bash
julia --startup-file=no --project=. check_submission.jl --solution
```

This runs all 48 tests, checks `solution/responses.md`, and writes the reports to
`solution/outputs/` and a manifest to `solution/MANIFEST.txt`. The student files
and outputs stay unchanged. The same flag works with `testme_part_1.jl`,
`testme_part_2.jl`, and `runscreen.jl`. The default remains the student
implementation; a missing local solution causes an error rather than falling back
to student code.

From the assignment root, install the Julia dependencies and run:

```bash
julia --startup-file=no --project=. -e 'using Pkg; Pkg.instantiate()'
python3 instructor/validate.py
python3 instructor/build_student_package.py
```

The validator first runs [test_supplied.jl](test_supplied.jl), separate from
student scores, once without and once with `--solution`. It checks the loader
(shape, column order, values against the CSV, Windows line endings, and clear
errors for a cut-short or missing file), `run_reaction` (exactly one draw,
inclusive cutoff, rejected conditions, and long-run success rate). It checks that the L10d lab solution reproduces the stored Thompson game
and, with `--solution`, plays the same 500-round game as the reference. The
Git-ignored `solution/check_reference.jl`, also run by the validator, reproduces the
stored block games with a separately written block implementation and checks the
equal-split row; it stays out of Git because that implementation would be a Part 2a
solution. It reads the lab solution from the sibling course repository and skips
those comparisons with a warning when the repository is absent, as in the release
Action. The validator then copies the student files into temporary directories and
substitutes the reference implementation only in those copies. It checks all 48
tests, the driver, and the checker's handling of unfinished code, partial work,
syntax errors, missing responses, Windows line endings, runs from another folder,
and reporting errors. Logs are in `instructor/validation-output/`; reference
reports are copied to `instructor/reference/`. Both directories are ignored by Git
and excluded from the student package.

To rebuild the data, run `python3 -I instructor/import_data.py`. It downloads
`datasets/deoxyf.csv` and `LICENSE.md` from `doyle-lab-ucla/bandit-optimization`
at commit `084bb561a200ee5950a215c7026012878a7bc065`, checks the CSV's SHA-256,
its shape, and the MIT license text, and rewrites `data/`. It never reads a local
copy.

## Reference results

The reference numbers are in the Git-ignored
[solution README](../solution/README.md). They are the numbers students report,
so they stay off GitHub until the reference solution is released.

## Modeling choices

- **Data and license.** The yields are the 37 × 20 table of Nielsen et al. (2018),
  taken from the repository of Wang et al. (2024) at the last commit that changed
  the file. At that commit the repository is MIT-licensed; it changed to GPL-3.0 on
  March 7, 2025. PS5 ships the MIT-licensed version with its license text
  (`data/LICENSE-bandit-optimization.txt`) and notices in
  `THIRD_PARTY_NOTICES.txt`, `data/README.md`, and `data/provenance.json`.
- **Story.** Every reaction detail (1.1 equiv sulfonyl fluoride, 1.5 equiv base,
  THF 0.4 M, room temperature, 48 h, ¹⁹F NMR yield, sulfonate-ester intermediate)
  is from Figure 1 of Nielsen et al. (2018). The medicinal chemistry group and its
  stream of alcohols are made up; the README says so.
- **Column order.** Sulfonyl fluoride first (3-Cl, PyFluor, 3-CF3, 3-NO2, PBSF),
  then base (DBU, MTBD, BTMG, BTPP), so the 16 PBSF-free conditions are columns
  1–16. The results do not depend on the order.
- **Cutoff 50%, inclusive.** The cutoff is ours, not the paper's; the README says
  so. Four yields are exactly 50. Nine alcohols never reach 50%, so no condition
  can exceed 28 of 37; the best, PBSF/BTMG, reaches 23.
- **Exact numbers.** The agent and the world share one `MersenneTwister`, and each
  docstring fixes the draw order, so every correct submission gives identical
  numbers. The tests compare exact action sequences and counts with literals
  stored in `test_support.jl`, so no reference code ships.
- **Closures.** The bandit functions take the lab's `world` function, made by a
  one-line closure `a -> run_reaction(yields, a, rng)`. The instructor allowed this
  on November 5, 2026, because students see closures in the labs that week.
- **Block sizes and seeds.** The block-size table uses 1, 6, 24, 96, and 480 wells
  per block over seeds 1–100, with 2,000 rounds of `probability_best` per screen;
  the main screens use 10,000 rounds. A design check in Python gave the same
  pattern; its numbers are in the Git-ignored solution README.
- **No greedy comparison.** The design review found that greedy's result depends
  on the column order (untried conditions tie at the prior mean and ties go to the
  first column), so the equal split is the only comparison. It needs no
  simulation.
- **Seed 5825 for the main and PBSF-free screens.** The planned seed, 5800, made
  questions 1 and 3 unclear, so later seeds were checked against criteria fixed
  beforehand. The criteria and the reason are in the Git-ignored
  [solution README](../solution/README.md), because they describe the answers.
- **Verified facts.** Thompson (1933), *Biometrika* 25(3–4), 285–294, checked on
  Crossref. PFBS and its salts were added to the ECHA Candidate List of substances
  of very high concern on 16 January 2020 (Article 57(f), human health and
  environment; ECHA decision ECHA/01/2020), checked against ECHA's Candidate List
  table as archived by the Internet Archive on 16 March 2020 (ECHA's site blocks
  automated requests). Nielsen et al. (2018) describe a rate-limiting SN2
  substitution between fluoride and the intermediate sulfonate ester and call
  PBSF's leaving group "the exceptionally reactive perfluorobutanesulfonate leaving
  group", checked against the paper's text.

## Preparing a release

Review the dates in the main README and the student workload, then run the
validation and build scripts. The builder refuses a release package with dates
still marked to be announced. It uses an explicit allowlist and checks that the
four starter errors remain in `src/Compute.jl`.

The reference code, sample answers, and generated reference outputs are kept
outside the student archive. Keep the data attribution in
[THIRD_PARTY_NOTICES.txt](../THIRD_PARTY_NOTICES.txt).

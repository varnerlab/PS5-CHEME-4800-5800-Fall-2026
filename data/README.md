# Deoxyfluorination data

Source: the high-throughput deoxyfluorination experiments of Nielsen, Ahneman,
Riera, and Doyle (2018), shared in the repository of a later study that used
these data to test bandit algorithms.

Measurements: Nielsen, M. K.; Ahneman, D. T.; Riera, O.; Doyle, A. G. (2018).
**Deoxyfluorination with Sulfonyl Fluorides: Navigating Reaction Space with
Machine Learning.** *Journal of the American Chemical Society*, **140**(15),
5004–5008. [DOI: 10.1021/jacs.8b01523](https://doi.org/10.1021/jacs.8b01523).

Repository: Wang, J. Y. et al. (2024). **Identifying general reaction
conditions by bandit optimization.** *Nature*, **626**, 1025–1033.
[DOI: 10.1038/s41586-024-07021-y](https://doi.org/10.1038/s41586-024-07021-y).
Code and data: [doyle-lab-ucla/bandit-optimization](https://github.com/doyle-lab-ucla/bandit-optimization).

| File | Contents |
|---|---|
| [deoxyfluorination.csv](deoxyfluorination.csv) | The yield of each of the 740 reactions: 37 alcohols, each run under 20 conditions. |
| [provenance.json](provenance.json) | Where the data file came from, with checksums (digital fingerprints) of the source file and of the two files PS5 provides. |
| [LICENSE-bandit-optimization.txt](LICENSE-bandit-optimization.txt) | The license of the source repository. |

## The reactions

Each reaction replaces the alcohol's hydroxyl –OH group with a –F (fluorine)
group. The alcohol, a
sulfonyl fluoride (1.1 equiv), and a base (1.5 equiv) react at 0.4 M in
tetrahydrofuran (THF) at room temperature for 48 h. The yield is the percent of
the alcohol converted to the alkyl fluoride, measured by fluorine-19 nuclear
magnetic resonance (¹⁹F NMR) spectroscopy of the crude reaction mixture. The
paper's authors ran all 20 conditions on 32 alcohols to train a machine learning
model, and on 5 more to test it; the file has all 37.

A **condition** is one sulfonyl fluoride paired with one base. The paper used
5 sulfonyl fluorides and 4 bases, so there are 20 conditions. Everything else is
the same in every reaction. The file uses the paper's short label for each
reagent:

| Label | Full name | Type |
|---|---|---|
| 3-Cl | 4-chlorobenzenesulfonyl fluoride | sulfonyl fluoride |
| PyFluor | pyridine-2-sulfonyl fluoride | sulfonyl fluoride |
| 3-CF3 | 4-(trifluoromethyl)benzenesulfonyl fluoride | sulfonyl fluoride |
| 3-NO2 | 4-nitrobenzenesulfonyl fluoride | sulfonyl fluoride |
| PBSF | perfluorobutanesulfonyl fluoride (C4F9SO2F) | sulfonyl fluoride |
| DBU | 1,8-diazabicyclo[5.4.0]undec-7-ene | amidine base |
| MTBD | 7-methyl-1,5,7-triazabicyclo[4.4.0]dec-5-ene | guanidine base |
| BTMG | 2-*tert*-butyl-1,1,3,3-tetramethylguanidine | guanidine base |
| BTPP | *tert*-butylimino-tri(pyrrolidino)phosphorane | phosphazene base |

In 3-Cl, 3-CF3, and 3-NO2, the 3 is the paper's compound number, not a ring
position.

## File layout

Each row of [deoxyfluorination.csv](deoxyfluorination.csv) is one reaction:

| Column | Meaning |
|---|---|
| `alcohol` | The alcohol's ID, `s1` to `s37`. |
| `alcohol_smiles` | The alcohol's structure, written as a SMILES (Simplified Molecular Input Line Entry System) string. |
| `sulfonyl_fluoride` | The sulfonyl fluoride used. |
| `base` | The base used. |
| `yield_percent` | The ¹⁹F NMR yield of the alkyl fluoride, in percent. |

The rows go alcohol by alcohol, from `s1` to `s37`. Within each alcohol, the
conditions follow the paper's order: the sulfonyl fluorides from least to most
reactive (3-Cl, PyFluor, 3-CF3, 3-NO2, PBSF), and for each one, the bases from
least to most bulky (DBU, MTBD, BTMG, BTPP). The same order sets the columns of
`yields`: column 1 is 3-Cl/DBU, column 20 is PBSF/BTPP, and columns 17 to 20
are the four PBSF conditions.

You do not need to read the CSV file yourself. The function `load_screen()` in
[src/Data.jl](../src/Data.jl) reads it into a 37 × 20 table, with one row per
alcohol and one column per condition.

## Things to know

- Yields are whole numbers from 0 to 106, as published. A ¹⁹F NMR yield can
  read a little above 100% because of measurement error.
- Nine alcohols (`s3`, `s6`, `s8`, `s15`, `s19`, `s24`, `s25`, `s28`, `s31`)
  give less than 50% yield under every condition. So no condition reaches 50% on
  more than 28 of the 37 alcohols.

## License

At the commit PS5 uses, the source repository is under the MIT license. See
[THIRD_PARTY_NOTICES.txt](../THIRD_PARTY_NOTICES.txt) for the full notice and
the changes made for PS5.

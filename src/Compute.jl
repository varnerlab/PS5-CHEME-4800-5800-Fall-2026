# Student implementation | Complete the four functions in Parts 1 and 2.
# Already written for you: Data.jl loads the yield table with load_screen();
# Lab.jl holds run_reaction, which runs one experiment; Reporting.jl writes the
# plots and tables.

# Do not change the function names, arguments, or return types.
# Replace each placeholder error(...) with your implementation and return value.
# The yield table, yields, has one row per alcohol and one column per condition, in percent.
# A condition is one sulfonyl fluoride paired with one base; condition a is column a.
# The world is a function of the condition: world(a) runs one experiment with
# condition a and returns its reward, 1 for a success or 0 for a failure. The
# supplied code makes it from the yield table, as the L10d lab did with bernoulli_world:
#     world = a -> run_reaction(yields, a, rng);
# Draw every random number from rng, in the order each docstring gives, so that
# the same seed always gives the same game.

# ----------------------------------------------------------------------------
# Part 1a: The true success fraction of each condition
# ----------------------------------------------------------------------------

"""
    success_fractions(yields::Array{Float64,2}; cutoff::Float64 = 50.0) -> Array{Float64,1}

Compute the true success fraction θₐ of each condition: the fraction of alcohols on
which condition `a` gives a yield of at least `cutoff` percent.

Only we, who built the simulation, know these fractions. The agent never sees them; it
sees only the reward of each experiment. We use them to check what the agent learned
and to measure the successes it lost while learning.

### Arguments
- `yields::Array{Float64,2}`: the yield table, one row per alcohol and one column per
  condition, in percent.
- `cutoff::Float64 = 50.0`: the smallest yield, in percent, that counts as a success. A
  yield exactly at the cutoff counts as a success.

### Returns
A new `Array{Float64,1}` with one entry per condition (column): the number of alcohols
(rows) with a yield of at least `cutoff`, divided by the number of alcohols. Leave
`yields` unchanged.

### Errors
Throws an `ArgumentError` if `yields` has no rows or no columns.

### Example
```julia
screen = load_screen();
θ = success_fractions(screen.yields); # one fraction per condition
θ[19] # PBSF/BTMG gives at least 50% yield on 23 of the 37 alcohols: 23/37 ≈ 0.622
```
"""
function success_fractions(yields::Array{Float64,2}; cutoff::Float64 = 50.0)

    # TODO 1: Compute and return the success fraction of each condition.

    # Check the table -
    # The number of alcohols is size(yields, 1), the rows, and the number of
    # conditions is size(yields, 2), the columns. Throw an ArgumentError if either is 0.

    # Count the successes in each column -
    # Make θ = zeros(number of conditions). For each condition a, count the alcohols i
    # with yields[i, a] >= cutoff, and set θ[a] to that count divided by the number
    # of alcohols.

    # Return θ -

    error("Complete success_fractions in src/Compute.jl");
end


# ----------------------------------------------------------------------------
# Part 1b: Thompson sampling, one experiment at a time (the L10d Task 3 function)
# ----------------------------------------------------------------------------

"""
    my_thompson_sampling(world::Function, K::Int64, T::Int64; rng::AbstractRNG,
        α::Array{Float64,1} = ones(K), β::Array{Float64,1} = ones(K)) -> NamedTuple

Play a binary Bernoulli bandit with `K` arms for `T` rounds using Thompson sampling.
This is the function from Task 3 of the L10d lab.

Each arm (condition) succeeds (reward `1`) with a probability that the agent does not
know, and fails (reward `0`) otherwise. The agent describes what it believes about
the success probability of arm `a` with a Beta distribution:

- before any experiments, its belief (the prior) is `Beta(α[a], β[a])`;
- after `S[a]` successes and `F[a]` failures on arm `a`, its updated belief (the
  posterior) is `Beta(α[a] + S[a], β[a] + F[a])`.

In each round `t = 1, 2, ..., T`, carry out these four steps, drawing random numbers in
exactly this order:

1. Draw one sample `p[a]` from the posterior of every arm, for `a = 1, 2, ..., K` in
   order: `p[a] = rand(rng, Beta(α[a] + S[a], β[a] + F[a]))`.
2. Choose the arm `aₜ` with the largest sample, `aₜ = argmax(p)` (on a tie, `argmax`
   returns the first one).
3. Run the experiment by calling `world(aₜ)` once. It returns the reward `rₜ`, `1` or `0`.
4. Update the counts of arm `aₜ`: one more success if `rₜ = 1`, or one more failure if
   `rₜ = 0`.

An arm with few runs has a wide posterior, so its sample is sometimes the largest
even when its posterior mean is lower than another arm's. Then the arm is tried
again. This is how Thompson sampling explores.

### Arguments
- `world::Function`: the world. `world(a)` runs one experiment with arm `a` and
  returns its reward, `1` or `0`. The agent sees only these rewards.
- `K::Int64`: the number of arms, at least 1.
- `T::Int64`: the number of rounds, at least 1.
- `rng::AbstractRNG`: the random number generator for the samples from the
  posteriors. It has no default, so you must pass one. In PS5, the agent and the
  world share one generator, so a new generator made from the same seed repeats the
  whole game.
- `α::Array{Float64,1} = ones(K)`: the first prior parameter of each arm, each positive.
- `β::Array{Float64,1} = ones(K)`: the second prior parameter of each arm, each
  positive. The default, `α[a] = β[a] = 1`, is the uniform distribution on `[0, 1]`:
  before any experiments, every success probability is equally likely.

### Returns
A `NamedTuple` with four fields (read one with `result.S`, and so on):
- `actions::Array{Int64,1}`: the arm chosen in each round, `T` entries.
- `rewards::Array{Int64,1}`: the reward received in each round, `1` or `0`, `T` entries.
- `S::Array{Int64,1}`: the number of successes on each arm, `K` entries.
- `F::Array{Int64,1}`: the number of failures on each arm, `K` entries.

### Errors
Throws an `ArgumentError` if `K` or `T` is less than 1, if `α` or `β` does not have
`K` entries, if an entry of `α` or `β` is not positive, or if `world` returns a value
other than `0` or `1`.

### Example
```julia
screen = load_screen();
rng = MersenneTwister(5800); # one random number generator for the agent and the world
world = a -> run_reaction(screen.yields, a, rng); # the reward of one experiment with condition a
result = my_thompson_sampling(world, 20, 480; rng = rng);
result.S .+ result.F # the number of experiments with each condition
```
"""
function my_thompson_sampling(world::Function, K::Int64, T::Int64; rng::AbstractRNG,
    α::Array{Float64,1} = ones(K), β::Array{Float64,1} = ones(K))

    # TODO 2: Play T rounds of Thompson sampling and return (actions, rewards, S, F).

    # Check the arguments -
    # Throw an ArgumentError if K or T is less than 1, if α or β does not have K
    # entries, or if an entry of α or β is not positive.

    # Initialize -
    # Start the counts S and F at zero, one entry per arm, and make vectors to hold
    # the action and the reward of each round. zeros(Int64, n) makes n whole-number zeros.
    # Also make p = zeros(K) to hold one posterior sample per arm.

    # Play the rounds: for t in 1:T -
    # Step 1: for a in 1:K, set p[a] = rand(rng, Beta(α[a] + S[a], β[a] + F[a])).
    # Step 2: choose the arm with the largest sample, argmax(p).
    # Step 3: call world once with that arm to get the reward r; throw an
    #         ArgumentError if r is not 0 or 1; store the arm and r for round t.
    # Step 4: add r to S of that arm, and 1 - r to F of that arm.

    # Return the history and the counts -
    # return (actions = actions, rewards = rewards, S = S, F = F);

    error("Complete my_thompson_sampling in src/Compute.jl");
end


# ----------------------------------------------------------------------------
# Part 2a: Thompson sampling in blocks
# ----------------------------------------------------------------------------

"""
    plate_thompson_sampling(world::Function, K::Int64, plates::Int64, wells::Int64; rng::AbstractRNG,
        α::Array{Float64,1} = ones(K), β::Array{Float64,1} = ones(K)) -> NamedTuple

Play Thompson sampling in blocks: `plates` reaction blocks of `wells` experiments each,
`plates * wells` experiments in all. The arm of every well in a block is chosen before
any experiment in the block runs, and the counts update only after the whole block,
with all of its results.

For each block, draw random numbers and run the experiments in exactly this order:

1. Choose the arm of every well, for well `w = 1, 2, ..., wells` in order. For each
   well, draw one sample from the posterior of every arm, in arm order,
   `p[a] = rand(rng, Beta(α[a] + S[a], β[a] + F[a]))`, and choose `argmax(p)`. Every
   well uses the counts `S` and `F` from the start of the block. Each well gets its own
   samples, so two wells can get different arms.
2. Run the wells in well order: call `world` once for each well's arm.
3. Update the counts with every result of the block.

Do not call `world` until every well in the block has its arm: an earlier call
changes the order of the random numbers, and your results no longer match the tests.

With one well per block, this is the same game as `my_thompson_sampling`, with the
same random numbers in the same order.

### Arguments
- `world::Function`: the world. `world(a)` runs one experiment with arm `a` and
  returns its reward, `1` or `0`.
- `K::Int64`: the number of arms, at least 1.
- `plates::Int64`: the number of blocks, at least 1.
- `wells::Int64`: the number of experiments in each block, at least 1.
- `rng::AbstractRNG`: the random number generator for the samples from the posteriors.
- `α::Array{Float64,1} = ones(K)` and `β::Array{Float64,1} = ones(K)`: the prior
  parameters of each arm, each positive, as in `my_thompson_sampling`.

### Returns
A `NamedTuple` with the same four fields as `my_thompson_sampling`:
- `actions::Array{Int64,1}` and `rewards::Array{Int64,1}`: the arm and the reward of
  each experiment, `plates * wells` entries, block by block and, within a block, well
  by well.
- `S::Array{Int64,1}` and `F::Array{Int64,1}`: the number of successes and failures on
  each arm, `K` entries.

### Errors
Throws an `ArgumentError` if `K`, `plates`, or `wells` is less than 1, if `α` or `β`
does not have `K` entries, if an entry of `α` or `β` is not positive, or if `world`
returns a value other than `0` or `1`.

### Example
```julia
screen = load_screen();
rng = MersenneTwister(5800);
world = a -> run_reaction(screen.yields, a, rng);
result = plate_thompson_sampling(world, 20, 20, 24; rng = rng); # 20 blocks of 24 wells
```
"""
function plate_thompson_sampling(world::Function, K::Int64, plates::Int64, wells::Int64; rng::AbstractRNG,
    α::Array{Float64,1} = ones(K), β::Array{Float64,1} = ones(K))

    # TODO 3: Play the blocks and return (actions, rewards, S, F).

    # Check the arguments -
    # As in my_thompson_sampling, and also check that plates and wells are at least 1.

    # Initialize -
    # Start S and F at zero, and make vectors for the plates * wells actions and rewards.
    # Also make p = zeros(K) for the samples, and block_arms = zeros(Int64, wells) for
    # the arm of each well in the current block.

    # Play the blocks: for plate in 1:plates -
    # Step 1: for each well w in 1:wells, draw one sample per arm into p, as in Step 1
    #         of my_thompson_sampling, and set block_arms[w] = argmax(p). Do not change
    #         S or F here: every well uses the counts from the start of the block.
    # Step 2: only after every well has its arm, run the wells in well order: one
    #         world call per well. Throw an ArgumentError if a reward is not 0 or 1.
    #         Store each action and reward.
    #         The experiment of well w in block plate is number (plate - 1) * wells + w.
    # Step 3: update S and F with every result of the block.

    # Return the history and the counts -

    error("Complete plate_thompson_sampling in src/Compute.jl");
end


# ----------------------------------------------------------------------------
# Part 2b: The probability that each condition is the best
# ----------------------------------------------------------------------------

"""
    probability_best(S::Array{Int64,1}, F::Array{Int64,1}, N::Int64; rng::AbstractRNG,
        α::Array{Float64,1} = ones(length(S)), β::Array{Float64,1} = ones(length(S))) -> Array{Float64,1}

Estimate, for each arm, the probability that it is the best arm, given the counts. The
best arm is the one with the highest success probability. The estimate uses the
posteriors `Beta(α[a] + S[a], β[a] + F[a])`.

Repeat `N` rounds. In each round, draw one sample from the posterior of every arm, in
arm order, `rand(rng, Beta(α[a] + S[a], β[a] + F[a]))`, and give the round to the arm
with the largest sample (`argmax`, the first one on a tie). The probability that arm
`a` is the best is the number of rounds arm `a` won, divided by `N`.

### Arguments
- `S::Array{Int64,1}` and `F::Array{Int64,1}`: the number of successes and failures on
  each arm, each at least 0.
- `N::Int64`: the number of rounds, at least 1. More rounds give a more precise estimate.
- `rng::AbstractRNG`: the random number generator for the samples.
- `α` and `β`: the prior parameters of each arm, each positive, as in `my_thompson_sampling`.

### Returns
A new `Array{Float64,1}` with one entry per arm. Each entry is a multiple of `1/N`, and
the entries add up to 1. Leave `S` and `F` unchanged.

### Errors
Throws a `DimensionMismatch` if `S` and `F` have different lengths, and an
`ArgumentError` if `N` is less than 1, if a count is negative, or if `α` or `β` has the
wrong length or an entry that is not positive.

### Example
```julia
# result is a game from my_thompson_sampling or plate_thompson_sampling (see their examples)
p = probability_best(result.S, result.F, 10_000; rng = MersenneTwister(5800));
argmax(p) # the arm most likely to be the best: the company's pick
```
"""
function probability_best(S::Array{Int64,1}, F::Array{Int64,1}, N::Int64; rng::AbstractRNG,
    α::Array{Float64,1} = ones(length(S)), β::Array{Float64,1} = ones(length(S)))

    # TODO 4: Estimate and return the probability that each arm is the best.

    # Check the arguments -
    # Throw a DimensionMismatch if S and F have different lengths. Throw an
    # ArgumentError if N is less than 1, a count is negative, or α or β has the
    # wrong length or an entry that is not positive.

    # Count the wins: for each of the N rounds -
    # Make wins = zeros(Int64, K) before the loop, where K = length(S). In each round,
    # draw one sample from each arm's posterior, in arm order, as in
    # my_thompson_sampling, and add one win to the arm with the largest sample.

    # Divide the wins by N and return -
    # Make a vector of K zeros, and set entry a to wins[a] / N.

    error("Complete probability_best in src/Compute.jl");
end

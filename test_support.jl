# ----------------------------------------------------------------------------
# Supplied test support | Small inputs and stored results
# ----------------------------------------------------------------------------

"""Supplied test inputs and stored reference results for the PS5 student functions."""
module PS5Checks

using Random; # MersenneTwister for repeatable games

using ..FluorinationScreen; # implementation loaded by the current test suite

export throws_type, toy_table, toy_world, counting_world, fixed_world;
export count_runs, count_successes, all_between;
export TOY_GAME_ACTIONS, REAL_GAME_S, REAL_GAME_F;
export TOY_PLATE_ACTIONS, REAL_PLATE_S, REAL_PLATE_F, TOY_BEST;

# ----------------------------------------------------------------------------
# Stored results | Made once with the reference solution; a correct solution
# that draws its random numbers in the documented order reproduces them exactly.
# ----------------------------------------------------------------------------

# my_thompson_sampling(toy_world(toy_table(), rng), 3, 20; rng) with rng = MersenneTwister(1234) -
const TOY_GAME_ACTIONS = [3, 3, 3, 1, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 3, 3, 3, 3, 3, 3];

# my_thompson_sampling on the real table, 200 rounds, with rng = MersenneTwister(5800) -
const REAL_GAME_S = [1, 5, 0, 0, 0, 0, 2, 3, 0, 1, 27, 2, 2, 9, 0, 5, 1, 3, 19, 11];
const REAL_GAME_F = [4, 6, 3, 3, 3, 3, 4, 3, 3, 4, 15, 5, 4, 9, 3, 7, 4, 5, 13, 8];

# plate_thompson_sampling(toy_world(toy_table(), rng), 3, 5, 4; rng) with rng = MersenneTwister(1234) -
const TOY_PLATE_ACTIONS = [3, 3, 2, 1, 3, 3, 3, 3, 3, 1, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3];

# plate_thompson_sampling on the real table, 10 blocks of 24 wells, with rng = MersenneTwister(5800) -
const REAL_PLATE_S = [2, 3, 5, 5, 1, 1, 1, 0, 0, 9, 1, 25, 3, 2, 1, 2, 4, 9, 15, 12];
const REAL_PLATE_F = [5, 8, 5, 9, 5, 7, 5, 3, 3, 13, 5, 15, 6, 5, 4, 5, 7, 10, 10, 9];

# probability_best([3, 0], [1, 1], 1000; rng = MersenneTwister(1234)) -
const TOY_BEST = [0.857, 0.143];

# ----------------------------------------------------------------------------
# Test inputs
# ----------------------------------------------------------------------------

"""
    toy_table() -> Array{Float64,2}

Build a small yield table with 10 alcohols (rows) and 3 conditions (columns), in
percent. At the 50% cutoff, condition 1 succeeds on 7 alcohols, condition 2 on 5
(one of them at exactly 50%), and condition 3 on 9. At a 90% cutoff, the counts are
1, 1, and 3.
"""
function toy_table()
    yields = [
        80.0  50.0  99.0;
        75.0  95.0  98.0;
        60.0  52.0  92.0;
        55.0  88.0  85.0;
        90.0  61.0  77.0;
        70.0  49.0  66.0;
        65.0  10.0  58.0;
        20.0   0.0  54.0;
        30.0  35.0  51.0;
        10.0  40.0  12.0;
    ];
    return yields;
end

"""
    toy_world(yields::Array{Float64,2}, rng::AbstractRNG) -> Function

Return the world for a yield table: a function of the condition `a` that runs one
experiment with `run_reaction(yields, a, rng)` and returns its reward, 1 or 0.
"""
function toy_world(yields::Array{Float64,2}, rng::AbstractRNG)
    return a -> run_reaction(yields, a, rng);
end

"""
    record_call(counter::Array{Int64,1}, reward::Int64) -> Int64

Add one to `counter[1]` and return `reward`. Used by `counting_world`.
"""
function record_call(counter::Array{Int64,1}, reward::Int64)
    counter[1] = counter[1] + 1; # one more call to the world
    return reward;
end

"""
    counting_world(counter::Array{Int64,1}, reward::Int64) -> Function

Return a world that returns `reward` for every condition and counts its calls in
`counter[1]`. Make the counter with `counter = [0]`, a vector with one entry, so
the count can change inside the world and still be read after the game.
"""
function counting_world(counter::Array{Int64,1}, reward::Int64)
    return a -> record_call(counter, reward);
end

"""
    fixed_world(rewards::Array{Int64,1}) -> Function

Return a world with no randomness: condition `a` always returns `rewards[a]`.
"""
function fixed_world(rewards::Array{Int64,1})
    return a -> rewards[a];
end

"""
    count_runs(actions, K::Int64) -> Array{Int64,1}

Count the experiments run with each arm. Entry `a` of the result is the number of
entries of `actions` equal to `a`, for `a = 1, 2, ..., K`.
"""
function count_runs(actions, K::Int64)

    # Compare every action with every arm, and count the matches -
    runs = zeros(Int64, K);
    for t in 1:length(actions)
        for a in 1:K
            if actions[t] == a
                runs[a] = runs[a] + 1;
            end
        end
    end

    return runs;
end

"""
    count_successes(actions, rewards, K::Int64) -> Array{Int64,1}

Add up the rewards of each arm. Entry `a` of the result is the sum of `rewards[t]`
over the experiments `t` with `actions[t] == a`. Throws an `ErrorException` if
`actions` and `rewards` have different lengths.
"""
function count_successes(actions, rewards, K::Int64)

    # Check that there is one reward per action -
    if length(actions) != length(rewards)
        error("actions and rewards have different lengths");
    end

    # Add each reward to the arm that earned it -
    successes = zeros(Int64, K);
    for t in 1:length(actions)
        for a in 1:K
            if actions[t] == a
                successes[a] = successes[a] + rewards[t];
            end
        end
    end

    return successes;
end

"""
    all_between(values, low, high) -> Bool

Return `true` if every entry of `values` is at least `low` and at most `high`, and
`false` otherwise.
"""
function all_between(values, low, high)

    # Stop at the first entry outside the range; NaN is outside every range -
    for k in 1:length(values)
        if !(values[k] >= low && values[k] <= high)
            return false;
        end
    end

    return true;
end

"""
    throws_type(f, T) -> Bool

Call `f()` and return `true` if it throws an error of type `T`, and `false` if it
throws another type of error or finishes without one.
"""
function throws_type(f, T)

    # Run f; if it throws, report whether the error has the expected type -
    try
        f();
    catch e
        return e isa T;
    end

    # f finished without an error -
    return false;
end

end

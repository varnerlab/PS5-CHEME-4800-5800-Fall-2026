# ----------------------------------------------------------------------------
# Supplied simulator | Run one reaction by replaying the published screen.
# ----------------------------------------------------------------------------

"""
    run_reaction(yields::Array{Float64,2}, a::Int64, rng::AbstractRNG; cutoff::Float64 = 50.0) -> Int64

Run one experiment with condition `a` and return its reward: `1` for a success and
`0` for a failure. This function is the world: the agent sees only the reward.

The function stands in for the lab. It picks one alcohol (row of `yields`) at random,
as the next alcohol in the queue, and looks up the yield the published screen measured
for that alcohol under condition `a`. Any alcohol can come up again. The run is a
success if that yield is at least `cutoff` percent (`50.0` by default; a yield of
exactly 50% counts as a success).

### Arguments
- `yields::Array{Float64,2}`: the yield table, one row per alcohol and one column per
  condition, in percent (from `load_screen()`, or a table with some of its columns).
- `a::Int64`: the condition to run, from 1 to the number of columns of `yields`.
- `rng::AbstractRNG`: the random number generator that picks the alcohol. The function
  draws exactly one number from it, `rand(rng, 1:size(yields, 1))`.
- `cutoff::Float64 = 50.0`: the smallest yield, in percent, that counts as a success.

### Errors
Throws an `ArgumentError` if `a` is not a column of `yields`.

### Example
```julia
screen = load_screen();
rng = MersenneTwister(5800);
world = a -> run_reaction(screen.yields, a, rng); # the world for the bandit functions
reward = world(19); # run PBSF/BTMG on one alcohol from the queue
```
"""
function run_reaction(yields::Array{Float64,2}, a::Int64, rng::AbstractRNG; cutoff::Float64 = 50.0)::Int64

    # Check the condition -
    if a < 1 || a > size(yields, 2)
        throw(ArgumentError("condition $a is not a column of the yield table (1 to $(size(yields, 2)))"));
    end

    # Pick the next alcohol in the queue at random; any alcohol can come up again -
    i = rand(rng, 1:size(yields, 1));

    # A success if the measured yield reaches the cutoff -
    if yields[i, a] >= cutoff
        return 1;
    else
        return 0;
    end
end

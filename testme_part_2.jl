# Run: julia --startup-file=no --project=. testme_part_2.jl
# The flag --solution is for the instructor: it tests solution/src/Compute.jl instead of yours.
# Each labeled case checks one requirement of plate_thompson_sampling or probability_best.
# No case calls a Part 1 function.


# ----------------------------------------------------------------------------
# Setup | Load your functions and the test helpers
# ----------------------------------------------------------------------------

using Test;   # record one scored assertion per labeled case
using Random; # MersenneTwister for repeatable games

# Load the code into this script's module; the checker runs each test script in its own module -
Base.include(@__MODULE__, joinpath(@__DIR__, "Include.jl"));
Base.include(@__MODULE__, joinpath(@__DIR__, "test_support.jl"));

using .PS5Checks; # small inputs and stored results

# Each case counts as one test, even when your function throws an error in it.
toy = toy_table();
screen = load_screen();

# ----------------------------------------------------------------------------
# Test cases | One scored assertion per labeled case
# ----------------------------------------------------------------------------

checks = [
    # Thompson sampling in blocks -
    "result fields and lengths" => () -> begin
        rng = MersenneTwister(1);
        result = plate_thompson_sampling(toy_world(toy, rng), 3, 6, 4; rng = rng);

        result.actions isa Array{Int64,1} && result.rewards isa Array{Int64,1} &&
            result.S isa Array{Int64,1} && result.F isa Array{Int64,1} &&
            length(result.actions) == 24 && length(result.rewards) == 24 &&
            length(result.S) == 3 && length(result.F) == 3
    end,

    "counts add up" => () -> begin
        rng = MersenneTwister(2);
        result = plate_thompson_sampling(toy_world(toy, rng), 3, 10, 7; rng = rng);

        sum(result.S) + sum(result.F) == 70
    end,

    "pulls and successes match the actions and rewards" => () -> begin
        rng = MersenneTwister(3);
        result = plate_thompson_sampling(toy_world(toy, rng), 3, 10, 7; rng = rng);

        result.S + result.F == count_runs(result.actions, 3) &&
            result.S == count_successes(result.actions, result.rewards, 3)
    end,

    "one well per block is ordinary Thompson sampling" => () -> begin
        rng = MersenneTwister(1234);
        result = plate_thompson_sampling(toy_world(toy, rng), 3, 20, 1; rng = rng);

        result.actions == TOY_GAME_ACTIONS
    end,

    "exact block game on the toy table" => () -> begin
        rng = MersenneTwister(1234);
        result = plate_thompson_sampling(toy_world(toy, rng), 3, 5, 4; rng = rng);

        result.actions == TOY_PLATE_ACTIONS
    end,

    "exact counts on the real table" => () -> begin
        # This longer game also fails if world is called before every well in a block has its arm.
        rng = MersenneTwister(5800);
        result = plate_thompson_sampling(toy_world(screen.yields, rng), 20, 10, 24; rng = rng);

        result.S == REAL_PLATE_S && result.F == REAL_PLATE_F
    end,

    "one block draws every well from the prior" => () -> begin
        # Every experiment succeeds. If the counts changed inside the block, the first
        # condition to succeed would take most of the wells.
        result = plate_thompson_sampling(counting_world([0], 1), 3, 1, 300; rng = MersenneTwister(9));
        wells_per_condition = count_runs(result.actions, 3);

        all_between(wells_per_condition, 70, 130)
    end,

    "counts update after each block" => () -> begin
        # Condition 1 always succeeds; conditions 2 and 3 always fail -
        result = plate_thompson_sampling(fixed_world([1, 0, 0]), 3, 20, 10; rng = MersenneTwister(10));
        last_block = result.actions[191:200];
        runs = count_runs(last_block, 3);

        runs[1] >= 8
    end,

    "same seed gives the same game" => () -> begin
        rng = MersenneTwister(5800);
        first_game = plate_thompson_sampling(toy_world(screen.yields, rng), 20, 5, 24; rng = rng);
        rng = MersenneTwister(5800);
        second_game = plate_thompson_sampling(toy_world(screen.yields, rng), 20, 5, 24; rng = rng);

        first_game.actions == second_game.actions
    end,

    "world called once per well" => () -> begin
        counter = [0]; # counting_world adds 1 to counter[1] at every call
        plate_thompson_sampling(counting_world(counter, 0), 3, 6, 5; rng = MersenneTwister(11));

        counter[1] == 30
    end,

    "prior keywords are used" => () -> begin
        rng = MersenneTwister(12);
        α = [1.0, 1000.0, 1.0]; # a strong belief that condition 2 almost always works
        β = [1000.0, 1.0, 1000.0];
        result = plate_thompson_sampling(toy_world(toy, rng), 3, 5, 10; rng = rng, α = α, β = β);
        runs = count_runs(result.actions, 3);

        runs[2] == length(result.actions) # every experiment used condition 2
    end,

    "K, plates, or wells below 1 rejected" => () ->
        throws_type(() -> plate_thompson_sampling(counting_world([0], 1), 0, 2, 2; rng = MersenneTwister(1)), ArgumentError) &&
        throws_type(() -> plate_thompson_sampling(counting_world([0], 1), 3, 0, 2; rng = MersenneTwister(1)), ArgumentError) &&
        throws_type(() -> plate_thompson_sampling(counting_world([0], 1), 3, 2, 0; rng = MersenneTwister(1)), ArgumentError),

    "bad prior rejected" => () ->
        throws_type(() -> plate_thompson_sampling(counting_world([0], 1), 3, 2, 2; rng = MersenneTwister(1),
            α = ones(4)), ArgumentError) &&
        throws_type(() -> plate_thompson_sampling(counting_world([0], 1), 3, 2, 2; rng = MersenneTwister(1),
            β = [1.0, -1.0, 1.0]), ArgumentError),

    "reward other than 0 or 1 rejected" => () ->
        throws_type(() -> plate_thompson_sampling(counting_world([0], -1), 3, 2, 2; rng = MersenneTwister(1)), ArgumentError),

    # The probability that each condition is the best -
    "probabilities type and length" => () -> begin
        p = probability_best([3, 1, 0], [1, 1, 2], 500; rng = MersenneTwister(13));

        p isa Array{Float64,1} && length(p) == 3
    end,

    "probabilities sum to one" => () -> begin
        p = probability_best([3, 1, 0, 7], [1, 1, 2, 9], 999; rng = MersenneTwister(14));

        abs(sum(p) - 1.0) < 1e-12
    end,

    "multiples of 1/N" => () -> begin
        N = 777;
        p = probability_best([3, 1, 0], [1, 1, 2], N; rng = MersenneTwister(15));
        wins = p * N; # the number of rounds each condition won
        whole_numbers = true;
        for a in 1:length(wins)
            if !(abs(wins[a] - round(wins[a])) < 1e-9)
                whole_numbers = false;
            end
        end

        whole_numbers
    end,

    "exact result" => () ->
        isapprox(probability_best([3, 0], [1, 1], 1000; rng = MersenneTwister(1234)), TOY_BEST; atol = 1e-12),

    "clear winner" => () ->
        isapprox(probability_best([500, 10], [10, 500], 1000; rng = MersenneTwister(16)), [1.0, 0.0]; atol = 1e-12),

    "equal counts give equal shares" => () -> begin
        p = probability_best([5, 5, 5, 5], [5, 5, 5, 5], 20_000; rng = MersenneTwister(17));
        equal_shares = true;
        for a in 1:length(p)
            if !(abs(p[a] - 0.25) < 0.02)
                equal_shares = false;
            end
        end

        equal_shares
    end,

    "same seed gives the same result" => () ->
        probability_best([4, 6, 2], [3, 5, 1], 2000; rng = MersenneTwister(18)) ==
        probability_best([4, 6, 2], [3, 5, 1], 2000; rng = MersenneTwister(18)),

    "prior keywords are used" => () ->
        isapprox(probability_best([0, 0], [0, 0], 500; rng = MersenneTwister(19), α = [1000.0, 1.0], β = [1.0, 1000.0]),
            [1.0, 0.0]; atol = 1e-12),

    "counts unchanged" => () -> begin
        S = [3, 1, 0];
        F = [1, 1, 2];
        probability_best(S, F, 100; rng = MersenneTwister(20));

        S == [3, 1, 0] && F == [1, 1, 2]
    end,

    "bad inputs rejected" => () ->
        throws_type(() -> probability_best([1, 2], [1, 2, 3], 10; rng = MersenneTwister(1)), DimensionMismatch) &&
        throws_type(() -> probability_best([1, 2], [1, 2], 0; rng = MersenneTwister(1)), ArgumentError) &&
        throws_type(() -> probability_best([1, -2], [1, 2], 10; rng = MersenneTwister(1)), ArgumentError),
];


# ----------------------------------------------------------------------------
# Run the 24 scored checks
# ----------------------------------------------------------------------------

@testset "PS5 Part 2 (24 tests)" begin
    for (label, check) in checks # each entry is label => check; check() is true when the case passes
        @testset "$label" begin
            @test check();
        end
    end
end;

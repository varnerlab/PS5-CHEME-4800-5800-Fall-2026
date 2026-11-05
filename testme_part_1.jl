# Run: julia --startup-file=no --project=. testme_part_1.jl
# Add --solution to test solution/src/Compute.jl without replacing student code.
# Each labeled case checks one requirement of success_fractions or my_thompson_sampling.


# ----------------------------------------------------------------------------
# Setup | Load the selected implementation and test helpers
# ----------------------------------------------------------------------------

using Test;   # record one scored assertion per labeled case
using Random; # MersenneTwister for repeatable games

Base.include(@__MODULE__, joinpath(@__DIR__, "Include.jl"));
Base.include(@__MODULE__, joinpath(@__DIR__, "test_support.jl"));

using .PS5Checks; # small inputs and stored results

# Each case contributes one scored test, including cases whose implementation raises an error.
toy = toy_table();
screen = load_screen();

# ----------------------------------------------------------------------------
# Test cases | One scored assertion per labeled case
# ----------------------------------------------------------------------------

checks = [
    # The true success fraction of each condition -
    "fractions type and length" => () -> begin
        θ = success_fractions(toy);

        θ isa Array{Float64,1} && length(θ) == 3
    end,

    "toy fractions" => () ->
        isapprox(success_fractions(toy), [0.7, 0.5, 0.9]; atol = 1e-12),

    "cutoff is inclusive" => () ->
        success_fractions(reshape([50.0], 1, 1)) == [1.0] && success_fractions(reshape([49.9], 1, 1)) == [0.0],

    "cutoff keyword is used" => () ->
        isapprox(success_fractions(toy; cutoff = 90.0), [0.1, 0.1, 0.3]; atol = 1e-12),

    "real data" => () -> begin
        θ = success_fractions(screen.yields);
        counts = round.(Int, 37 .* θ); # alcohols at or above 50% for each condition

        counts == [4, 11, 11, 12, 8, 12, 12, 12, 8, 14, 15, 18, 9, 14, 17, 14, 16, 20, 23, 22]
    end,

    "fractions between 0 and 1" => () -> begin
        θ = success_fractions(screen.yields; cutoff = 30.0);

        length(θ) == 20 && all(0.0 .<= θ .<= 1.0)
    end,

    "table unchanged" => () -> begin
        yields = copy(toy);
        success_fractions(yields);

        yields == toy
    end,

    "empty table rejected" => () ->
        throws_type(() -> success_fractions(zeros(0, 3)), ArgumentError) &&
        throws_type(() -> success_fractions(zeros(3, 0)), ArgumentError),

    # Thompson sampling, one experiment at a time -
    "result fields and types" => () -> begin
        rng = MersenneTwister(1);
        result = my_thompson_sampling(toy_world(toy, rng), 3, 50; rng = rng);

        result.actions isa Array{Int64,1} && result.rewards isa Array{Int64,1} &&
            result.S isa Array{Int64,1} && result.F isa Array{Int64,1} &&
            length(result.actions) == 50 && length(result.rewards) == 50 &&
            length(result.S) == 3 && length(result.F) == 3
    end,

    "one success or failure per round" => () -> begin
        rng = MersenneTwister(2);
        result = my_thompson_sampling(toy_world(toy, rng), 3, 200; rng = rng);

        sum(result.S) + sum(result.F) == 200
    end,

    "pulls match the actions" => () -> begin
        rng = MersenneTwister(3);
        result = my_thompson_sampling(toy_world(toy, rng), 3, 200; rng = rng);

        result.S .+ result.F == [count(result.actions .== a) for a in 1:3]
    end,

    "successes match the rewards" => () -> begin
        rng = MersenneTwister(4);
        result = my_thompson_sampling(toy_world(toy, rng), 3, 200; rng = rng);

        result.S == [sum(result.rewards[result.actions .== a]) for a in 1:3]
    end,

    "rewards are 0 or 1" => () -> begin
        rng = MersenneTwister(5);
        result = my_thompson_sampling(toy_world(toy, rng), 3, 200; rng = rng);

        all((result.rewards .== 0) .| (result.rewards .== 1))
    end,

    "same seed gives the same game" => () -> begin
        rng = MersenneTwister(5800);
        first_game = my_thompson_sampling(toy_world(screen.yields, rng), 20, 300; rng = rng);
        rng = MersenneTwister(5800);
        second_game = my_thompson_sampling(toy_world(screen.yields, rng), 20, 300; rng = rng);

        first_game.actions == second_game.actions
    end,

    "exact game on the toy table" => () -> begin
        rng = MersenneTwister(1234);
        result = my_thompson_sampling(toy_world(toy, rng), 3, 20; rng = rng);

        result.actions == TOY_GAME_ACTIONS
    end,

    "exact counts on the real table" => () -> begin
        rng = MersenneTwister(5800);
        result = my_thompson_sampling(toy_world(screen.yields, rng), 20, 200; rng = rng);

        result.S == REAL_GAME_S && result.F == REAL_GAME_F
    end,

    "learns the best toy condition" => () -> begin
        rng = MersenneTwister(1234);
        result = my_thompson_sampling(toy_world(toy, rng), 3, 2000; rng = rng);
        posterior_mean = (1 + result.S[3]) / (2 + result.S[3] + result.F[3]);

        count(result.actions .== 3) > 1000 && abs(posterior_mean - 0.9) < 0.05
    end,

    "one condition only" => () -> begin
        rng = MersenneTwister(6);
        result = my_thompson_sampling(toy_world(toy[:, 1:1], rng), 1, 30; rng = rng);

        result.actions == ones(Int64, 30)
    end,

    "prior keywords are used" => () -> begin
        rng = MersenneTwister(7);
        α = [1.0, 1000.0, 1.0]; # a strong belief that condition 2 almost always works
        β = [1000.0, 1.0, 1000.0];
        result = my_thompson_sampling(toy_world(toy, rng), 3, 50; rng = rng, α = α, β = β);

        all(result.actions .== 2)
    end,

    "world called once per round" => () -> begin
        counter = Ref(0);
        my_thompson_sampling(counting_world(counter, 1), 3, 40; rng = MersenneTwister(8));

        counter[] == 40
    end,

    "K or T below 1 rejected" => () ->
        throws_type(() -> my_thompson_sampling(counting_world(Ref(0), 1), 0, 10; rng = MersenneTwister(1)), ArgumentError) &&
        throws_type(() -> my_thompson_sampling(counting_world(Ref(0), 1), 3, 0; rng = MersenneTwister(1)), ArgumentError),

    "wrong-length prior rejected" => () ->
        throws_type(() -> my_thompson_sampling(counting_world(Ref(0), 1), 3, 10; rng = MersenneTwister(1),
            α = ones(2)), ArgumentError),

    "nonpositive prior rejected" => () ->
        throws_type(() -> my_thompson_sampling(counting_world(Ref(0), 1), 3, 10; rng = MersenneTwister(1),
            β = [1.0, 0.0, 1.0]), ArgumentError),

    "reward other than 0 or 1 rejected" => () ->
        throws_type(() -> my_thompson_sampling(counting_world(Ref(0), 2), 3, 10; rng = MersenneTwister(1)), ArgumentError),
];


# ----------------------------------------------------------------------------
# Run the 24 scored checks
# ----------------------------------------------------------------------------

@testset "PS5 Part 1 (24 tests)" begin
    for (label, check) in checks
        @testset "$label" begin
            @test check();
        end
    end
end;

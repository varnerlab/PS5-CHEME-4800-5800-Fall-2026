# Supplied loader and simulator checks, separate from the 48 scored student tests.
# Run: julia --startup-file=no --project=. instructor/test_supplied.jl [--solution]
# With --solution, also compare the reference Thompson sampling with the L10d lab solution.
using Test;   # loader and simulator assertions
using Random; # MersenneTwister for repeatable draws
include(joinpath(@__DIR__, "..", "Include.jl"));
include(joinpath(@__DIR__, "..", "test_support.jl"));
using .PS5Checks; # toy table, toy world, and stored results

using Distributions; # Bernoulli, for the lab's world

# The L10d reference solution, loaded into its own module -
const LAB_THOMPSON = joinpath(@__DIR__, "..", "..", "CHEME-5800-CourseRepository-Fall-2026", "weeks", "week-10",
    "L10d", "src", "Compute-solution.jl");
has_lab = isfile(LAB_THOMPSON);
has_lab || @warn "Course repository not found next to PS5; skipping the comparisons with the L10d lab.";
module LabThompson end
if has_lab
    Base.include(LabThompson, LAB_THOMPSON);
end

"""
    lab_bernoulli_world(a, θ, rng) -> Int64

The body of the L10d `bernoulli_world` (its `Utility.jl` needs the course package, which
PS5 does not install): return 1 with probability `θ[a]` and 0 otherwise.
"""
function lab_bernoulli_world(a::Int64, θ::Array{Float64,1}, rng::AbstractRNG)::Int64
    success = rand(rng, Bernoulli(θ[a]));
    if success == true
        return 1;
    else
        return 0;
    end
end

# Successes (yield of at least 50%) per condition, in column order, from the published table -
const EXPECTED_COUNTS = [4, 11, 11, 12, 8, 12, 12, 12, 8, 14, 15, 18, 9, 14, 17, 14, 16, 20, 23, 22];

"""
    load_error_message(folder) -> String

Call `load_screen(folder)` and return the text of the error it throws, or `""` if it
loads without an error.
"""
function load_error_message(folder)
    message = "";
    try
        load_screen(folder);
    catch caught
        message = sprint(showerror, caught);
    end
    return message;
end

"""
    copy_data() -> String

Copy the shipped data folder to a new temporary folder and return its path.
"""
function copy_data()
    folder = mktempdir();
    for name in readdir(joinpath(@__DIR__, "..", "data"))
        cp(joinpath(@__DIR__, "..", "data", name), joinpath(folder, name));
    end
    return folder;
end

@testset "Supplied loader and simulator" begin
    screen = load_screen();

    # Loader: shape, names, and column order -
    @test size(screen.yields) == (37, 20);
    @test screen.yields isa Array{Float64,2};
    @test length(screen.conditions) == 20 && length(screen.alcohols) == 37 && length(screen.smiles) == 37;
    @test screen.conditions[1] == "3-Cl/DBU" && screen.conditions[2] == "3-Cl/MTBD";
    @test screen.conditions[17] == "PBSF/DBU" && screen.conditions[19] == "PBSF/BTMG" && screen.conditions[20] == "PBSF/BTPP";
    @test screen.sulfonyl_fluorides[19] == "PBSF" && screen.bases[19] == "BTMG";
    @test screen.alcohols[1] == "s1" && screen.alcohols[37] == "s37";
    @test screen.smiles[1] == "OCCCCC1=CC=CC=C1";

    # Loader: values match the CSV (s1 with PyFluor and DBU gave 48%) -
    @test screen.yields[1, 5] == 48.0 && screen.conditions[5] == "PyFluor/DBU";
    @test screen.yields[1, 1] == 42.0 && screen.yields[1, 2] == 76.0;
    @test all(0.0 .<= screen.yields .<= 106.0) && maximum(screen.yields) == 106.0;

    # Loader: successes per condition match the published table -
    counts = zeros(Int64, 20);
    for a in 1:20
        for i in 1:37
            if screen.yields[i, a] >= 50.0
                counts[a] = counts[a] + 1;
            end
        end
    end
    @test counts == EXPECTED_COUNTS;

    # Loader: a file saved with Windows line endings loads to the same table -
    folder = copy_data();
    path = joinpath(folder, "deoxyfluorination.csv");
    write(path, replace(read(path, String), "\n" => "\r\n"));
    @test load_screen(folder).yields == screen.yields;

    # Loader: a cut-short file gives a clear error naming the file and the row count -
    folder = copy_data();
    path = joinpath(folder, "deoxyfluorination.csv");
    lines = split(read(path, String), "\n"; keepempty=false);
    write(path, join(lines[1:end-1], "\n") * "\n");
    message = load_error_message(folder);
    @test occursin("deoxyfluorination.csv", message) && occursin("740", message);

    # Loader: a missing file gives a clear error naming the file -
    folder = copy_data();
    rm(joinpath(folder, "deoxyfluorination.csv"));
    @test occursin("deoxyfluorination.csv", load_error_message(folder));

    # Simulator: exactly one draw, rand(rng, 1:37), then the cutoff -
    for a in (1, 5, 19, 20)
        rng = MersenneTwister(7);
        reward = run_reaction(screen.yields, a, rng);
        twin = MersenneTwister(7);
        i = rand(twin, 1:37);
        expected = 0;
        if screen.yields[i, a] >= 50.0
            expected = 1;
        end
        @test reward == expected && reward isa Int64;
        @test rand(rng) == rand(twin); # both generators are at the same point
    end

    # Simulator: the cutoff is inclusive and can be changed -
    rng = MersenneTwister(1);
    @test run_reaction(reshape([50.0], 1, 1), 1, rng) == 1;
    @test run_reaction(reshape([49.0], 1, 1), 1, rng) == 0;
    @test run_reaction(reshape([60.0], 1, 1), 1, rng; cutoff = 70.0) == 0;

    # Simulator: a condition outside the table is rejected -
    @test_throws ArgumentError run_reaction(screen.yields, 0, rng);
    @test_throws ArgumentError run_reaction(screen.yields, 21, rng);

    # Simulator: over many draws, each condition succeeds at its published rate -
    rng = MersenneTwister(2026);
    successes = 0;
    for k in 1:20_000
        successes = successes + run_reaction(screen.yields, 19, rng);
    end
    @test abs(successes / 20_000 - 23 / 37) < 0.01;

    # Reference Thompson sampling: the same games as the L10d lab solution -
    if has_lab
        toy = toy_table();
        rng = MersenneTwister(1234);
        lab_game = LabThompson.L10dThompson.my_thompson_sampling(toy_world(toy, rng), 3, 20; rng = rng);
        @test lab_game.actions == TOY_GAME_ACTIONS;
    end
    if has_lab && "--solution" in ARGS # needs the reference solution, absent from the student archive
        θ = [0.70, 0.50, 0.90];
        rng = MersenneTwister(5800);
        lab_game = LabThompson.L10dThompson.my_thompson_sampling(a -> lab_bernoulli_world(a, θ, rng), 3, 500; rng = rng);
        rng = MersenneTwister(5800);
        reference_game = my_thompson_sampling(a -> lab_bernoulli_world(a, θ, rng), 3, 500; rng = rng);
        @test reference_game.actions == lab_game.actions && reference_game.S == lab_game.S;
    end
end

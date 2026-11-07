# ----------------------------------------------------------------------------
# Supplied reports | Run the screens and write the plots and tables.
# ----------------------------------------------------------------------------

"""Supplied plots and tables for the PS5 deoxyfluorination screens."""
module ScreenReports

using Distributions # Beta, for the posterior curves
using Plots         # posterior curves
using Printf        # tables with a fixed number of decimals
using Random        # MersenneTwister, one generator per screen

# Settings used for every report -
const CUTOFF = 50.0;          # a yield of at least 50% is a success
const SEED = 5825;            # seed of the main screen and of the PBSF-free screen
const BLOCKS = 20;            # reaction blocks in the main screen
const WELLS = 24;             # wells (experiments) per reaction block
const EXPERIMENTS = 480;      # experiments in every screen: 20 blocks of 24
const DAYS_PER_BLOCK = 2;     # each block takes 48 h
const BLOCK_SIZES = [1, 6, 24, 96, 480]; # wells per block compared in plate-sizes.csv
const SCREEN_SEEDS = 1:100;   # one screen per seed for each block size
const DRAWS_SUMMARY = 10_000; # rounds of probability_best for a single screen
const DRAWS_AVERAGE = 2_000;  # rounds of probability_best for each of the 100 screens
const PBSF_FREE = 1:16;       # columns of the 16 conditions without PBSF

# Every file write_outputs creates; the checker clears exactly these before a run -
const REPORT_FILES = ["conditions.csv", "screen-summary.csv", "posteriors.png",
    "plate-sizes.csv", "pbsf-ban.csv"];

"""
    write_outputs(assignment, directory) -> NamedTuple

Run the screens with the student's functions and write every report.

### Arguments
- `assignment`: the loaded `FluorinationScreen` module, including the student's four
  completed functions.
- `directory::String`: the output folder; it is created if needed.

### Returns
The named tuple `(pick, pick_probability, pbsf_free_pick)`: the name of the main
screen's pick, its probability of being best, and the name of the PBSF-free screen's
pick. The function also writes or overwrites the five files in `REPORT_FILES` and
prints its progress and a summary.

### Errors
Throws an `ErrorException` if a student function returns results of the wrong size.
Errors from the student functions, file writing, or plotting are passed on.
"""
function write_outputs(assignment, directory)

    # Call each student function once on a tiny input, so an unfinished one stops here -
    tiny = reshape([60.0, 40.0], 2, 1); # a 2 × 1 yield table: two alcohols, one condition
    assignment.success_fractions(tiny);
    tiny_rng = MersenneTwister(1);
    tiny_world = a -> assignment.run_reaction(tiny, a, tiny_rng);
    assignment.my_thompson_sampling(tiny_world, 1, 2; rng = tiny_rng);
    assignment.plate_thompson_sampling(tiny_world, 1, 1, 2; rng = tiny_rng);
    assignment.probability_best([1], [1], 2; rng = tiny_rng);

    # Load the table and the true success fraction of each condition -
    mkpath(directory);
    screen = assignment.load_screen();
    yields = screen.yields;
    K = size(yields, 2);
    θ = assignment.success_fractions(yields; cutoff = CUTOFF);
    check_length(θ, K, "success_fractions");
    write_conditions(directory, screen, θ);

    # The main screen: 20 blocks of 24 wells, all 20 conditions -
    println("Main screen: $BLOCKS blocks of $WELLS wells, all $K conditions.");
    rng = MersenneTwister(SEED);
    world = a -> assignment.run_reaction(yields, a, rng; cutoff = CUTOFF);
    game = assignment.plate_thompson_sampling(world, K, BLOCKS, WELLS; rng = rng);
    check_game(game, K, EXPERIMENTS, "plate_thompson_sampling");

    # The probability that each condition is the best; the pick is the most likely one -
    best = assignment.probability_best(game.S, game.F, DRAWS_SUMMARY; rng = rng);
    check_length(best, K, "probability_best");
    write_summary(directory, screen, θ, game, best);
    write_posteriors(directory, screen, θ, game);
    pick = argmax(best);

    # Screens of 480 experiments with each block size, averaged over 100 screens -
    write_plate_sizes(directory, assignment, yields, θ);

    # The PBSF ban: what the main screen says about the 16 PBSF-free conditions, and a new screen -
    pbsf_free = collect(PBSF_FREE); # the column numbers 1 to 16, as a vector

    # Check that none of these columns uses PBSF -
    for a in pbsf_free
        if screen.sulfonyl_fluorides[a] == "PBSF"
            error("Column $a of the table uses PBSF; the PBSF-free columns are 1 to 16.");
        end
    end

    # What the company learned from the main screen: the probability of being best among the PBSF-free conditions only -
    first_best = assignment.probability_best(game.S[pbsf_free], game.F[pbsf_free], DRAWS_SUMMARY;
        rng = MersenneTwister(SEED + 1));

    # A new screen of 480 experiments with the 16 PBSF-free conditions -
    println("PBSF-free screen: $BLOCKS blocks of $WELLS wells, $(length(pbsf_free)) conditions.");
    yields_free = yields[:, pbsf_free]; # the table without the PBSF columns
    rng_free = MersenneTwister(SEED);
    world_free = a -> assignment.run_reaction(yields_free, a, rng_free; cutoff = CUTOFF);
    game_free = assignment.plate_thompson_sampling(world_free, length(pbsf_free), BLOCKS, WELLS; rng = rng_free);
    check_game(game_free, length(pbsf_free), EXPERIMENTS, "plate_thompson_sampling");
    best_free = assignment.probability_best(game_free.S, game_free.F, DRAWS_SUMMARY; rng = rng_free);
    write_ban(directory, screen, θ, pbsf_free, game, first_best, game_free, best_free);
    pick_free = pbsf_free[argmax(best_free)];

    # Print the summary -
    n = size(yields, 1); # the number of alcohols
    best_all = argmax(θ); # the column of the best condition
    best_ban = pbsf_free[argmax(θ[pbsf_free])]; # the column of the best PBSF-free condition
    println();
    @printf("Main screen pick: %s, probability of being best %.3f, %d experiments, at least 50%% yield on %d of %d alcohols.\n",
        screen.conditions[pick], best[pick], game.S[pick] + game.F[pick], round(Int, θ[pick] * n), n);
    @printf("PBSF-free screen pick: %s, at least 50%% yield on %d of %d alcohols.\n",
        screen.conditions[pick_free], round(Int, θ[pick_free] * n), n);
    @printf("Best condition: %s (%d of %d). Best PBSF-free condition: %s (%d of %d).\n",
        screen.conditions[best_all], round(Int, θ[best_all] * n), n,
        screen.conditions[best_ban], round(Int, θ[best_ban] * n), n);
    @printf("Cost of the ban with the best PBSF-free condition: %.1f extra failed runs per 100 alcohols.\n",
        100 * (θ[best_all] - θ[best_ban]));
    println("Reports written to ", directory);

    return (pick = screen.conditions[pick], pick_probability = best[pick],
        pbsf_free_pick = screen.conditions[pick_free]);
end


"""
    check_length(v, n, name)

Throw an `ErrorException` naming the student function `name` unless `v` is a vector
with `n` entries.

### Arguments
- `v`: the result to check.
- `n::Int64`: the number of entries `v` must have.
- `name::String`: the name of the student function that returned `v`, for the message.
"""
function check_length(v, n, name)
    if !(v isa AbstractVector) || length(v) != n
        error("$name returned a result with the wrong size; expected a vector with $n entries.");
    end
end


"""
    check_game(game, K, T, name)

Throw an `ErrorException` naming the student function `name` unless `game` has the
fields `actions`, `rewards`, `S`, and `F` with `T`, `T`, `K`, and `K` entries.

### Arguments
- `game`: the named tuple returned by `my_thompson_sampling` or `plate_thompson_sampling`.
- `K::Int64`: the number of conditions.
- `T::Int64`: the number of experiments.
- `name::String`: the name of the student function, for the message.
"""
function check_game(game, K, T, name)

    # Check that each field is there (:actions is the name of the field actions) -
    for field in (:actions, :rewards, :S, :F)
        if !hasproperty(game, field)
            error("$name returned a result without the field $field.");
        end
    end

    # Check the length of each field -
    check_length(game.actions, T, name);
    check_length(game.rewards, T, name);
    check_length(game.S, K, name);
    check_length(game.F, K, name);
end


"""
    write_conditions(directory, screen, θ)

Write `conditions.csv`: each condition, its reagents, the number of alcohols that the
condition fluorinates with a yield of at least the cutoff, and its true success
fraction.

### Arguments
- `directory::String`: the output folder.
- `screen::NamedTuple`: the paper's data, from `load_screen()`.
- `θ::Array{Float64,1}`: the true success fraction of each condition.
"""
function write_conditions(directory, screen, θ)
    n = size(screen.yields, 1); # the number of alcohols

    # Write one header line, then one line per condition -
    io = open(joinpath(directory, "conditions.csv"), "w");
    println(io, "condition,sulfonyl_fluoride,base,alcohols_at_or_above_cutoff,alcohols,true_success_fraction");
    for a in 1:length(θ)
        @printf(io, "%s,%s,%s,%d,%d,%.4f\n", screen.conditions[a], screen.sulfonyl_fluorides[a],
            screen.bases[a], round(Int, θ[a] * n), n, θ[a]);
    end
    close(io);
end


"""
    write_summary(directory, screen, θ, game, best)

Write `screen-summary.csv` for the main screen: for each condition, the experiments,
successes, failures, posterior mean, probability of being best, and true success
fraction.

### Arguments
- `directory::String`: the output folder.
- `screen::NamedTuple`: the paper's data, from `load_screen()`.
- `θ::Array{Float64,1}`: the true success fraction of each condition.
- `game::NamedTuple`: the main screen, from `plate_thompson_sampling`.
- `best::Array{Float64,1}`: the probability that each condition is the best.
"""
function write_summary(directory, screen, θ, game, best)

    # Write one header line, then one line per condition -
    io = open(joinpath(directory, "screen-summary.csv"), "w");
    println(io, "condition,sulfonyl_fluoride,base,experiments,successes,failures,posterior_mean,probability_best,true_success_fraction");
    for a in 1:length(θ)
        S = game.S[a];
        F = game.F[a];
        posterior_mean = (1 + S) / (2 + S + F); # the mean of Beta(1 + S, 1 + F)
        @printf(io, "%s,%s,%s,%d,%d,%d,%.4f,%.4f,%.4f\n", screen.conditions[a], screen.sulfonyl_fluorides[a],
            screen.bases[a], S + F, S, F, posterior_mean, best[a], θ[a]);
    end
    close(io);
end


"""
    write_posteriors(directory, screen, θ, game)

Plot `posteriors.png`: the posterior of the six most-run conditions in the main screen,
and of the condition with the lowest true success fraction, each with a dashed line at
its true success fraction.

### Arguments
- `directory::String`: the output folder.
- `screen::NamedTuple`: the paper's data, from `load_screen()`.
- `θ::Array{Float64,1}`: the true success fraction of each condition.
- `game::NamedTuple`: the main screen, from `plate_thompson_sampling`.
"""
function write_posteriors(directory, screen, θ, game)

    # Choose the curves: the six most-run conditions, then the worst condition -
    runs = game.S + game.F; # the number of experiments with each condition
    order = sortperm(runs; rev = true); # conditions from most to fewest experiments
    shown = order[1:6];
    worst = argmin(θ);
    if !(worst in shown)
        push!(shown, worst);
    end

    # Draw each posterior, Beta(1 + S, 1 + F) -
    theme(:default);
    x = range(0.0, 1.0; length = 1001);
    figure = plot(; xlabel = "Success probability θ", ylabel = "Posterior density",
        title = "Posteriors after $EXPERIMENTS experiments ($BLOCKS blocks of $WELLS)",
        legend = :topleft, size = (900, 520), framestyle = :box, titlefontsize = 11,
        left_margin = 6 * Plots.mm, bottom_margin = 4 * Plots.mm);
    for k in 1:length(shown)
        a = shown[k];
        posterior = Beta(1 + game.S[a], 1 + game.F[a]);
        density = zeros(length(x));
        for j in 1:length(x)
            density[j] = pdf(posterior, x[j]);
        end
        label = @sprintf("%s: %d runs (true θ = %.2f)", screen.conditions[a], runs[a], θ[a]);
        plot!(figure, x, density; lw = 2, label = label, color = k);
        vline!(figure, [θ[a]]; ls = :dash, lw = 1, color = k, label = "");
    end
    savefig(figure, joinpath(directory, "posteriors.png"));
end


"""
    write_plate_sizes(directory, assignment, yields, θ)

Run 100 screens of 480 experiments for each block size in `BLOCK_SIZES`, and write
`plate-sizes.csv`. One well per block uses `my_thompson_sampling`; the other sizes use
`plate_thompson_sampling`. The last table row is the equal split: every condition runs
on the same number of alcohols, with no learning.

### Arguments
- `directory::String`: the output folder.
- `assignment`: the loaded `FluorinationScreen` module, with the student's functions.
- `yields::Array{Float64,2}`: the yield table.
- `θ::Array{Float64,1}`: the true success fraction of each condition.
"""
function write_plate_sizes(directory, assignment, yields, θ)

    # Set up: the best and second-best success fractions, and the table's header -
    K = length(θ);
    best_value = maximum(θ);
    sorted = sort(θ; rev = true);
    second_value = sorted[2]; # the second-highest success fraction
    screens = length(SCREEN_SEEDS);
    io = open(joinpath(directory, "plate-sizes.csv"), "w");
    println(io, "strategy,wells_per_block,blocks,days,mean_successes,pick_is_best,pick_in_top_two");

    # Run 100 screens for each block size -
    for k in 1:length(BLOCK_SIZES)
        w = BLOCK_SIZES[k]; # wells per block
        blocks = div(EXPERIMENTS, w); # blocks per screen: 480 / w
        total_successes = 0;
        picks_best = 0;
        picks_top_two = 0;
        for s in 1:screens
            seed = SCREEN_SEEDS[s];
            if s % 25 == 0 # print progress every 25 screens
                println("Block size $w: screen $s of $screens");
            end

            # Play one screen with this block size; one well per block is my_thompson_sampling -
            rng = MersenneTwister(seed);
            world = a -> assignment.run_reaction(yields, a, rng; cutoff = CUTOFF);
            if w == 1
                game = assignment.my_thompson_sampling(world, K, EXPERIMENTS; rng = rng);
                check_game(game, K, EXPERIMENTS, "my_thompson_sampling");
            else
                game = assignment.plate_thompson_sampling(world, K, blocks, w; rng = rng);
                check_game(game, K, EXPERIMENTS, "plate_thompson_sampling");
            end
            best = assignment.probability_best(game.S, game.F, DRAWS_AVERAGE; rng = rng);
            pick = argmax(best);

            # Add up the results: successes, and whether the pick is the best or second best -
            total_successes = total_successes + sum(game.rewards);
            if θ[pick] == best_value
                picks_best = picks_best + 1;
            end
            if θ[pick] >= second_value
                picks_top_two = picks_top_two + 1;
            end
        end
        # Write the averages over the 100 screens for this block size -
        @printf(io, "thompson,%d,%d,%d,%.1f,%.2f,%.2f\n", w, blocks, blocks * DAYS_PER_BLOCK,
            total_successes / screens, picks_best / screens, picks_top_two / screens);
    end

    # The equal split: the same number of runs on every condition, no learning -
    runs_each = div(EXPERIMENTS, K); # 480 / 20 = 24 runs per condition
    equal_successes = runs_each * sum(θ); # the expected successes: 24 runs times each success fraction
    @printf(io, "equal_split,,,,%.1f,,\n", equal_successes);
    close(io);
end


"""
    write_ban(directory, screen, θ, pbsf_free, game, first_best, game_free, best_free)

Write `pbsf-ban.csv`: for each PBSF-free condition, its results in the main screen
(experiments, posterior mean, and probability of being best among the PBSF-free
conditions), the same results from the new PBSF-free screen, and its true success
fraction.

### Arguments
- `directory::String`: the output folder.
- `screen::NamedTuple`: the paper's data, from `load_screen()`.
- `θ::Array{Float64,1}`: the true success fraction of each of the 20 conditions.
- `pbsf_free::Array{Int64,1}`: the columns of the PBSF-free conditions in the full table.
- `game::NamedTuple`: the main screen, with all 20 conditions.
- `first_best::Array{Float64,1}`: from the main screen, the probability that each
  PBSF-free condition is the best of the PBSF-free conditions.
- `game_free::NamedTuple`: the new screen, with only the PBSF-free conditions.
- `best_free::Array{Float64,1}`: from the new screen, the probability that each
  PBSF-free condition is the best.
"""
function write_ban(directory, screen, θ, pbsf_free, game, first_best, game_free, best_free)

    # Write one header line, then one line per PBSF-free condition -
    io = open(joinpath(directory, "pbsf-ban.csv"), "w");
    println(io, "condition,main_screen_experiments,main_screen_posterior_mean,main_screen_probability_best," *
        "new_screen_experiments,new_screen_posterior_mean,new_screen_probability_best,true_success_fraction");
    for k in 1:length(pbsf_free)
        a = pbsf_free[k]; # the column of this condition in the full table
        S1 = game.S[a]; # successes in the main screen
        F1 = game.F[a];
        S2 = game_free.S[k]; # successes in the new screen; its column k is condition a
        F2 = game_free.F[k];
        @printf(io, "%s,%d,%.4f,%.4f,%d,%.4f,%.4f,%.4f\n", screen.conditions[a],
            S1 + F1, (1 + S1) / (2 + S1 + F1), first_best[k],
            S2 + F2, (1 + S2) / (2 + S2 + F2), best_free[k], θ[a]);
    end
    close(io);
end

end

# Load the assignment from its own directory, independent of the working directory.
"""
    FluorinationScreen

Load the supplied loader and simulator, then the four functions in `src/Compute.jl`.
The loader, `load_screen()`, returns the paper's deoxyfluorination yield table. The
simulator, `run_reaction(...)`, runs one experiment. Your functions and the reference
solution use the same loader and simulator.

The flag `--solution`, passed after a script's filename, is for the instructor: it
loads the instructor's `solution/src/Compute.jl` instead of `src/Compute.jl`. That
folder is not part of the student download. Without the flag, this file always loads
`src/Compute.jl`.

Include this file once per Julia session to make these functions available. After you
edit a source file, restart Julia, or run the scripts from the terminal as the README
shows.
"""
module FluorinationScreen

using Distributions # Beta: rand(rng, Beta(x, y)) draws one random number from a Beta distribution
using Random        # AbstractRNG, the type of a random number generator such as MersenneTwister(5800)

# Include the loader and the simulator first, because your functions use them -
include(joinpath(@__DIR__, "src", "Data.jl"));
include(joinpath(@__DIR__, "src", "Lab.jl"));
# If you add helper files, include them here, before Compute.jl. If one helper file
# uses another, include the one it uses first. For example, after creating src/MyHelpers.jl:
# include(joinpath(@__DIR__, "src", "MyHelpers.jl"));
# Choose which Compute.jl to load: the instructor's with --solution, otherwise yours -
if "--solution" in ARGS
    const COMPUTE_PATH = joinpath(@__DIR__, "solution", "src", "Compute.jl");
else
    const COMPUTE_PATH = joinpath(@__DIR__, "src", "Compute.jl");
end
if !isfile(COMPUTE_PATH)
    error("Cannot find $COMPUTE_PATH. The --solution flag needs the instructor's solution folder.");
end
include(COMPUTE_PATH);

export load_screen, run_reaction;
export success_fractions, my_thompson_sampling, plate_thompson_sampling, probability_best;

end

using .FluorinationScreen; # make the assignment functions available to the calling script

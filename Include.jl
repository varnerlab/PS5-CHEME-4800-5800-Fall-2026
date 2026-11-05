# Load the assignment from its own directory, independent of the working directory.
"""
    FluorinationScreen

Load the data loader, the simulator, and the four student functions. The loader,
`load_screen()`, returns the yield table of the deoxyfluorination screen. The
simulator, `run_reaction(...)`, runs one experiment. The student functions and the
reference solution use the same loader and simulator.
Pass `--solution` after a script's filename to load `solution/src/Compute.jl`
instead of the student file. The local solution must exist; no files are copied
or replaced. Without that flag, always load `src/Compute.jl`.
Include this file once per Julia session to make the exported names available.
Restart Julia after editing source files, or run the scripts in a new process.
"""
module FluorinationScreen

using Distributions # Beta: rand(rng, Beta(x, y)) draws one sample from a Beta distribution
using Random        # AbstractRNG, the type of a random number generator such as MersenneTwister(5800)

# Load the data loader and the simulator before the student functions that use them -
include(joinpath(@__DIR__, "src", "Data.jl"));
include(joinpath(@__DIR__, "src", "Lab.jl"));
# If you add helper files, include them here in dependency order before Compute.jl.
# For example, after creating src/MyHelpers.jl:
# include(joinpath(@__DIR__, "src", "MyHelpers.jl"));
# Select exactly one implementation; never fall back when the solution is absent -
if "--solution" in ARGS
    const COMPUTE_PATH = joinpath(@__DIR__, "solution", "src", "Compute.jl");
else
    const COMPUTE_PATH = joinpath(@__DIR__, "src", "Compute.jl");
end
if !isfile(COMPUTE_PATH)
    error("Implementation file is missing: $COMPUTE_PATH. --solution requires the local instructor solution.");
end
include(COMPUTE_PATH);

export load_screen, run_reaction;
export success_fractions, my_thompson_sampling, plate_thompson_sampling, probability_best;

end

using .FluorinationScreen; # make the assignment functions available to the calling script

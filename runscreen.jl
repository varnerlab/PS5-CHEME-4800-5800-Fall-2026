# ----------------------------------------------------------------------------
# Run the screens and write the reports
# ----------------------------------------------------------------------------
# Run from the assignment root:
#   julia --startup-file=no --project=. runscreen.jl
#   julia --startup-file=no --project=. runscreen.jl --solution
#
# The --solution flag loads the reference code and writes solution/outputs/.
#
# After Parts 1 and 2 are complete, run the main screen (20 blocks of 24 wells),
# the same 480 experiments with five block sizes (100 screens each), and a new
# screen without PBSF, then write the plots and tables to outputs/. Existing files
# with the same names are overwritten.


# 1. Load the implementation and reporting utilities -
ENV["GKSwstype"] = "100"; # render plots to files without opening a GUI window

include(joinpath(@__DIR__, "Include.jl"));
include(joinpath(@__DIR__, "src", "Reporting.jl"));


# 2. Select the output directory -
if "--solution" in ARGS
    output_directory = joinpath(@__DIR__, "solution", "outputs");
    println("Running the instructor reference solution.");
else
    output_directory = joinpath(@__DIR__, "outputs");
end


# 3. Run the screens and write the reports -
try
    ScreenReports.write_outputs(FluorinationScreen, output_directory);
catch caught
    # An unfinished function gets a short message instead of a long error listing -
    if caught isa ErrorException && startswith(caught.msg, "Complete ")
        println(stderr, "Cannot make the reports yet: ", caught.msg, ".");
        println(stderr, "Finish Parts 1 and 2 and pass testme_part_1.jl and testme_part_2.jl first.");
        if !isinteractive() # stop a script run from the terminal; leave a REPL session running
            exit(1);
        end
    else
        rethrow();
    end
end

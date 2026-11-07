# Check your work: run the 48 tests, make the reports, check responses.md, and
# write MANIFEST.txt.
# Run: julia --startup-file=no --project=. check_submission.jl
# The flag --solution is for the instructor: it checks the reference code and
# responses in solution/ and writes the reports and manifest there. Your files stay
# unchanged.
# The script exits with code 0 if the tests, the reports, and the response check all
# pass, and with code 1 otherwise. Passing does not set your score; the instructor
# grades your answers.
using Test;  # tell failed tests apart from errors that stop a test script
using SHA;   # fingerprint submitted source files and responses
using Dates; # timestamp the submission manifest

# Choose which files to check before running any tests or writing any reports -
const SOLUTION_MODE = "--solution" in ARGS;
const CHECK_ROOT = SOLUTION_MODE ? joinpath(@__DIR__, "solution") : @__DIR__;
const RESPONSE_PATH = joinpath(CHECK_ROOT, "responses.md");
const COMPUTE_PATH = joinpath(CHECK_ROOT, "src", "Compute.jl");
if SOLUTION_MODE
    for path in (COMPUTE_PATH, RESPONSE_PATH)
        if !isfile(path)
            error("Cannot find $path. The --solution flag needs the instructor's solution folder.");
        end
    end
    println("Checking the instructor reference solution; outputs and manifest go under solution/.");
end

"""
    rootcause(caught)

Return the error underneath a caught exception. Julia wraps an error in a
`LoadError` each time it passes through an `include`, so this function removes
those wrappers one at a time. If `caught` is not a `LoadError`, return it as is.
The checker uses the result to tell failed tests apart from errors that stopped a
test script from running.
"""
function rootcause(caught)
    while caught isa LoadError
        caught = caught.error;
    end
    return caught;
end

"""
    discussion_issues(path; questions=1:3) -> Vector{String}

Read the response file at `path` and return a message for each question in
`questions` that is missing, appears twice, has no answer, or still has a TODO or
TBD placeholder. The file must hold numbered, bold question prompts, each followed
by a blank line and then the answer. HTML comments do not count as an answer.

Return an empty vector if there are no problems; this check does not grade your
answers. A missing or unreadable file gives one message. The file is not changed.
"""
function discussion_issues(path; questions=1:3)
    # Check that the file is there -
    if !isfile(path)
        return ["responses.md is missing"];
    end

    # Read the file; remove Windows line endings and a byte-order mark -
    content = "";
    try
        content = read(path, String);
        content = replace(content, "\r\n" => "\n"); # turn Windows line endings into plain ones
        content = replace(content, '\ufeff' => "");  # remove the invisible byte-order mark some editors add
    catch
        return ["responses.md could not be read"];
    end
    answers = Dict{Int,String}(); # question number => answer text
    issues = String[];

    # Separate each numbered prompt from the answer paragraphs that follow it -
    # The pattern finds a line that starts with "1.", "2.", or "3." and a bold "**"
    # prompt, and takes everything up to the next such line or the end of the file.
    for section in eachmatch(r"(?ms)^[ \t]{0,2}([1-3])\.[ \t]+\*\*.*?(?=^[ \t]{0,2}[1-3]\.[ \t]+\*\*|\z)", content)
        number = parse(Int, section.captures[1]);
        if !(number in questions)
            continue;
        end
        if haskey(answers, number)
            push!(issues, "Question $number appears more than once");
        end
        # The prompt is the first paragraph; the answer is everything after the first blank line -
        paragraphs = split(section.match, r"\n[ \t]*\n"; limit=2);
        answer = length(paragraphs) == 2 ? paragraphs[2] : "";
        answer = replace(answer, r"(?s)<!--.*?-->" => ""); # drop HTML comments, <!-- ... -->
        answers[number] = strip(answer);
    end

    # Each question needs an answer with at least one letter or digit, and no placeholder -
    for number in questions
        answer = get(answers, number, "");
        if !occursin(r"[\p{L}\p{N}]", answer)
            push!(issues, "Question $number has no answer");
        elseif occursin(r"(?i)\b(TODO|TBD)\b|Write your response|Your answer here", answer)
            push!(issues, "Question $number still has a placeholder");
        end
    end
    return issues;
end

println("PS5 submission check: Parts 1 and 2, 48 required tests, and questions 1–3.");
statuses = Dict{String,String}();
suites = Dict{String,Module}();
required_suites = ("testme_part_1.jl", "testme_part_2.jl");
# Run each test script in its own module, so loading your code twice does not replace the first copy -
# (Module(gensym(...)) makes a new, empty module with a unique name for each test script)
for filename in required_suites
    println("\nRunning ", filename);
    try
        suite = Module(gensym(:PS5Part));
        Base.include(suite, joinpath(@__DIR__, filename));
        suites[filename] = suite;
        statuses[filename] = "all tests passed";
    catch caught
        if rootcause(caught) isa Test.TestSetException
            statuses[filename] = "some tests failed";
        else
            statuses[filename] = "tests could not run";
            showerror(stderr, caught, catch_backtrace());
            println(stderr);
        end
    end
end

issues = discussion_issues(RESPONSE_PATH);

# Both required test scripts must pass before the reports are made -
# (global: inside a loop or try block at the top of a script, Julia needs this word to
# change a variable defined outside the block)
required_passed = true;
for name in required_suites
    if statuses[name] != "all tests passed"
        global required_passed = false;
    end
end

# Remove earlier reports so outputs/ holds only results from the code just checked -
# (this list must match REPORT_FILES in src/Reporting.jl)
for name in ("conditions.csv", "screen-summary.csv", "posteriors.png", "plate-sizes.csv",
        "gap-loss.png", "pbsf-ban.csv")
    rm(joinpath(CHECK_ROOT, "outputs", name); force=true);
end
report_status = "not generated because tests need attention";
if required_passed
    try
        ENV["GKSwstype"] = "100"; # render plots to files without opening a GUI window
        include(joinpath(@__DIR__, "src", "Reporting.jl"));
        println("\nRunning the screens and writing the reports.");
        assignment = getfield(suites["testme_part_2.jl"], :FluorinationScreen);
        ScreenReports.write_outputs(assignment, joinpath(CHECK_ROOT, "outputs"));
        global report_status = "plots and data tables generated";
    catch caught
        global report_status = "OUTPUT GENERATION NEEDS ATTENTION";
        showerror(stderr, caught, catch_backtrace());
        println(stderr);
    end
end

ready = required_passed && report_status == "plots and data tables generated" && isempty(issues);

# Record the test status and fingerprint every submitted source file -
# walkdir visits src/ and every folder inside it; for each folder it gives the folder,
# its subfolders (not needed here, so named _), and its files.
files = [joinpath(@__DIR__, "Include.jl"), RESPONSE_PATH];
for (directory, _, filenames) in walkdir(joinpath(@__DIR__, "src"))
    for name in filenames
        file_path = joinpath(directory, name);
        # Fingerprint the Compute.jl that was actually loaded (the instructor's, with --solution) -
        if file_path == joinpath(@__DIR__, "src", "Compute.jl")
            file_path = COMPUTE_PATH;
        end
        push!(files, file_path);
    end
end
io = open(joinpath(CHECK_ROOT, "MANIFEST.txt"), "w");
if SOLUTION_MODE
    println(io, "PS5 instructor reference solution manifest");
else
    println(io, "PS5 CHEME 4800/5800 Fall 2026 submission manifest");
end
println(io, "Generated: ", Dates.now());
for name in sort(collect(keys(statuses)))
    println(io, name, ": ", statuses[name]);
end
println(io, "Outputs: ", report_status);
if isempty(issues)
    println(io, "Questions: every question has an answer; the instructor grades them");
else
    println(io, "Questions: ", join(issues, "; "));
end
println(io, "Required work: ", ready ? "checks passed; instructor review required" : "WORK NEEDS ATTENTION");
for path in sort(files)
    relative = replace(relpath(path, @__DIR__), '\\' => '/');
    try
        stream = open(path);
        println(io, bytes2hex(sha256(stream)), "  ", relative); # the file's SHA-256 fingerprint
        close(stream);
    catch
        println(io, "MISSING OR UNREADABLE  ", relative);
    end
end
close(io);

println("\nSubmission summary");
for name in sort(collect(keys(statuses)))
    println(name, ": ", statuses[name]);
end
println("Outputs: ", report_status);
for issue in issues
    println("Questions: ", issue);
end
if SOLUTION_MODE
    println("Status: ", ready ? "REFERENCE SOLUTION PASSED" : "REFERENCE SOLUTION NEEDS ATTENTION");
    println("Wrote solution/MANIFEST.txt; reference outputs are in solution/outputs/.");
else
    println("Status: ", ready ? "READY TO PACKAGE; instructor review pending" : "WORK NEEDS ATTENTION");
    println("Wrote MANIFEST.txt. Zip the whole folder, including MANIFEST.txt and outputs/.");
    println("Name it CHEME-4800-5800-PS5-<your netid>.zip and upload it to Canvas yourself.");
    println("Submit your current work by the initial deadline even if some tests still fail.");
end
exit(ready ? 0 : 1);

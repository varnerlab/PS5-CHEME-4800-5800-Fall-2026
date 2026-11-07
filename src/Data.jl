# ----------------------------------------------------------------------------
# Supplied loader | Read the paper's deoxyfluorination yields from data/.
# ----------------------------------------------------------------------------

const DATA_FILE = "deoxyfluorination.csv"; # the paper's yields: 37 alcohols × 20 conditions
const SULFONYL_FLUORIDES = ["3-Cl", "PyFluor", "3-CF3", "3-NO2", "PBSF"]; # least to most reactive
const BASES = ["DBU", "MTBD", "BTMG", "BTPP"]; # least to most bulky
const NUMBER_OF_ALCOHOLS = 37;

"""
    load_screen(directory::String = <the assignment's data folder>) -> NamedTuple

Read the paper's deoxyfluorination yields: 37 alcohols, each run under 20
conditions. A condition is one sulfonyl fluoride paired with one base.

### Returns
A named tuple with these fields:
- `yields::Array{Float64,2}`: the 37 × 20 table of yields, in percent. Row `i` is
  alcohol `i` and column `a` is condition `a`. Each entry is the ¹⁹F NMR yield of the
  alkyl fluoride made from that alcohol under that condition.
- `conditions::Array{String,1}`: the name of each condition (column), such as
  `"PBSF/BTMG"` (the sulfonyl fluoride, then the base).
- `sulfonyl_fluorides::Array{String,1}` and `bases::Array{String,1}`: the sulfonyl
  fluoride and the base of each condition (column).
- `alcohols::Array{String,1}`: the ID of each alcohol (row), `"s1"` to `"s37"`.
- `smiles::Array{String,1}`: the structure of each alcohol (row), as a SMILES string.

The columns go sulfonyl fluoride by sulfonyl fluoride (3-Cl, PyFluor, 3-CF3, 3-NO2,
PBSF), and for each one, base by base (DBU, MTBD, BTMG, BTPP). So column 1 is
`"3-Cl/DBU"`, column 20 is `"PBSF/BTPP"`, and columns 1 to 16 are the conditions
without PBSF.

### Errors
Throws an `ErrorException` that names the file if the data file is missing or does
not hold the expected 740 reactions, which usually means the download or unzip was
incomplete or the file was changed.
"""
function load_screen(directory::String = joinpath(@__DIR__, "..", "data"))

    # Check that the file is there -
    path = joinpath(directory, DATA_FILE);
    if !isfile(path)
        error("data file $DATA_FILE is missing from $directory. Download the assignment again.");
    end

    # Read the lines; remove Windows line endings so a file saved by Excel still reads -
    text = replace(read(path, String), "\r" => "");
    lines = split(text, "\n"; keepempty = false);
    number_of_conditions = length(SULFONYL_FLUORIDES) * length(BASES);
    expected_rows = NUMBER_OF_ALCOHOLS * number_of_conditions; # 740 reactions
    if length(lines) != expected_rows + 1 # one header line, then one line per reaction
        error("data file $DATA_FILE has $(length(lines) - 1) reactions; expected $expected_rows. Download the assignment again.");
    end

    # Build the condition names in column order -
    conditions = String[];
    sulfonyl_fluorides = String[];
    bases = String[];
    for fluoride in SULFONYL_FLUORIDES
        for base in BASES
            push!(conditions, fluoride * "/" * base);
            push!(sulfonyl_fluorides, fluoride);
            push!(bases, base);
        end
    end

    # Fill the table: the rows of the file go alcohol by alcohol, then condition by condition -
    yields = zeros(NUMBER_OF_ALCOHOLS, number_of_conditions);
    alcohols = String[];
    smiles = String[];
    line_number = 1; # line 1 is the header
    for i in 1:NUMBER_OF_ALCOHOLS
        for a in 1:number_of_conditions
            line_number = line_number + 1;
            fields = split(lines[line_number], ","); # alcohol, SMILES, sulfonyl fluoride, base, yield
            if length(fields) != 5 || fields[3] != sulfonyl_fluorides[a] || fields[4] != bases[a]
                error("data file $DATA_FILE: line $line_number is not the expected reaction (alcohol $i, condition $(conditions[a])); it should hold 740 reactions in order. Download the assignment again.");
            end
            if a == 1
                # String(...) copies each piece of the line into a string of its own -
                push!(alcohols, String(fields[1])); # the alcohol's ID, such as s1
                push!(smiles, String(fields[2]));   # the alcohol's structure
            end
            yields[i, a] = parse(Float64, fields[5]); # the yield, in percent
        end
    end

    return (yields = yields, conditions = conditions, sulfonyl_fluorides = sulfonyl_fluorides,
        bases = bases, alcohols = alcohols, smiles = smiles);
end

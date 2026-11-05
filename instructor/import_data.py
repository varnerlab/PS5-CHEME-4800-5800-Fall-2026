"""Download the deoxyfluorination screen and write the PS5 data files to data/.

Run: python3 -I instructor/import_data.py
Only the Python standard library is required. Download the published table and
the repository license (MIT at that commit) at a pinned commit into a temporary folder, never from a
local copy. Check the table's hash and shape, then overwrite the shipped files in
data/. Failed checks raise AssertionError; download and file errors propagate.
"""
from pathlib import Path
import csv
import hashlib
import json
import tempfile
import urllib.request

REPOSITORY = "https://github.com/doyle-lab-ucla/bandit-optimization"
COMMIT = "084bb561a200ee5950a215c7026012878a7bc065"  # last change to datasets/deoxyf.csv (2023-10-24)
RAW = f"https://raw.githubusercontent.com/doyle-lab-ucla/bandit-optimization/{COMMIT}/"
SOURCE_FILE = "datasets/deoxyf.csv"
SOURCE_SHA256 = "1c6b0f2401e2d945fc8f0fc0a905249eb2eb7e42fdc92782e85ab2cbb4c90e85"
LICENSE_FILE = "LICENSE.md"

# Column order: sulfonyl fluoride first, in the paper's order of increasing reactivity,
# then base, in the paper's order of increasing steric bulk (Nielsen et al. 2018, Figure 1) -
SULFONYL_FLUORIDES = ["3-Cl", "PyFluor", "3-CF3", "3-NO2", "PBSF"]
BASES = ["DBU", "MTBD", "BTMG", "BTPP"]
ALCOHOLS = [f"s{k}" for k in range(1, 38)]  # s1 to s37
CUTOFF = 50.0

root = Path(__file__).resolve().parents[1]
data = root / "data"
data.mkdir(exist_ok=True)


def sha256(path):
    """Return the hex SHA-256 digest of the file at path."""
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def download(name, folder):
    """Download one file from the pinned commit into folder and return its path."""
    target = Path(folder) / Path(name).name
    with urllib.request.urlopen(RAW + name) as response:
        target.write_bytes(response.read())
    return target


# 1. Download the table and the license at the pinned commit; check the table's hash -
with tempfile.TemporaryDirectory() as folder:
    table_path = download(SOURCE_FILE, folder)
    assert sha256(table_path) == SOURCE_SHA256, f"{SOURCE_FILE}: unexpected SHA-256 {sha256(table_path)}"
    print(f"{SOURCE_FILE}: hash OK")
    license_path = download(LICENSE_FILE, folder)
    license_text = license_path.read_text(encoding="utf-8")
    # At this commit the repository is under the MIT license; it moved to GPL-3.0 in March 2025 -
    assert "Permission is hereby granted, free of charge" in license_text, "license at the pinned commit is not MIT"
    assert "Jason Y. Wang" in license_text, "unexpected copyright line in the license"
    with open(table_path, newline="", encoding="utf-8") as handle:
        source_rows = list(csv.DictReader(handle))

# 2. Check the table: 37 alcohols × 20 conditions, each pair once, integer yields -
assert len(source_rows) == 740, f"expected 740 rows, found {len(source_rows)}"
yields = {}
smiles = {}
for row in source_rows:
    key = (row["substrate_name"], row["fluoride_name"], row["base_name"])
    assert key not in yields, f"duplicate row {key}"
    value = float(row["yield"])
    assert value == int(value) and 0 <= value <= 110, f"unexpected yield {value} in {key}"
    yields[key] = int(value)
    previous = smiles.setdefault(row["substrate_name"], row["substrate_smiles"])
    assert previous == row["substrate_smiles"], f"two SMILES for {row['substrate_name']}"
    assert "," not in row["substrate_smiles"] and '"' not in row["substrate_smiles"], "SMILES needs quoting"
for alcohol in ALCOHOLS:
    for fluoride in SULFONYL_FLUORIDES:
        for base in BASES:
            assert (alcohol, fluoride, base) in yields, f"missing {(alcohol, fluoride, base)}"

# 3. Write the shipped table: one row per alcohol and condition, alcohols in order, then conditions -
rows = []
for alcohol in ALCOHOLS:
    for fluoride in SULFONYL_FLUORIDES:
        for base in BASES:
            rows.append([alcohol, smiles[alcohol], fluoride, base, yields[(alcohol, fluoride, base)]])
with open(data / "deoxyfluorination.csv", "w", newline="", encoding="utf-8") as handle:
    writer = csv.writer(handle, lineterminator="\n")
    writer.writerow(["alcohol", "alcohol_smiles", "sulfonyl_fluoride", "base", "yield_percent"])
    writer.writerows(rows)
print(f"deoxyfluorination.csv: {len(rows)} rows")

# 4. Copy the license text that covers the table (MIT: keep the copyright and permission notice) -
(data / "LICENSE-bandit-optimization.txt").write_text(license_text, encoding="utf-8")

# 5. Summarize the table for the data notes: successes per condition and never-successful alcohols -
counts = []
for fluoride in SULFONYL_FLUORIDES:
    for base in BASES:
        counts.append(sum(1 for alcohol in ALCOHOLS if yields[(alcohol, fluoride, base)] >= CUTOFF))
never = [alcohol for alcohol in ALCOHOLS
         if max(yields[(alcohol, f, b)] for f in SULFONYL_FLUORIDES for b in BASES) < CUTOFF]
print("alcohols at or above 50% per condition:", counts)
print("alcohols below 50% under every condition:", never)

# 6. Record where the files came from -
provenance = {
    "dataset": "Deoxyfluorination of 37 alcohols under 20 sulfonyl fluoride and base combinations",
    "measurements": {
        "authors": ["Matthew K. Nielsen", "Derek T. Ahneman", "Orestes Riera", "Abigail G. Doyle"],
        "title": "Deoxyfluorination with Sulfonyl Fluorides: Navigating Reaction Space with Machine Learning",
        "journal": "Journal of the American Chemical Society",
        "year": 2018,
        "volume": 140,
        "issue": 15,
        "pages": "5004-5008",
        "doi": "10.1021/jacs.8b01523",
    },
    "repository_paper": {
        "authors": "Wang, J. Y. et al.",
        "title": "Identifying general reaction conditions by bandit optimization",
        "journal": "Nature",
        "year": 2024,
        "volume": 626,
        "pages": "1025-1033",
        "doi": "10.1038/s41586-024-07021-y",
    },
    "repository": REPOSITORY,
    "commit": COMMIT,
    "source_file": SOURCE_FILE,
    "source_url": RAW + SOURCE_FILE,
    "source_sha256": SOURCE_SHA256,
    "license": "MIT license of the source repository at the pinned commit (Copyright (c) 2012-2023 Jason Y. Wang "
               "and others); full text in data/LICENSE-bandit-optimization.txt. Later versions of the repository "
               "(from March 2025) use GPL-3.0; the shipped table comes from the MIT-licensed commit.",
    "selection": "all 740 rows (37 alcohols, 20 conditions); only the alcohol ID, alcohol SMILES, "
                 "sulfonyl fluoride, base, and yield columns are kept",
    "row_order": "alcohols s1 to s37 by number; within each alcohol, sulfonyl fluoride in the order "
                 + ", ".join(SULFONYL_FLUORIDES) + ", then base in the order " + ", ".join(BASES),
    "yield": "19F NMR yield of the alkyl fluoride product, percent, as published (integers from 0 to 106)",
    "shipped_sha256": {name: sha256(data / name) for name in ["deoxyfluorination.csv", "LICENSE-bandit-optimization.txt"]},
}
(data / "provenance.json").write_text(json.dumps(provenance, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print("provenance.json written")
for name, digest in provenance["shipped_sha256"].items():
    print(f"  {name}: {digest}")

"""Build a student ZIP from the explicit file list, excluding instructor material.

Run from any directory: python3 instructor/build_student_package.py [--draft]
Write or overwrite the ZIP in instructor/artifacts/. --draft allows dates marked
to be announced and adds -draft to the archive name. No files are published.
"""
from pathlib import Path
import argparse
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ROOT_FILES = ["README.md", "RUBRIC.md", "responses.md", "Project.toml", "Manifest.toml",
              "Include.jl", "test_support.jl", "testme_part_1.jl", "testme_part_2.jl",
              "check_submission.jl", "runscreen.jl", "LICENSE", "THIRD_PARTY_NOTICES.txt"]
DIRECTORIES = ["src", "data"]

def student_files():
    """Return absolute Paths for the required root files and all src/ and data/ files.

    Exclude .DS_Store and Python bytecode-cache directories. Read paths relative
    to ROOT without changing files. Raise AssertionError if a required file is
    missing. This list is also used to stage isolated validation copies.
    """
    files = [ROOT / name for name in ROOT_FILES]
    files += [p for name in DIRECTORIES for p in sorted((ROOT / name).rglob("*"))
              if p.is_file() and p.name != ".DS_Store" and "__pycache__" not in p.parts]
    assert all(p.is_file() for p in files), "A required student file is missing"
    return files

def main():
    """Read the command-line options, build the ZIP, and verify its student contents.

    Return None after printing the archive path and file count. Reject unset
    dates unless --draft is supplied. Raise AssertionError if forbidden material
    is packaged or the four student stubs are absent. File errors propagate.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument("--draft", action="store_true", help="Allow dates marked to be announced")
    args = parser.parse_args()
    if "To be announced" in (ROOT / "README.md").read_text() and not args.draft:
        parser.error("Set the release and submission dates before building a release, or use --draft")
    out = ROOT / "instructor" / "artifacts"
    out.mkdir(exist_ok=True)
    suffix = "-draft" if args.draft else ""
    archive = out / f"PS5-CHEME-4800-5800-Fall-2026-student{suffix}.zip"
    prefix = "PS5-CHEME-4800-5800-Fall-2026"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
        for path in student_files():
            bundle.write(path, str(Path(prefix) / path.relative_to(ROOT)))
    with zipfile.ZipFile(archive) as bundle:
        names = bundle.namelist()
        assert not any(part in Path(name).parts for name in names
                       for part in ("solution", "instructor", ".git", "outputs"))
        compute = bundle.read(prefix + "/src/Compute.jl").decode()
        assert compute.count('error("Complete ') == 4, "Student starter must contain exactly four stubs"
    print(f"Built {archive} ({len(names)} files); no reference solution or generated answers included.")

if __name__ == "__main__":
    main()

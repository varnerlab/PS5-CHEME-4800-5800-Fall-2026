"""Build and test the Git source archive without access to the private solution.

Run from any directory: python3 instructor/validate_release.py [--ref REF] [--tag TAG]
The release Action runs this with --tag before creating a draft GitHub release.
It checks the committed tree only; the working tree and solution/ are not used.
"""
import argparse
import hashlib
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile
from build_student_package import ROOT, ROOT_FILES

# The archive must hold exactly the student package plus Git's own settings files -
REQUIRED_FILES = set(ROOT_FILES) | {
    "src/Data.jl", "src/Lab.jl", "src/Compute.jl", "src/Reporting.jl",
    "data/README.md", "data/deoxyfluorination.csv", "data/provenance.json",
    "data/LICENSE-bandit-optimization.txt",
}
ALLOWED_EXTRA = {".gitattributes", ".gitignore"}
REPORTS = ("screen-summary.csv", "plate-sizes.csv", "pbsf-ban.csv")


def require(condition, message):
    """Stop the release if a required check fails."""
    if not condition:
        raise RuntimeError(message)


def git(*arguments):
    """Run a git command in the repository and return its output, without trailing whitespace."""
    return subprocess.check_output(["git", *arguments], cwd=ROOT, text=True).strip()


def run_julia(student, *arguments, timeout=900):
    """Run Julia in the student copy with its environment; return (exit code, output)."""
    result = subprocess.run(
        ["julia", "--startup-file=no", "--project=.", *arguments],
        cwd=student, text=True, capture_output=True, timeout=timeout,
    )
    return result.returncode, result.stdout + result.stderr


def check_contents(student, names):
    """Check the archive's file list, starter placeholders, and local links."""
    files = {name for name in names if not name.endswith("/")}
    require(REQUIRED_FILES <= files, f"Missing student files: {sorted(REQUIRED_FILES - files)}")
    require(files <= REQUIRED_FILES | ALLOWED_EXTRA,
            f"Unexpected files in archive: {sorted(files - REQUIRED_FILES - ALLOWED_EXTRA)}")
    prohibited = {".git", ".github", "instructor", "solution", "outputs", "__pycache__"}
    for name in names:
        path = Path(name)
        require(not path.is_absolute() and ".." not in path.parts, f"Invalid archive path: {name}")
        require(not prohibited.intersection(path.parts), f"Instructor or generated file in archive: {name}")

    source = (student / "src/Compute.jl").read_text()
    require(source.count('error("Complete ') == 4, "Expected four unfinished starter functions")
    responses = (student / "responses.md").read_text()
    require(responses.count("\n   TODO: Write your response.\n") == 3, "Expected three unanswered questions")

    for markdown in student.rglob("*.md"):
        # GitHub's math renderer rejects these macros and shows an error in place of the math -
        for macro in ("\\operatorname", "\\DeclareMathOperator", "\\newcommand"):
            require(macro not in markdown.read_text(),
                    f"{markdown.relative_to(student)} uses {macro}, which GitHub cannot render")
        for target in re.findall(r"\]\(([^)]+)\)", markdown.read_text()):
            if target.startswith(("https:", "http:", "mailto:", "#")):
                continue
            require((markdown.parent / target.split("#")[0]).exists(),
                    f"Broken local link in {markdown.relative_to(student)}: {target}")


def main():
    """Check the tag (if given), build the source archive of the commit, and test it."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ref", default="HEAD", help="Committed tree to check")
    parser.add_argument("--tag", help="Release tag, which must identify the same commit")
    arguments = parser.parse_args()
    if arguments.tag:
        require(git("rev-parse", f"{arguments.tag}^{{commit}}") ==
                git("rev-parse", f"{arguments.ref}^{{commit}}"), "Release tag does not match the checked commit")
        canvas = git("show", f"{arguments.ref}:instructor/canvas-assignment-description.html")
        require(f"/releases/tag/{arguments.tag}\"" in canvas, "Canvas description does not link to the release tag")

    with tempfile.TemporaryDirectory(prefix="ps5-release-") as temporary:
        directory = Path(temporary)
        archive = directory / "student.zip"
        subprocess.run(["git", "archive", "--format=zip", f"--output={archive}", arguments.ref],
                       cwd=ROOT, check=True)
        student = directory / "student"
        with zipfile.ZipFile(archive) as bundle:
            names = bundle.namelist()
            bundle.extractall(student)
        check_contents(student, names)
        print("Archive contents, starter placeholders, and local links passed.", flush=True)

        # Install the recorded environment exactly as the README instructs -
        code, output = run_julia(student, "-e", "using Pkg; Pkg.instantiate()", timeout=3600)
        require(code == 0, f"Pkg.instantiate failed:\n{output[-8000:]}")
        print("Recorded Julia environment installed.", flush=True)

        # The supplied loader and simulator must work with the shipped data and environment -
        (student / "instructor").mkdir()
        test_supplied = git("show", f"{arguments.ref}:instructor/test_supplied.jl") # the committed copy
        (student / "instructor/test_supplied.jl").write_text(test_supplied + "\n", encoding="utf-8")
        code, output = run_julia(student, "instructor/test_supplied.jl")
        require(code == 0, f"Loader and simulator checks failed:\n{output[-8000:]}")
        print("Loader and simulator checks passed.", flush=True)

        # The unfinished starter must fail clearly and still write a manifest -
        code, output = run_julia(student, "check_submission.jl")
        require(code == 1, f"Starter checker should exit 1, not {code}:\n{output[-8000:]}")
        require("Status: WORK NEEDS ATTENTION" in output and "READY TO PACKAGE" not in output,
                "Starter incorrectly reported completion")
        for number in (1, 2, 3):
            require(f"Question {number} still has a placeholder" in output, f"Missing warning for question {number}")
        manifest = (student / "MANIFEST.txt").read_text()
        require(manifest.count("some tests failed") == 2, "Manifest did not record both unfinished parts")
        for name in ("Include.jl", "responses.md"):
            digest = hashlib.sha256((student / name).read_bytes()).hexdigest()
            require(f"{digest}  {name}" in manifest, f"Manifest omitted the {name} digest")
        require(not any((student / "outputs" / name).exists() for name in REPORTS),
                "Starter produced reports")
        print("Starter failures, question warnings, and manifest passed.", flush=True)
    print("The student source archive is ready for a draft GitHub release.")


if __name__ == "__main__":
    main()

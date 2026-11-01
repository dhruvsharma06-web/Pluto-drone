"""Index a locally built APK. Does not upload artifacts or certify device behavior."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args], text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    apk = args.apk.resolve(strict=True)
    # Deliberately require an artifact in this checkout. No machine-local SDK
    # paths, signing material, user photographs or credentials enter the index.
    location = apk.relative_to(ROOT).as_posix()
    with apk.open("rb") as stream:
        digest = hashlib.file_digest(stream, "sha256").hexdigest()
    result = {
        "artifact": "pluto-inspector-runtime-candidate",
        "version": "0.1.0+1",
        "source_commit": git("rev-parse", "HEAD"),
        "working_tree_dirty_at_index": bool(git("status", "--porcelain")),
        "location": location,
        "sha256": digest,
        "bytes": apk.stat().st_size,
        "signing": "Android debug identity; hackathon sideload only",
        "abi": "arm64-v8a",
        "minimum_android_api": 24,
        "physical_device_tested": False,
        "detector_integrated": False,
        "reference_version": "pending",
        "dataset": None,
        "model": None,
        "access": "Local build; no shared release uploaded",
        "rights": "Team source; third-party notices retained in APK. Repository licence undecided.",
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(f"Indexed {location}: sha256={digest}")


if __name__ == "__main__":
    main()

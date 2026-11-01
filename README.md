# Pluto propeller installation verifier

Shared hackathon skeleton for an Android Flutter app with an OpenCV/ML core and a separate overview website. **Scaffold only: camera, real inference, verified drone configuration and final APK are not implemented.** The runtime fails closed with Unable to Verify. The unrelated earlier Pluto X ZIP is excluded.

## Start here

1. Clone this entire repository and switch to your assigned branch below.
2. Open your copy-ready prompt in `prompts/` and give its entire contents to your AI tool.
3. Read the shared contract; implement in owned paths; update your handoff.
4. Develop independently. Merge workstreams only during the agreed final integration window.

| Person | Workstream | Branch | Prompt |
|---|---|---|---|
| 1 | Drone research only | `research/drone` | [Research](prompts/research.md) |
| 2: frontend owner | Flutter UI with Codex | `frontend/flutter` | [Flutter frontend](prompts/frontend-app.md) |
| 2: same person | Website UI with Claude | `frontend/website` | [Website](prompts/frontend-web.md) |
| 3 | App/runtime/APK and final integration | `app/runtime` | [App](prompts/app.md) |
| 4 | CV/ML/dataset/training | `ml/vision` | [ML](prompts/ml.md) |

`main` is the common baseline; `integration/final` is reserved for end-stage assembly. Use separate clones/worktrees for concurrent Codex/Claude frontend work. Never switch the branch in another running tool's working directory.

## Layout and checks

- `apps/mobile/`: generated Android Flutter wrapper; owned by app developer.
- `packages/inspection_ui/`: Flutter presentation; owned by frontend developer.
- `packages/inspection_runtime/`: controller/acquisition/engine adapters; app developer.
- `packages/inspection_contract/`, `contracts/`: shared v1 boundary and labelled fixtures.
- `apps/website/`: independent website; frontend developer using Claude.
- `vision/`, `ml/`, `datasets/`, `models/`: CV/data/training; ML developer.
- `docs/research/`, `reference/evidence/`: drone research and source evidence.
- `docs/handoffs/`, `docs/status/`: isolated owner-specific records.
- `resources/manifest.json`: versioned external-resource index for the entire team.

Contract checks: `python -m pip install -r tools/requirements.txt`, then `python tools/check_contracts.py` from repo root.
Flutter: in `apps/mobile`, run `flutter pub get`, `flutter analyze`, `flutter test`, then `flutter run`. Package checks can run in each package. These verify a safe scaffold; they do not establish detector quality. Android SDK/NDK/device setup is documented by app owner as integration proceeds.

## Product and schedule

Inspection requires disarmed drone and stopped motors. Results: Pass, Incorrect Installation, Unable to Verify. Unclear inputs must not receive Pass. Both live and upload inputs are required in the completed product. Core logic must remain reusable.

First round in about 5h and second in about 8h from the user's deadline message. See [deadline plan](docs/DEADLINES.md), [ownership](docs/OWNERSHIP.md), [branch commands](docs/BRANCH_WORKFLOW.md), [architecture](docs/ARCHITECTURE.md), [contract](docs/CONTRACT.md), [requirements](docs/REQUIREMENTS.md), and [status](docs/STATUS.md).

No project-wide licence is invented here. Track third-party licences/permissions; team decides repository licensing. APK/data/model/website release links are pending until real artifacts exist.

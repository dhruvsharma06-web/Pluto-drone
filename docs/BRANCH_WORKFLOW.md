# Independent branches, final integration

All role branches start from the SAME bootstrap commit. Keep working independently until the end-stage integration window, as requested. Main remains the baseline during that period. Fetching/reading another branch is okay; merging its code early is outside this workflow. Coordinate interfaces using v1 docs/fixtures and handoff proposals. No force pushes, no wholesale root regeneration and no duplicate full-product repositories.

```sh
git clone https://github.com/dhruvsharma06-web/Pluto-drone.git
cd Pluto-drone
git fetch origin
git switch --track origin/research/drone
# Replace research/drone with YOUR branch. If already tracked: git switch YOUR_BRANCH
git status
# Edit only owned files, run checks, then stage selected paths:
git add docs/research docs/status/research.md docs/handoffs/research.md
git commit -m "docs(research): record verified drone evidence"
git push -u origin HEAD
```

For two concurrent frontend tools use separate directories/worktrees:

```sh
git worktree add ../Pluto-flutter frontend/flutter
git worktree add ../Pluto-website frontend/website
```

If those branches are not local yet, use `git worktree add -b frontend/flutter ../Pluto-flutter origin/frontend/flutter` (and similarly for website). Do not run both AIs in one mutable checkout. Each task receives its prompt and reads shared docs.

At final integration (app owner, coordinate with all owners):

```sh
git fetch origin
git switch integration/final
git merge --no-ff origin/research/drone
git merge --no-ff origin/ml/vision
git merge --no-ff origin/frontend/flutter
git merge --no-ff origin/app/runtime
git merge --no-ff origin/frontend/website
# Resolve changes with the affected owner; run checks and real APK/device demo.
git push origin integration/final
# Open reviewed PR integration/final -> main only after evidence is recorded.
```

Leave integration time before BOTH rounds: target first combined candidate by about 3.5h after the deadline message; second candidate by about 6.5h. Do not delay the first integrated attempt until minutes before judging. These are end-stage windows, not continuous feature merges. Final integration may start as soon as all bounded handoffs are ready. A draft PR can show a branch's work without merging. Do not create empty PRs at baseline.

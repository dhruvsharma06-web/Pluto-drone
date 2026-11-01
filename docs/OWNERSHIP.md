# Ownership

- **Person 1: drone research** (`research/drone`): docs/research/, reference/evidence/, docs/status/research.md, docs/handoffs/research.md.
- **Person 2 (you): Flutter frontend with Codex** (`frontend/flutter`): packages/inspection_ui/, docs/frontend/, docs/status/frontend-app.md, docs/handoffs/frontend-app.md.
- **Person 2 (you): website UI with Claude** (`frontend/website`): apps/website/, docs/website/, docs/status/frontend-web.md, docs/handoffs/frontend-web.md.
- **Person 3: Flutter application and integration** (`app/runtime`): apps/mobile/, packages/inspection_runtime/, tools/, .github/workflows/, docs/app/, docs/status/app.md, docs/handoffs/app.md.
- **Person 4: OpenCV, ML, dataset and training** (`ml/vision`): vision/, ml/, datasets/, models/, reference/config/, docs/ml/, docs/status/ml.md, docs/handoffs/ml.md.

Shared contracts, package interface types, root docs, root ignore files and Android composition/dependencies are coordinated by app owner after checking affected consumers. Frontend UI changes stay in its package, website changes stay in its app. Research owns facts/evidence; ML encodes active reference with research domain review. Do not edit other people's files without an agreed handoff. Each role owns its module tests and documentation. App owner assembles release/test report; ML supplies evaluation; research reviews domain claims; frontend verifies rendered screens/site.

GitHub usernames for other teammates have not been supplied. No collaborator invitations, CODEOWNERS enforcement or branch protection has been configured. Ownership is documented, not server-enforced. Each teammate may add preferences inside owned docs and its own handoff; shared implications need coordination.

# Person 3: Flutter application and integration: status

Branch: `app/runtime`

State: MERGED CANDIDATE INSTALLED/LAUNCHED ON PHONE; FULL DEVICE ACCEPTANCE AND REAL DETECTOR PENDING.

Latest physical smoke: USB debugging authorized; APK installed and launched successfully on Samsung SM-S731B, Android17/API37, arm64-v8a. Initial unchecked safety gate/disabled Start observed; no matching fatal errors in sampled app logs. User is trying gallery upload; captured upload screen has not yet shown selected photo/result. Camera and complete acquisition/lifecycle tests remain pending. See `docs/app/DEVICE_SMOKE.md`; no private photo committed.

Combined APK source commit: `0f9c249faeb876f5e6d63d63f20959cf6c1096cc`, merging latest `frontend/flutter` `4c28f735d6a0ec0f1c07f8a3d04db9e413fdf55c` at the user's explicit request. Earlier runtime implementation source: `e06f4362fc8eb73bbbbf0cb94ee31bebfc3b3ac4`.

Implemented: system image picker/recovery; sampled rear-camera stills and injected preview; safety/lifecycle cancellation; unique input IDs; bounded decode/inference and pending import; isolate JPEG/PNG EXIF normalization; still viewport geometry; reference validation; fail-closed native adapter/result guard; arm64 sideload packaging; CI and reproducible handoff/docs.

Actual post-merge checks: 46 runtime tests + 14 frontend checks + 1 mobile widget test passed; frontend/mobile analysis clean (runtime analysis previously clean); contract checker passed (4 labelled fixtures, 7 unsafe mutations, bundled pending reference); merged arm64 APK built with debug signing and verified signature/ABI/permissions. See `docs/app/VALIDATION.md` and `docs/app/apk.json`. Windows sees a connected Samsung phone; ADB still lists no devices, so installation/phone testing is pending debugging setup.

Blockers: real supplied-drone reference/variant, dataset/model, Android ML engine, ADB authorization/physical phone validation and remaining end-stage integration. Frontend is now merged. Production cannot verify installations; missing inputs/engine remain Unable to Verify. Live tracking is unimplemented and live verified statuses abstain. No latency/FPS/accuracy claim.

Latest user steering: merge latest frontend into current runtime branch (completed); phone is cabled and user is fixing USB-debugging setup. Conserve usage; no extra agents, unrelated redesign, cloud workaround, push or deployment. Other role branches remain independent. Supplied frontend design preserved; no design skill workflow needed for this merge/build-only work.

Next: ML/app agree the documented Android adapter proposal and proof; research/ML supply reviewed reference/resources; frontend consumes unchanged v1 controller/preview; user follows phone checklist. Leave ~90 minutes before each estimated round for coordinated final integration. Source changes are local commits on `app/runtime`.

# Person 3: Flutter application and integration: status

Branch: `app/runtime`

State: APP/RUNTIME CANDIDATE BUILT; REAL DETECTOR AND PHYSICAL VALIDATION BLOCKED.

Runtime source commit: `e06f4362fc8eb73bbbbf0cb94ee31bebfc3b3ac4`.

Implemented: system image picker/recovery; sampled rear-camera stills and injected preview; safety/lifecycle cancellation; unique input IDs; bounded decode/inference and pending import; isolate JPEG/PNG EXIF normalization; still viewport geometry; reference validation; fail-closed native adapter/result guard; arm64 sideload packaging; CI and reproducible handoff/docs.

Actual checks: 46 runtime tests + 1 mobile widget test passed; analysis clean in both modules; contract checker passed (4 labelled fixtures, 7 unsafe mutations, bundled pending reference); arm64 release-mode APK built with debug signing. See `docs/app/VALIDATION.md` and `docs/app/apk.json` for package/signature/hash evidence. No device connected (`adb devices -l` empty).

Blockers: real supplied-drone reference/variant, dataset/model, Android ML engine, physical phone validation, frontend replacement and agreed end-stage integration. Production cannot verify installations; missing inputs/engine remain Unable to Verify. Live tracking is unimplemented and live verified statuses abstain. No latency/FPS/accuracy claim.

Preference: user confirmed no connected device now; will attach it later. Preserve independent branches and conserve usage; no extra agents, unrelated UI design, cloud workaround, push, merge or deployment. Skills catalog reviewed; visual/design skills are not applicable to this infrastructure-only work.

Next: ML/app agree the documented Android adapter proposal and proof; research/ML supply reviewed reference/resources; frontend consumes unchanged v1 controller/preview; user follows phone checklist. Leave ~90 minutes before each estimated round for coordinated final integration. Source changes are local commits on `app/runtime`.

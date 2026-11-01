# Final integration and demo gate

- Collect each handoff's branch/commit, v1 compatibility, commands and real limitations. Preserve a recovery commit before merging.
- Merge role branches in integration/final using the documented plan; coordinate overlapping shared files.
- Validate reference matches supplied drone; pending reference must refuse verification.
- Run schema/semantic checks, Flutter analyze/test and applicable core/data tests.
- Trace same real image through normalization -> detector -> reference -> structured result -> correct overlay/guidance. Test a different input, not only the fixture.
- Demonstrate correct, misplaced/incorrect and unclear/occluded inputs; no unclear-input Pass. Exercise live input plus upload and stale-result reset.
- Install exact APK on actual available Android device; record OS/device, APK hash, commit, model/data/reference versions and observed latency.
- Keep drone disarmed and motors stopped. Do not demonstrate motor control. State unobservable limitations.
- Freeze code/resources; provide README/build/install/user guide, dataset/annotations/splits, method/training docs, results/error analysis and known issues. Model files only if actually trained/exported.
- Website uses approved assets, actual screenshots/claims and working resource links; mobile and reduced-motion fallback checked.
- Deliver identical versioned resource index and access to all four teammates. Review PR into main; no automatic deployment implied.

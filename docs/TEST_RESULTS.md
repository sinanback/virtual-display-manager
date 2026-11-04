# Local verification · 2026-10-31

Verified using Windows PowerShell 5.1 on the development computer. No display-device mutations were performed by these tests.

- Turkish/English translation-key parity and nonempty resource values: passed.
- Language persistence, translated controls and tray menu, activity retranslation: passed.
- Main window visible on launch; controls rendered before the first hardware snapshot: passed.
- First window render observed at approximately 1.3–1.6 seconds from application script entry. This excludes UAC interaction and launcher startup; it is not a guaranteed end-to-end startup time.
- First asynchronous read-only hardware query: approximately 0.5–0.8 seconds. Two physical displays detected on this computer.
- Automatic-policy tests using simulated snapshots: attach, detach, two-sample debounce, unknown connection and device-fault handling: passed. Mutating commands were captured by test doubles rather than executed.
- Close-to-tray, tray restore and explicit exit: passed. The automated lifecycle test bypassed the modal close explanation; its text and event wiring were checked separately.
- Exact packaged bootstrap: parsed application extracted correctly; driver ZIP offset/signature valid; long-lived test child had a zero console handle.
- Normal startup reads a small application prefix rather than converting/extracting the 25 MB driver bundle. ZIP extraction remains deferred to an explicitly confirmed install operation.
- Turkish overview, English overview, activity and guide layouts rendered and visually inspected at the development display scale.

Not verified here: physical cable attach/detach, actual device enable/disable, installation, removal, reboot handling, other computers/Windows terminal configurations, all DPI scales, and third-party redistribution eligibility. Complete RELEASE_CHECKLIST.md before publishing a public release.


## Automatic-switching verification · 2026-11-03

DisplayConfig is the primary detector, with device-identity classification and bounded retries for topology changes. Successful empty native topology is a valid zero, independent of WMI support. Failure of both detectors remains an unknown state, never a zero.

- Windows PowerShell 5.1 live read-only query: one active VDD adapter (`ROOT\DISPLAY\0000`), zero physical monitors, no detection error.
- `tests/verify-detection.ps1`: 14 assertions passed, including empty topology with unsupported WMI, HDMI-reporting VDD exclusion, GPU/USB/internal displays, fallback, dual failures, attach/detach and connection changes immediately before mutation. Mutations were simulated.
- Existing UI/background-policy/lifecycle suite: passed; first render 1.5 seconds and initial read-only query 0.5 seconds in this run.
- Icon fidelity and exact portable bootstrap/ZIP offset/no-console checks: passed.

Actual physical cable manipulation and automatic device disable/enable were not performed during this verification run, to avoid interrupting the current headless remote desktop. Existing installation/removal/reboot and cross-device limitations above still apply.
## Display-presence verification · 2026-11-04

- Live read-only evidence before recovery: DisplayConfig reported one available DisplayPort path, while a successful present-monitor PnP query returned zero monitors. The disabled VDD had device code 22.
- Active paths now require an exact match with a currently present monitor instance. A successful empty presence query means zero monitors; a failed presence query remains unknown. The WMI fallback uses the same presence filter.
- `tests/verify-detection.ps1`: 18 assertions passed, including cached DisplayPort paths, virtual-only presence, mixed stale/present paths and presence-query failure.
- UI/background-policy/lifecycle and portable bootstrap checks: passed. First window render approximately 1.5 seconds; initial query approximately 0.5 seconds.
- The existing VDD was enabled during recovery and Windows reported OK / CM_PROB_NONE. The current application was restarted with automatic monitoring; subsequent live snapshots reported VDD enabled, zero physical monitors and no detection error.
- Actual physical cable manipulation and automatic hardware enable/disable cycles were not performed in this run. The test suite simulates those mutations.
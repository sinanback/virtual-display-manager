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


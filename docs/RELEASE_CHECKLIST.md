# Release checks / Sürüm kontrolleri

Automated checks are read-only with respect to display devices. Complete these physical checks before publishing a release:

- Start the packaged CMD from Explorer with Windows Terminal as the default terminal. Approve UAC. Confirm the main window opens and no persistent Terminal taskbar item remains.
- Switch TR → EN → TR, inspect all tabs and tray menus, restart, and verify the language persists. Confirm Turkish characters render correctly.
- Attach an HDMI/DP monitor: after two stable checks VDD should disable. Disconnect the last physical display: VDD should enable again. Repeat while the window is hidden.
- Test internal laptop panels, USB display adapters, sleep/resume, and multiple monitors. A dummy HDMI plug reporting a monitor is indistinguishable from a physical display to Windows.
- Close the main window, read the explanation, reopen from the tray, then exit completely. Confirm monitoring stops and the existing VDD state is preserved.
- Test install/uninstall/reboot behavior on a disposable test computer. Confirm that logs describe the result and failed/incomplete operations do not report success.
- Test WMI failure/unavailable monitor ancestry: verify no automatic disabling occurs and the warning appears in both languages.
- Test 100%, 125%, 150% and 200% Windows display scaling. Check startup responsiveness and keyboard tab navigation.
- Export activity; review UTC timestamps and technical details. Confirm language settings are saved and corrupt settings do not prevent startup.
- Verify SHA256SUMS.txt after packaging. Review third-party redistribution terms, then add the chosen application LICENSE and repository/release metadata.


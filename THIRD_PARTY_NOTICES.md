# Third-party components

The source package does not include the offline driver bundle or claim ownership of third-party binaries.

- Virtual Display Driver: https://github.com/VirtualDrivers/Virtual-Display-Driver. Use the upstream release and review its licensing, signature, supported Windows versions and redistribution terms.
- Microsoft devcon: Windows Driver Kit tool. Review Microsoft's redistribution terms for the exact binary before publishing it in a release.
- Microsoft Visual C++ Redistributable: review the Microsoft license and distribution requirements for the exact version being bundled.

The current local offline bundle came from the pre-existing project work directory. Its contents have not been re-downloaded or independently license-audited in this change. Source archives deliberately exclude those binary files.

No application-source license is selected automatically. The repository owner should choose and add an appropriate LICENSE before public release.


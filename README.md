# STINGRAY v20 — source and portable distribution

This is the verified STINGRAY v20 command center packaged for transfer in **24,000,000-byte parts**. The application is unchanged from the v20 menu and toolbar correction release. Aircraft, surface traffic, cameras, weather and World Monitor retain their existing integrations and coverage limits.

## Start here

Read **INSTRUCTIONS.txt**, or open **INSTRUCTIONS.html** and print it. Extract **STINGRAY-v20-Start-Here.zip** beside all numbered parts. Run **Join-Portable.cmd**, **Join-Source.cmd** or **Join-Both.cmd**. Complete verified ZIPs appear in `assembled`. Extract those ZIPs before use. The parts are binary slices, not individual ZIP files or 7-Zip volumes.

The manifest `STINGRAY-parts.json` records every part's byte count and SHA-256 checksum, plus each completed archive's checksum. `SHA256SUMS.txt` provides a plain-text list. Hashes detect damaged or incomplete transfers; they are not a publisher signature. The join tool checks every requested part, checks the completed ZIP again, and does not overwrite a different existing file.

## Packages

- **Portable:** prebuilt Windows x64 application, Node runtime, WebView2 loader, retained licenses, corresponding application source, guides, and a desktop launcher. Extract it to a writable folder and run `Launch-STINGRAY.vbs`. WebView2 Runtime must already be installed. Close the window and run `Stop-STINGRAY.cmd` before moving or backing up the folder. Your new profile lives in `STINGRAY/data`; existing installations are not imported automatically.
- **Source-Compiler:** complete corresponding v20 application source in `application`, hosted JA21 compiler, TypeScript 5.9.3 compiler, Node 24.15.0, npm CLI, build wrappers, provenance, and retained licenses. `Compile-JA21.cmd` works offline using the included toolchain. It compiles four STINGRAY modules, four World Monitor modules and 18 design tokens. The precise source profile is documented in `application/ja21/PROFILE.md`.

## Compiler and full build

`Compile-JA21.cmd` generates TypeScript and CSS for the existing host. To verify without regenerating, run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Compile-JA21.ps1 -Check`. The wrapper installs the bundled TypeScript compiler into the source's `node_modules` only when that package is absent. The complete TypeScript CLI is also available as `TypeScript-Compiler.cmd`.

For a full Windows application build, install Python 3.10 or newer on PATH and have the Windows .NET Framework x64 C# compiler available. `Build-Application.cmd` downloads dependencies with both lockfiles, builds the web applications, compiles the native window and assembles a new release under `application/release`. The C# compiler is discovered from Windows; it is not included in this archive. The full build requires internet access and several GB of free disk space. It does not require a global Node or npm installation.

For a prerequisite check, run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Build-Application.ps1 -PreflightOnly`. After dependencies have been installed successfully, `-SkipDependencyInstall` reuses them. The toolchain includes `npm.cmd` beside Node so nested npm build scripts can run. There is no native JA21 VM in the supplied corpora; this package does not claim a complete native-language translation.

## Licenses

**The combined application remains AGPL-3.0-only because it incorporates World Monitor.** The requested Apache 2.0 license applies to the new standalone distribution tools and guides, and to TypeScript under its original license. Read `LICENSE-SCOPE.md`, `NOTICE`, `LICENSE-APACHE-2.0.txt` and `LICENSE-AGPL-3.0.txt`. All application and third-party notices remain included. Do not replace the application's AGPL license with the packaging license.

## Release evidence

`APPLICATION-VERIFICATION.json` records the previously completed v20 checks: 162 regression tests, 37 interface checks, builds and installation checks. `DISTRIBUTION-VERIFICATION.json` beside the download parts records this packaging run's checks. Native graphical rendering was not rerun for this repackaging. Provider credentials and private profiles are not included.

The portable source-download ZIP is the original verified v20 corresponding source (SHA-256 `69751603521fafc14eb53de034ead223b4d40a36ac14c5b24b7b08f9580dbaef`). The source/compiler package preserves all its 7,723 entries unchanged under `application/`; separate packaging tools and compilers are added outside that folder.

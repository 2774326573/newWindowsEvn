# C++ / Qt toolchain inventory

This repository now records a Windows-first toolchain policy and provides a read-only inventory. It does not silently install Visual Studio workloads, switch compiler environments, replace Qt kits, or copy proprietary SDKs.

## Supported profiles

| Profile | Required components | Policy |
| --- | --- | --- |
| `qt5-msvc` | Visual Studio 2022 C++ tools, Windows SDK, Qt 5, CMake, Xmake | Preferred Windows production profile |
| `qt5-mingw` | MinGW-w64 GCC 10+, Qt 5 built for the matching MinGW ABI, CMake, Xmake | Secondary build profile |

Baseline:
- C++20.
- Qt 5 preferred; Qt 5.12.12 is the currently recorded reference version.
- Qt 6 automatic installation is disabled.
- MSVC 2022 and Windows SDK are detected separately.
- OpenCV is optional and discovered through `OpenCV_DIR`, `OPENCV_ROOT`, and common install roots.
- HALCON, camera/PLC/motion SDKs, licensed binaries and license files are not installed, copied or bundled by this manager.

## Inspect the current machine

Run in PowerShell 7:

```powershell
pwsh -NoProfile -File .\scripts\Manage-Toolchain.ps1
pwsh -NoProfile -File .\scripts\Manage-Toolchain.ps1 -Profile qt5-msvc
pwsh -NoProfile -File .\scripts\Manage-Toolchain.ps1 -Profile qt5-mingw
```

The inventory checks:
- Visual Studio 2022 C++ workload via `vswhere` (does not require an initialized Developer Shell).
- Installed Windows SDK versions.
- Qt kits discovered via `qmake` and their `QMAKE_XSPEC`.
- MinGW GCC, CMake, Xmake and OpenCV CMake package configuration.

A found Qt kit does not prove compiler ABI compatibility. Match Qt's compiler kit with MSVC or MinGW and validate the actual project build. MSVC's `cl.exe` is available only after entering a Visual Studio Developer environment.

## Export for migration / offline preparation

```powershell
pwsh -NoProfile -File .\scripts\Manage-Toolchain.ps1 -Mode Export -Output .\offline\toolchain-inventory.json
```

The JSON report records OS/architecture, detected tool versions and paths, and profile gaps. It can contain the computer name and local installation paths; review or redact it before sharing publicly. Review it before migrating to another machine. It is an inventory, not a machine restore script; paths and installed components differ between computers.

Running `scripts/Prepare-Offline.ps1` also saves a toolchain inventory into the offline cache before generating its SHA-256 manifest.

## Next stage

This phase establishes detection and a portable policy. Automated side-by-side compiler switching, project-specific Qt kit resolution, package acquisition and full machine restore are deliberately separate follow-up work. Vendor installers, Qt offline repositories, HALCON and camera/PLC SDK packages must be acquired from authorized sources and handled according to their licenses.

Architecture decision: [C++ / Qt toolchain and offline migration policy](decisions/cpp-toolchain.md).

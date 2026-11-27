# C++ / Qt toolchain and offline migration policy

## Accepted baseline

- C++20.
- Qt 5 preferred; Qt 5.12.12 is the current reference kit.
- Visual Studio 2022 + Windows SDK for the MSVC profile.
- MinGW-w64 GCC 10+ for the MinGW profile.
- CMake and Xmake are first-class build tools.
- OpenCV is detected as an optional project dependency.
- Qt 6 is not installed automatically.

## Profile separation

A Qt kit is compiler-ABI-specific. A Qt kit built for MSVC must not be selected for a MinGW build, or vice versa. The inventory records qmake's `QMAKE_XSPEC` and warns when it does not match the requested profile. It does not switch PATH or initialize a compiler shell.

## Installation ownership

The manager detects and reports tools. It does not silently modify Visual Studio workloads, install Qt kits, change the active compiler, copy SDK binaries, or handle licenses. Those operations require explicit vendor installer choices and project-specific validation.

HALCON, camera/PLC/motion SDKs, proprietary runtime DLLs, license files and credentials are excluded from the public repository and generic offline cache.

## Offline migration

Online preparation exports `offline/toolchain-inventory.json` before generating the SHA-256 cache manifest. The inventory is a source-machine snapshot for comparison, not a restore script. Generic installers already listed in `config/packages.txt` may be cached with WinGet. Qt, Visual Studio workloads and licensed/vendor SDKs must be obtained through authorized vendor channels and staged separately by the operator.

The target machine must be independently inventoried after restore. Never reuse absolute source-machine paths as target configuration.

## Rollout stages

1. Read-only inventory and profile policy (current).
2. Project-aware compiler/Qt kit selection and environment initialization, without global PATH mutation.
3. Explicit package acquisition with version pins and SHA-256 verification.
4. Offline restore with target-machine path resolution and post-restore diagnostics.
5. Project-specific smoke builds for CMake/Xmake and Qt5 MSVC/MinGW.

The current implementation covers stage 1 and inventory export in offline preparation. Later stages require separate tests and should not be represented as already implemented.

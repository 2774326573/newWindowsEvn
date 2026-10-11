# Auto-select the build system of the CURRENT directory; never auto-download dependencies.
function build {
    if (Test-Path -LiteralPath './xmake.lua' -PathType Leaf) {
        if (Get-Command xmake -ErrorAction SilentlyContinue) { & xmake @args }
        else { Write-Warning 'xmake not found. Run Install-Online.ps1 or install Xmake manually.' }
        return
    }
    if (Test-Path -LiteralPath './build/CMakeCache.txt' -PathType Leaf) {
        if (Get-Command cmake -ErrorAction SilentlyContinue) { & cmake --build build @args }
        else { Write-Warning 'CMake not found.' }
        return
    }
    if (Test-Path -LiteralPath './CMakeLists.txt' -PathType Leaf) {
        Write-Warning 'CMake project is not configured. Run: cmake -S . -B build'
        return
    }
    Write-Warning 'No xmake.lua or configured CMake build/ detected in the current folder.'
}

function cmconfig {
    if (-not (Test-Path -LiteralPath './CMakeLists.txt' -PathType Leaf)) {
        Write-Warning 'No CMakeLists.txt in current folder.'
        return
    }
    if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
        Write-Warning 'CMake not found.'
        return
    }
    & cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON @args
}

function cmtest {
    if (-not (Get-Command ctest -ErrorAction SilentlyContinue)) {
        Write-Warning 'CTest not found.'
        return
    }
    & ctest --test-dir build --output-on-failure @args
}

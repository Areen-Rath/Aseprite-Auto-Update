Add-Type -AssemblyName PresentationFramework

$PSNativeCommandUseErrorActionPreference = $true

<#
    CMake, Ninja, Git and GitHub CLI must be installed and added
    to the system PATH for this script to work properly.
#>

<#
    Set the paths to Aseprite, Skia, and Visual Studio Developer Command Prompt.
    In case of a different installation path or version, please change
    the paths below accordingly.
    For Visual Studio 2022, use the following path instead:
    C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\VsDevCmd.bat
#>
$asepritePath = "C:\aseprite"
$skiaPath = "C:\deps\skia"
$VSPath = "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\Launch-VsDevShell.ps1"

$env:GIT_REDIRECT_STDERR = '2>&1'

Set-Location $asepritePath

$current = git describe --tags
if ($LASTEXITCODE -ne 0) {
    Write-Output "Something went wrong while checking the current version of Aseprite. Please check the output above for more information."
    pause
    exit
}

$latest = gh release view --json tagName --jq ".tagName"
if ($LASTEXITCODE -ne 0) {
    Write-Output "Something went wrong while checking for latest version on GitHub. Please check the output above for more information."
    pause
    exit
}

if ($current -eq $latest) {
    exit
}

$choice = [System.Windows.MessageBox]::Show("A newer version of Aseprite is available. Update?`nNOTE: This will close any instance of Aseprite.", "Confirm Action", "YesNo", "Question")
if ($choice -eq "No") {
    & "$asepritePath\build\bin\aseprite.exe"
    exit
}
Get-Process -Name "aseprite" -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Output "Updating Aseprite..."
Write-Output "`nPulling latest changes from GitHub..."
git reset --hard HEAD
git checkout main
git pull
if ($LASTEXITCODE -ne 0) {
    Write-Output "Something went wrong while pulling the latest changes from GitHub. Please check the output above for more information."
    pause
    exit
}

Write-Output
Write-Output "`nUpdating submodules..."
git submodule update --init --recursive
if ($LASTEXITCODE -ne 0) {
    Write-Output "Something went wrong while pulling the latest changes from GitHub. Please check the output above for more information."
    pause
    exit
}

Write-Output "`nOpening Visual Studio Developer Command Prompt..."
& $VSPath -Arch amd64 -HostArch amd64
if ($LASTEXITCODE -ne 0) {
    Write-Output "Something went wrong while opening Visual Studio Developer Command Prompt. Please check the output above for more information."
    pause
    exit
}

Write-Output "`nCleaning up build directory..."
Remove-Item -Path "$asepritePath\build\*" -Force -Recurse
Set-Location $asepritePath\build

$version = ($latest -replace "v") + "-dev"
Write-Output "Changing version in CMakeLists.txt to $version..."
$lines = Get-Content -Path "$asepritePath\src\ver\CMakeLists.txt"
$lines[4] = "set(VERSION `"$version`")"
$lines | Set-Content -Path "$asepritePath\src\ver\CMakeLists.txt"

Write-Output "`nConfiguring the build with CMake..."
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DLAF_BACKEND=skia -DSKIA_DIR="$skiaPath" -DSKIA_LIBRARY_DIR="$skiaPath\out\Release-x64" -DSKIA_LIBRARY="$skiaPath\out\Release-x64\skia.lib" -G Ninja ..
Write-Progress -Activity "CMake Configuration" -Completed
if ($LASTEXITCODE -ne 0) {
    Write-Output "Something went wrong while configuring the build with CMake. Please check the output above for more information."
    pause
    exit
}

Write-Output "`nBuilding Aseprite with Ninja..."
ninja aseprite
if ($LASTEXITCODE -ne 0) {
    Write-Output "Something went wrong while building Aseprite. Please check the output above for more information."
    pause
    exit
}

(New-Object -ComObject Shell.Application).ShellExecute("$asepritePath\build\bin\aseprite.exe", "", "", "", 4)

exit
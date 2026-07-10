Add-Type -AssemblyName PresentationFramework

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
$VSPath = "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\VsDevCmd.bat"

Set-Location $asepritePath
& "$asepritePath\build\bin\aseprite.exe"

try {
    $current = git describe --tags
    $latest = gh release view --json tagName --jq ".tagName"
    if ($current -eq $latest) {
        exit
    }
    $choice = [System.Windows.MessageBox]::Show("A newer version of Aseprite is avilable. Update?", "Confirm Action", "YesNo", "Question")
    if ($choice -eq "No") {
        exit
    }
    try {
        Write-Output "Updating Aseprite..."
        Write-Output "Pulling latest changes from GitHub..."
        git pull
        Write-Output "Updating Submodules..."
        git submodule update --init --recursive
        Write-Output "Checking out the latest stable release..."
        git checkout $latest
        Write-Output "Building Aseprite..."
        & $VSPath -arch=x64
        Remove-Item -Path "$asepritePath\build\*"
        Set-Location $asepritePath\build
        cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DLAF_BACKEND=skia -DSKIA_DIR="$skiaPath" -DSKIA_LIBRARY_DIR="$skiaPath\out\Release-x64" -DSKIA_LIBRARY="$skiaPath\out\Release-x64\skia.lib" -G Ninja ..
        ninja aseprite
        Write-Output "Aseprite updated successfully!"
        Write-Output "You are now on version $latest."
        Write-Output "Please close Aseprite and restart it to apply the update."
        pause
    } catch {
        Write-Output "Aseprite build failed."
        Write-Output "Please check the output above for any errors."
        pause
    }
} catch {
    exit
}
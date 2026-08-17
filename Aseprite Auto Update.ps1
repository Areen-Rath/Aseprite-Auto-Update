Add-Type -AssemblyName System.Windows.Forms, System.Drawing, Microsoft.VisualBasic

$MethodDefinition = @'
    [DllImport("shcore.dll")]
    public static extern int SetProcessDpiAwareness(int value);
'@

Add-Type -MemberDefinition $MethodDefinition -Name 'DpiUtil' -Namespace 'Win32' -PassThru | Out-Null
[Win32.DpiUtil]::SetProcessDpiAwareness(2) | Out-Null

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

$env:GIT_REDIRECT_STDERR = '2>&1'

Set-Location $asepritePath

function Open-Aseprite {
    try {
        & "$asepritePath\build\bin\aseprite.exe"
    } catch {
        [Microsoft.VisualBasic.Interaction]::MsgBox(
            "Failed to open Aseprite. Please ensure that Aseprite is properly installed and that the path to Aseprite is correct.",
            "OKOnly,Critical",
            "Failed to Open Aseprite"
        ) | Out-Null
    }
}

$AnchorForm = New-Object System.Windows.Forms.Form
$AnchorForm.TopMost = $true
$AnchorForm.Text = "Aseprite+"
$AnchorForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
$AnchorForm.StartPosition = 'CenterScreen'
$AnchorForm.WindowState = 'Minimized'
$AnchorForm.Show()

$ParentHandle = New-Object System.Windows.Forms.NativeWindow
$ParentHandle.AssignHandle($AnchorForm.Handle)

$current = git describe --tags

$latest = gh release view --json tagName --jq ".tagName"
if ($current -eq $latest) {
    Open-Aseprite
    $AnchorForm.Dispose()
    exit
}

$choice = [Microsoft.VisualBasic.Interaction]::MsgBox(
    "A newer version of Aseprite is available. Update?`nNOTE: This will close any instance of Aseprite.",
    "YesNo,Question",
    "Update Aseprite?"
)
if ($choice -eq "No") {
    Open-Aseprite
    $AnchorForm.Dispose()
    exit
}

Get-Process -Name "aseprite" -ErrorAction SilentlyContinue | Stop-Process -Force

$AnchorForm.Dispose()

$updateScript = {
    $skiaPath = "C:\deps\skia"
    $VSPath = "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\Launch-VsDevShell.ps1"

    Write-Output "Updating Aseprite..."
    Write-Output "`nPulling latest changes from GitHub..."
    git reset --hard origin/main
    git checkout main
    git pull
    if ($LASTEXITCODE -ne 0) {
        Write-Output "Something went wrong while pulling the latest changes from GitHub. Please check the output above for more information."
        pause
        exit
    }

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
    try {
        Remove-Item -Path "build\*" -Force -Recurse -ErrorAction Stop
    } catch {
        Write-Output "Build directory does not exist. Creating build directory..."
        New-Item -ItemType Directory -Path "build"
    }

    $current = git describe --tags
    $version = $current + "-dev"
    Write-Output "Changing version in CMakeLists.txt to $version..."
    $lines = Get-Content -Path "src\ver\CMakeLists.txt"
    $lines[4] = "set(VERSION `"$version`")"
    $lines | Set-Content -Path "src\ver\CMakeLists.txt"

    Write-Output "Committing versioning changes..."
    git add .
    git commit -m "Aseprite+ $version"
    git tag -f -a "$current" -m "Aseprite+ $version"

    Set-Location "build"

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

    (New-Object -ComObject Shell.Application).ShellExecute("build\bin\aseprite.exe", "", "", "", 4)
}

$encodedCommand = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($updateScript.ToString()))

Start-Process powershell -ArgumentList "-EncodedCommand", $encodedCommand

exit
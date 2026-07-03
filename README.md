# Aseprite Auto Update

Aseprite Auto Update is an app that automatically checks for the latest stable release for Aseprite and updates it if needed.

**Note:** The app is only available on Windows and targets 64-bit devices.

## Dependencies

Dependencies for Aseprite:
* Windows 11
* Visual Studio Community 2026 (we don't support MinGW)
* The Desktop development with C++ item + Windows SDK from Visual Studio installer
* The latest version of CMake
* Ninja build system
* A compiled version of a supported branch of the Skia library

Dependencies for the App:
* Git for Windows
* Github CLI

The app assumes that:
* CMake, Ninja, Git and GitHub CLI are added to PATH.
* Visual Studio 2026 is being used.
* The compiled version of Skia library is saved in `C:\deps\skia`.
* Aseprite folder location is `C:\aseprite`.

In case of any discrepancy, please refer to the comments in the PowerShell file for steps to address them.

## How It Works

Under the hood, the app is simply a PowerShell script that has been converted to an executable file using the `ps2exe` module and given the Aseprite logo. The PowerShell script opens Aseprite and checks for any updates by comparing the current version of the local Aseprite Git repo and the latest release of the GitHub repo. In case of a newer version, a dialog box will ask the user whether to update or not, and the user can decide accordingly. The user can continue working while updating Aseprite. If Aseprite is up-to-date, the PowerShell script will exit and the user can continue doing their work.

In case of a poor/no Internet connection, the script will exit automatically without notification. Success/failure of an update will be shown at the end in the PowerShell window.

The PowerShell window will be visible for the entirety of the duration of the script run to ensure transparency and to enable the user to check the status of the update.
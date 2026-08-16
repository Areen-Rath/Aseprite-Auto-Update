# Aseprite Auto Update

Aseprite Auto Update is an app that automatically checks for the latest stable release for Aseprite and updates it if needed. This is for Aseprite users who have built Aseprite rather than bought it.

This app automatically opens Aseprite after checking for updates and updating (in case of a new version), so it serves as an add-on to Aseprite which the user can open instead of simply opening Aseprite.

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

The app is a PowerShell script under the hood that has been built into an app using PS2EXE. The PowerShell script checks for any updates by comparing the current version of the local Aseprite Git repo and the latest release of the GitHub repo. In case of a newer version, a dialog box will ask the user whether to update or not, and the user can decide accordingly. If Aseprite is up-to-date, the PowerShell script will open Aseprite normally and exit.

Success/failure of an update will be shown at the end in the PowerShell window.

The app will silently check for updates. During updation, the PowerShell window will be visible for the entirety of the duration of the updation to ensure transparency and to enable the user to check the status of the update.
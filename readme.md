# PPKG
PPKG is a package manager for Windows.

- [Documentation](docs/index.md)

## Features
- Install, uninstall and update packages.
- Completely transactional.
- Supports http, https and sftp.
- Supports private package repositories.
- Integrates with Powershell.
- Easy to create package manifests.
- (For package maintainers) Provides helpers for updating package manifests that use github.

## Requirements
You will need Powershell v7.0.0 or above. Windows Powershell (Powershell v 5.x and earlier) is not supported.

To check your Powershell version, run:
```powershell
$PSVersionTable.PSVersion.ToString()
```

If your version is older than 7.0.0, follow the instructions from [this page](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows).

## Getting Started
- Download the release archive (`ppkg-x32.zip` or `ppkg-x64.zip`) from the [releases page](https://github.com/insomnimus/ppkg/releases) ([here's the latest release](https://github.com/insomnimus/ppkg/releases/latest)).
- Extract it to some location with the `ppkg` directory name (suggestion is to put somewhere in `$env:PSMODULEPATH` for automatic loading).
- If you extracted to somewhere outside `$env:PSMODULEPATH`, add `import-module -disableNameChecking D:/path/to/ppkg/ppkg.psd1` in your Powershell profile.
- Restart Powershell.
- Register a repository: `ppkg-add-repo insomnia https://github.com/insomnimus/ppkg-repo`.

More documentation is available [here](docs/getting-started.md).

For more on Powershell profiles, see [this page from MSDN](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7.3).

## Build From Source
Building from source is optional but you can do it if you wish.

You will need:
- `dotnet` cli with DotNet 7 SDK enabled
- Powershell v7.0.0 or newer

```powershell
# Clone the repository with git:
git clone https://github.com/insomnimus/ppkg
cd ppkg
# Run the build script:
./build.ps1 -publish
# The module will be created into ./module
# You can move this directory to a suitable place, all the files inside it are required
```

## About AlphaFS
This project uses the [AlphaFS](https://github.com/alphaleonis/AlphaFS) library for transactional filesystem operations.
Because the latest version on NuGet has some bugs and is incompatible with Dotnet Standard, the source code for AlphaFS is vendored in this project. You can find its license file at [AlphaFS/LICENSE.md](AlphaFS/LICENSE.md).

# Getting Started
- Download the release archive (`ppkg-x32.zip` or `ppkg-x64.zip`) from the [releases page](https://github.com/insomnimus/ppkg/releases) ([here's the latest release](https://github.com/insomnimus/ppkg/releases/latest)).
- Extract it to some location with the `ppkg` directory name (suggestion is to put somewhere in `$env:PSMODULEPATH` for automatic loading).
- If you extracted to somewhere outside `$env:PSMODULEPATH`, add `import-module -disableNameChecking D:/path/to/ppkg/ppkg.psd1` in your Powershell profile.
- Restart Powershell.

PPKG will install packages in the directory specified by the `PPKG_ROOT` environment variable if it exists; if it doesn't, the default is `%SYSTEMDRIVE%/ppkg`.
Make sure that the `bin` directory of this path is in your `PATH`.
For example, if you set the `PPKG_ROOT` environment variable, add `%PPKG_ROOT%/bin` to your `PATH`.

## Adding Repositories
By default, PPKG does not install any repository. You'll have to add the ones you want.

PPKG repositories are simply git repositories with any number of package manifests in `.json` files.
- For more on package manifests, see the [Package Manifests page](package-manifests.md).
- For more on maintaining a package repository, see the [Maintaining A Package Repository page](maintaining-a-package-repository.md).

You can easily create your own custom repository but here we'll install Insomnia's (the author of PPKG) repository for his own apps.

The cmdlet to use is `ppkg-add-repo`.
It takes 2 arguments, the first one being the local name of the repo and the second, the git clone URL.

The repository we'll install is located at [github.com/insomnimus/ppkg-repo](https://github.com/insomnimus/ppkg-repo).

Here's the command to install:
```powershell
ppkg-add-repo insomnia https://github.com/insomnimus/ppkg-repo
```

## Viewing Information On Packages
Let's get some information about the `mars` package from Insomnia's repository (which we just registered above!).
```powershell
PS> ppkg-info mars
name        : mars
repo        : insomnia
version     : 0.13.0
description : A github flavored markdown to html converter
homepage    : https://github.com/insomnimus/mars
license     : MIT
bin         : mars.exe
installed   : False
```

We can visit the homepage of a package by using the `-online` flag of `ppkg-info`.
```powershell
# This will open the package's homepage on your default browser
ppkg-info mars -online
```

## Installing A Package
Let's install the `mars` package from above.
This is very straightforward, as it should be. The command is...
```powershell
ppkg-install mars
```

This will download the package using `curl`, shipped with recent versions of Windows 10 and 11 by default.
After the download, it will be unarchived using 7zip, which is bundled with PPKG unless you've built from source, in which case a system-wide installation of 7zip is used, if available.

The executables are put in separate installation directories. A shim that proxies to the executable will be created in the `bin` directory of the PPKG root. This directory should be put in the `PATH` environment variable.

With that, the `mars.exe` executable is installed!

## Updating Packages
Package updates are done with the `ppkg-update` cmdlet.
The cmdlet accepts 0 or more package names and updates them. You can use wildcard patterns such as `*`.

If no package name is given, only the repositories are updated.

```powershell
# Only update repositories:
ppkg-update
# Update repositories and then the mars package:
ppkg-update mars
```

## Uninstalling Packages
Package uninstallations are done with the `ppkg-remove` cmdlet.
```powershell
# Uninstall mars
ppkg-remove mars
```

By default, the contents of packages are not deleted from the filesystem; only the shims pointing to it are removed to not have to re-download if you decide to install again.
To force a clean removal, use the `-full` flag:
```powershell
ppkg-remove mars -full
```

Alternatively you can run the `ppkg-clean` cmdlet anytime you want to clean up package caches.

## Searching Packages
You can search for packages using the `ppkg-search` cmdlet.
You can search for package names, names of repositories, binary names and package descriptions.

Or you can use custom logic to filter out packages. Like all PPKG cmdlets, this cmdlet returns Powershell objects you can further process.

```powershell
# search for ffmpeg
ppkg-search ffmpeg
# Search for ffprobe.exe
ppkg-search -bin ffprobe.exe
# Get all packages and filter the results with a script block
ppkg-search * | where-object {
	$_.repo -like "*-dev" -and
	$_.license -eq "MIT" -and
	$_.bin.count -gt 1 -and
	$null -ne $_.x32
}

# Get all packages with sftp URL's
ppkg-search * | where-object {
	($_.x32 -and $_.x32.url -like "sftp://*") -or
	($_.x64 -and $_.x64.url -like "sftp://")
}
```

## Getting Installed Packages
You can use the `ppkg-list` cmdlet to get the list of installed packages.
It optionally lets you limit the results to specified repositories or packages matching a wildcard pattern.

```powershell
# Get all installed packages
ppkg-list
# Get all installed packages from the `insomnia` repository
ppkg-list -repo insomnia
# Get installed packages that match a wildcard pattern
ppkg-list cargo-*
```

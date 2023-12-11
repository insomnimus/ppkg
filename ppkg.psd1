@{
	RootModule = "ppkg.psm1"
	ModuleVersion = "0.3.0"
	GUID = "4f750862-10bd-4ad2-873f-da4141c81440"
	Author = "Taylan Gökkaya"
	Copyright = "MIT License Copyright (c) 2023 Taylan Gökkaya <insomnimus@proton.me>"
	Description = "A transactional package manager"
	PowerShellVersion = "7.2.0"

	RequiredAssemblies = @("libdll/AlphaFS.dll", "libdll/PPKG.dll")
	FormatsToProcess = @("format/InstallInfo.format.ps1xml", "format/Package.format.ps1xml")

	NestedModules = @(
		"completions.ps1"
		# Lib
		"lib/version.ps1"
		"lib/assert.ps1"
		"lib/bytes.ps1"
		"lib/download.ps1"
		"lib/fsops.ps1"
		"lib/logging.ps1"
		"lib/package.ps1"
		"lib/shims.ps1"
		"lib/utility.ps1"
		# Commands
		"cmd/ppkg-add-repo.ps1", "cmd/ppkg-clean.ps1"
		"cmd/ppkg-info.ps1", "cmd/ppkg-install.ps1"
		"cmd/ppkg-list.ps1", "cmd/ppkg-remove.ps1"
		"cmd/ppkg-search.ps1", "cmd/ppkg-update.ps1"
		"cmd/ppkg-where.ps1", "cmd/update-manifest.ps1"
	)

	FunctionsToExport = @(
		"ppkg-add-repo"
		"ppkg-clean", "ppkg-info"
		"ppkg-install", "ppkg-list"
		"ppkg-remove", "ppkg-search"
		"ppkg-update", "ppkg-where"
		"Update-PPKGManifest"
	)
	CmdletsToExport = @()
	VariablesToExport = @()
	AliasesToExport = @()

	FileList = @()

	# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{
		PSData = @{
			# Tags applied to this module. These help with module discovery in online galleries.
			# Tags = @()
			# LicenseUri = ''
			# A URL to the main website for this project.
			# ProjectUri = ""
			# IconUri = ''
			# Prerelease string of this module
			# Prerelease = ""

			# Flag to indicate whether the module requires explicit user acceptance for install/update/save
			# RequireLicenseAcceptance = $false

			# External dependent modules of this module
			# ExternalModuleDependencies = @()
		}
	}

	# HelpInfoURI = ''
	# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
	# DefaultCommandPrefix = ''
}

function ppkg-info {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, HelpMessage = "Name of the package")]
		[string] $package,
		[Parameter(HelpMessage = "The repository the package should be searched in")]
		[string] $repo
	)

	$ErrorActionPreference = "stop"
	$query = [WildcardPattern]::escape($package)
	$packages = script::ppkg-search -package $query -repo:$repo

	if($packages.count -eq 0) {
		if($repo) {
			err "no package ``$package`` found in repository ``$repo``"
		} else {
			err "could not find the package ``$package`` in any of the installed repositories"
		}
	}

	if($packages.count -gt 1) {
		warn "more than one package with the name ``$package`` exists in the repositories $($packages.repo -join ", "); showing the one in the repository $($packages[0].repo)"
	}

	[PackageDisplay] $packages[0]
}

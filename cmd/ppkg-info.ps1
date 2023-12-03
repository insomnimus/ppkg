function ppkg-info {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, HelpMessage = "Name of the package")]
		[string] $package,
		[Parameter(HelpMessage = "The repository the package should be searched in")]
		[string] $repo,
		[Parameter(HelpMessage = "Open the package homepage with the default web browser")]
		[switch] $online
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

	$p = $packages[0]

	if($online) {
		if(-not $p.homepage) {
			err "the package $p does not specify a homepage"
		} elseif($p.homepage -notmatch "^https?://") {
			err "the homepage URL for {0} isn't http or https; it is not safe to try opening with the web browser: {1}" $p.name $p.homepage
		} else {
			say "opening {0} with the default browser" $p.homepage
			start-process $p.homepage
		}
		return
	}

	[PackageDisplay] $packages[0]
}

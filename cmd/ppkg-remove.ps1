function :ppkg-remove {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, HelpMessage = "Names of packages to uninstall", ParameterSetName = "noglob")]
		[string[]] $package,

		[Parameter(HelpMessage = "Uninstall packages matching the pattern")]
		[switch] $glob,

		[Parameter(HelpMessage = "Do not prompt for confirmation")]
		[switch] $yes,
		[Parameter(HelpMessage = "Do not leave behind existing files for caching")]
		[switch] $full
	)

	$ErrorActionPreference = "stop"
	$query = $glob ? $package : ($package | foreach-object { [WildcardPattern]::escape($_) })
	$packages = script::ppkg-list $query

	assert $packages.count -ne 0 "No installed package matched the given query"

	info "removing packages: $($packages.name -join ", ")"
	if(!$yes -and -not (script::prompt "proceed with uninstallation?")) {
		info "cancelled"
		return
	}

	$scope, $tx = script::new-tx
	try {
		foreach($pkg in $packages) {
			info "removing $($pkg.name)"
			$target = $pkg.InstallDir()
			$latest = join-path (split-path $target) "latest"
			$man = $pkg.InstalledManifestPath()
			$shims = $pkg.BinNames() | foreach-object { join-path $script:settings.bin $_ }
			# Check if any of the shims are currently running
			$running = get-process | where-object Path -in $shims
			if($running.count -ne 0) {
				err "can't remove $pkg because the following executables are currently running:`n$($running | join-string -separator "`n" {
			"pid $($_.pid) - $($_.path)"
		})"
			}

			info "removing shims"
			$shims `
			| where-object { script::exists $_ -tx $tx } `
			| script::rm -tx $tx

			info "removing install record"
			script::rm -lp $man -tx $tx
			info "unlinking {0}/latest" $pkg.name
			script::rm -lp $latest -tx $tx

			if($full) {
				info "removing cached files from $pkg"
				script::rm -lp $target -tx $tx -recurse
				$cachedManifest = "$target.json"
				if(script::exists $cachedManifest -tx $tx) {
					script::rm -lp $cachedManifest -tx $tx
				}
			}

			info "removed $pkg"
		}

		info "completing transaction"
		$scope.complete()
		info "successfully removed $($packages.name -join ", ")"
	} catch {
		err "failed to complete transaction: $_`n`nprevious operations are unrolled"
	} finally {
		$scope.dispose()
		$scope = $null
	}
}

function ppkg-remove {
	[CmdletBinding(DefaultParameterSetName = "literal")]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, HelpMessage = "Names of packages to uninstall", ParameterSetName = "noglob")]
		[string[]] $package,

		[Parameter(HelpMessage = "Uninstall packages matching the pattern")]
		[switch] $glob,

		[Parameter(HelpMessage = "Do not prompt for confirmation")]
		[switch] $yes,
		[Parameter(HelpMessage = "Do not leave behind existing files for caching")]
		[switch] $full
	)

	try {
		script::ppkg-remove -ea stop @PSBoundParameters
	} catch {
		write-error "error: $_"
	}
}

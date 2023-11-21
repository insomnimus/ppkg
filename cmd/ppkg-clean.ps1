function ppkg-clean {
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ValueFromRemainingArguments, HelpMessage = "Packages to clean (accepts glob)")]
		[string[]] $package,
		[Parameter(HelpMessage = "Clean packages in the provided repositories only")]
		[string[]] $repo,

		[Parameter(HelpMessage = "Do not leave the latest version in the cache")]
		[switch] $full,
		[Parameter(HelpMessage = "Do not remove temporary files")]
		[switch] $keepTemporary,
		[Parameter(HelpMessage = "Remove log files")]
		[switch] $logs
	)

	try {
		script::ppkg-clean -ea stop @PSBoundParameters
	} catch {
		err "error: $_"
	}
}

function :ppkg-clean {
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ValueFromRemainingArguments, HelpMessage = "Packages to clean (accepts glob)")]
		[string[]] $package,
		[Parameter(HelpMessage = "Clean packages in the provided repositories only")]
		[string[]] $repo,

		[Parameter(HelpMessage = "Do not leave the latest version in the cache")]
		[switch] $full,
		[Parameter(HelpMessage = "Do not remove temporary files")]
		[switch] $keepTemporary,
		[Parameter(HelpMessage = "Remove log files")]
		[switch] $logs
	)

	$ErrorActionPreference = "stop"

	# Validate that -repo contains valid values
	foreach($r in $repo) {
		if(script::exists -directory -not $r) {
			err "${r} is not a known repository"
		}
	}

	$found = [Ordered] @{}
	info "searching packages"
	$repos = Get-ChildItem -directory -lp $script:settings.apps `
	| where-object { !$repo -or $_.name -in $repo } `
	| foreach-object {
		$name = $_.name
		$apps = Get-ChildItem -lp $_ -directory `
		| where-object {
			if(!$package) { return $true }
			foreach($p in $package) {
				if($_.name -like $p -or $_.name -eq $p) {
					$found[$p] = $true
					return $true
				}
			}
			$false
		}

		[PSCustomObject] @{
			repo = $name
			apps = $apps
		}
	}

	$installed = script::ppkg-list -repo:$repo
	# Validate that all packages specified are found
	foreach($p in $package) {
		if(!$found[$p]) {
			err "the query ${p} did not match any installed/cached package"
		}
	}

	$toRemove = $repos | foreach-object {
		$r = $_.repo
		$_.apps | foreach-object {
			$name = $_.name
			$pkg = $installed | where-object { $_.repo -eq $r -and $_.name -eq $name }
			$isInstalled = $null -ne $pkg -and $pkg.IsInstalled($false)
			$keep = $full ? 0 : 1

			# Do not use the "?*.?*.?*" pattern in -filter; native API treats ? as "0 or 1".
			Get-ChildItem -directory -lp $_ `
			| where-object name -clike "?*.?*.?*" `
			| foreach-object {
				$path = $_
				try {
					$version = [PVersion] $path.name
					[PSCustomObject] @{
						path = $path
						name = "$name@$version"
						version = $version
					}
				} catch {
					warn "unrecognized folder at $path"
				}
			} `
			| where-object {
				# don't remove if it's active (currently installed).
				!$isInstalled -or $_.version -ne $pkg.version
			}
			| sort-object -descending -property version `
			| select-object -skip $keep `
			| foreach-object {
				[PSCustomObject] @{ name = $_.name; path = $_.path }
				# Also remove the cached manifest if it exists
				if($p = get-item -ea ignore -lp "$($_.path).json") {
					[PSCustomObject] @{ name = ""; path = $p }
				}
			}
		}
	}

	if($toRemove.count -eq 0 -and -not $logs -and $noTemporary) {
		info "nothing to clean up"
		return
	}

	$freed = [Bytes]::new(0)
	$scope, $tx = script::new-tx
	foreach($p in $toRemove) {
		if($p.name) {
			info "removing {0} (outdated)" $p.name
		}
		$freed += script::size -ea ignore $p.path
		script::rm -rf $p.path -tx $tx
	}

	if($logs) {
		info "cleaning logs"
		$freed += script::size $script:settings.logs
		script::empty-dir $script:settings.logs -tx $tx
	}
	if(!$noTemporary) {
		info "cleaning temporary files"
		$freed += script::size $script:settings.tmp
		script::empty-dir $script:settings.tmp -tx $tx
	}

	info "commiting transaction"
	try {
		$scope.complete()
		info "freed $freed of disk space"
	} catch {
		err "failed to complete transaction: $_"
	} finally {
		$scope.dispose()
		$scope = $null
	}
}

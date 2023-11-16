function ppkg-update {
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ValueFromRemainingArguments, HelpMessage = "Name of the packages to update (accepts glob)")]
		[string[]] $package
	)

	try {
		script::ppkg-update -ea stop @PSBoundParameters
	} catch {
		write-error "error: $_"
	}
}

function :ppkg-update {
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ValueFromRemainingArguments, HelpMessage = "Name of the packages to update (accepts glob)")]
		[string[]] $package
	)

	$ErrorActionPreference = "stop"
	$hasStar = $package -ccontains "*"

	# Update repositories
	$repos = $script:settings.GetRepos($repo)
	if($repos.count -eq 0) {
		write-warning "no repository is registered"
		return
	}
	foreach($r in $repos) {
		info "updating repository $r"
		try {
			if($r.update()) {
				info "successfully updated $r"
			} else {
				info "`tno changes"
			}
		} catch {
			err "error updating ${r}: $_"
			return
		}
	}

	$installed = script::ppkg-list -repo:$repo
	$toUpdate = [Collections.Generic.SortedDictionary[string, InstallInfo]]::new()
	foreach($p in $package) {
		$xs = $installed | where-object {
			$_.name -like $p -or $_.name -eq $p
		}
		assert $xs.count -ne 0 "${p}: no package matched the pattern"

		foreach($pkg in $xs) {
			$key = "{0}/{1}" -f $pkg.repo, $pkg.name
			if(!$toUpdate.TryGetValue($key, [ref] $null)) {
				$toUpdate.Add($key, $pkg)
			}
		}
	}

	$updates = $toUpdate.values | foreach-object {
		$path = join-path $script:settings.repos $_.repo "$($_.name).json"
		if(script::exists $path) {
			$current = $_
			try {
				$new = [Package]::ParseFile($path, $_.repo)
				[PSCustomObject] @{ old = $current; new = $new }
			} catch {
				warn "error parsing new package manifest for $($current.repo)/$($current.name): $_"
			}
		} else {
			warn "can't update ${_}: the repository $($_.repo) no longer contains this package"
		}
	} `
	| where-object {
		if($_.new.version -gt $_.old.version) {
			$_
		} elseif(!$hasStar) {
			info "$($_.old): already on latest"
		}
	}

	if($updates.count -eq 0) {
		info "nothing to do"
		return
	}
	info "updating $(script::plural $updates.count package)"

	foreach($x in $updates) {
		$name = $x.old.name

		try {
			$oldBins = $x.old.BinNames()
			$newBins = $x.new.BinNames()
			$removedBins = $oldBins | where-object { $_ -notin $newBins }
			$addedBins = $newBins | where-object { $_ -notin $oldBins }

			# Check for conflicts
			$conflicts = $addedBins | script::shim::conflicts
			if($conflicts.count -ne 0) {
				err "cannot update ${name}: binary name conflicts: $($conflicts -join ", ")"
			}
			$running = $removedBins | script::shim::is-running
			if($running.count -ne 0) {
				err "cannot update ${name}: following $(script::plural $running.count process processes) must be terminated: $($running -join ", ")"
			}

			# Download the new version
			$new = $x.new
			$old = $x.old

			$res = script::resolve-arch $new -override:$old.archOverride
			$file = ""
			script::download $new $res -out ([ref] $file)
			$files = script::extract $file -selectFiles:$res.files

			$target = $new.InstallDir()
			$cachedManifest = "$target.json"

			$scope, $tx = script::new-tx
			# Move the files to the apps directory
			script::empty-dir $target -tx $tx
			trace "moving downloaded files to $target"
			script::mv -lp $files $target -tx $tx

			info "linking $new/latest"
			$latest = join-path (split-path $target) "latest"
			if(script::exists $latest -tx $tx) {
				script::rm -lp $latest -tx $tx
			}
			script::ln -junction -path $latest -pointsTo $target -tx $tx

			# Install shims
			$bins = $new.bin | foreach-object {
				$path = join-path $latest $_
				if(script::exists -not $path -tx $tx) {
					err "package manifest error: package $new declares a binary '$_' however it does not exist"
				}
				$path
			}

			$bins | script::shim::write -tx $tx

			info "copying metadata to the install directory"
			$installPath = $new.InstalledManifestPath()
			$cachedManifestPath = $new.GetCacheManifestPath()
			split-path $installPath | script::ensure-dir -tx $tx

			trace "creating install record"
			$md = $new.CreateInstallInfo($old.archOverride).Json()
			script::write-file -path $installPath -data $md -tx $tx
			script::write-file -path $cachedManifestPath -data $md -tx $tx

			try {
				info "completing transaction"
				$scope.complete()
				info "successfully updated $($new.name) $($old.version) -> $($new.version)"
			} catch {
				err "failed to complete transaction: $_"
			} finally {
				$scope.dispose()
				$scope = $null
			}
		} catch {
			err "failed to update ${name}: $_"
		}
	}
}

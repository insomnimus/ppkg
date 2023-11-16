function ppkg-install {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, HelpMessage = "Name of the packages to install")]
		[string[]] $package,
		[Parameter(HelpMessage = "Specify a repository")]
		[string] $repo,

		[Parameter(HelpMessage = "The architecture to install for")]
		[Arch] $arch
	)

	try {
		script::ppkg-install -ea stop @PSBoundParameters
	} catch {
		write-error "error: $_"
	}
}

function :ppkg-install {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, HelpMessage = "Name of the packages to install")]
		[string[]] $package,
		[Parameter(HelpMessage = "Specify a repository")]
		[string] $repo,

		[Parameter(HelpMessage = "The architecture to install for")]
		[Arch] $arch
	)

	$ErrorActionPreference = "stop"
	$query = $package | foreach-object { [WildcardPattern]::escape($_) }

	info "searching package repositories"
	$packages = script::ppkg-search -repo:$repo -wa ignore $query
	assert $packages.count -ne 0 "No packages found matching $package"

	$packages = $packages | foreach-object {
		# filter out already installed packages
		$installPath = join-path $script:settings.installed $_.repo "$($_.name).json"
		if(test-path -lp $installPath) {
			write-warning "skipping $($_.name) (already installed)"
		} elseif($arch -eq "x32" -and $null -eq $_.x32) {
			err "${_}: no x32 binary available"
		} elseif($arch -eq "x64" -and $null -eq $_.x64) {
			err "${_}: no x64 binary available; but an x32 binary exists"
		} else {
			$_
		}
	}

	if($packages.count -eq 0) {
		write-warning "no package to install"
		return
	}

	foreach($pkg in $packages) {
		info "installing $($pkg.name)@$($pkg.version)"
		foreach($bin in $pkg.BinNames()) {
			if(join-path $script:settings.bin $bin | test-path) {
				err "binary name conflict: $($pkg.name) installs executable $bin but it already exists"
			}
		}

		$target = $pkg.InstallDir()
		$cachedManifest = "$target.json"
		$installInfo = $null

		if((test-path -lp $target) -and (test-path -lp $cachedManifest)) {
			# We don't have to download again since we have a cached copy
			info "reusing cache for $pkg"
			try {
				$installInfo = [InstallInfo]::ParseFile($cachedManifest, $pkg.repo)
				$installInfo.name = $pkg.name
			} catch {
				err "failed to parse cached manifest for $pkg`nhelp: you can fix this issue by running ``ppkg clean $($pkg.name) -repo $($pkg.repo)``"
			}
			$scope, $tx = script::new-tx
		} else {
			$res = script::resolve-arch $pkg -override:$arch
			$file = ""
			script::download $pkg $res -outResult ([ref] $file)
			$files = script::extract $file -selectFiles:$res.files
			try {
				$scope, $tx = script::new-tx
				# Move the files to the apps directory
				script::empty-dir $target -tx $tx

				trace "moving downloaded files to $target"
				script::mv -lp $files $target -tx $tx
				$installInfo = $pkg.CreateInstallInfo($arch)
				trace "creating install record"
				$data = $installInfo.Json()
				script::write-file -path $cachedManifest -data $data -tx $tx
			} catch {
				err -ea stop "error installing ${pkg}:`n$_"
			}
		}

		info "linking $installInfo/latest"
		$latest = join-path (split-path $target) "latest"
		script::ln -junction -path $latest -pointsTo $target -tx $tx

		# Install shims
		$bins = $installInfo.bin `
		| foreach-object {
			$path = join-path $latest $_
			if(script::exists -not $path -tx $tx) {
				err "package manifest error: package $installInfo declares a binary '$_' however it does not exist"
			}
			$path
		}

		$bins | script::shim::write -tx $tx


		# Link persistent files and folders
		if($pkg.persist) {
			info "linking persistent files and folders"
			$persistDir = $pkg.GetPersistDir()
			script::ensure-dir $persistDir -tx $tx
			foreach($p in $pkg.persist) {
				info "persisting {0}" $p.rename
				$path = join-path $target $p.rename
				$real = join-path $persistDir $p.name
				$realExists = script::exists $real -tx $tx
				try {
					$path = script::get-file $path -tx $tx
				} catch {
					err "the package $pkg defines a file to be persisted but the file `"$path`" can't be statted: $_"
				}

				if($realExists) {
					# We have to prefer the user config over the one shipped in the package
					# If it's a directory, copy missing items
					if($path.IsDirectory -and (script::exists -directory $real -tx $tx)) {
						foreach($p in script::ls $path -recurse -tx $tx) {
							$moveto = join-path $real $p.fullname.substring($path.fullname.length + 1)
							if(script::exists -not $moveto -tx $tx) {
								split-path -parent $moveto | script::ensure-dir -tx $tx
								script::mv $_ $moveto -tx $tx
							}
						}
     }
					script::rm -rf $path -tx $tx
				} else {
					script::mv $path $real -tx $tx
				}

				if($real.IsDirectory) {
					script::ln -junction -path $path -pointsTo $real -tx $tx
				} else {
					script::ln -hard -path $path -pointsTo $real -tx $tx
				}
			}
  }

		info "copying metadata to the install directory"
		$installPath = $installInfo.InstalledManifestPath()
		split-path $installPath | script::ensure-dir -tx $tx
		$md = $installInfo.Json()
		script::write-file -path $installPath -data $md -tx $tx

		try {
			info "completing transaction"
			$scope.complete()
			info "installed $pkg ($($pkg.BinNames() -join ", "))"
		} catch {
			err "failed to complete transaction: $_"
		} finally {
			$scope.dispose()
			$scope = $null
		}
	}
}

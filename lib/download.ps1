function :download {
	# Returns: Path of the downloaded file
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(Mandatory, Position = 0)]
		[Package] $pkg,

		[Parameter(Mandatory, Position = 1)]
		[Resource] $res,

		[Parameter(Mandatory)]
		[ref] $outResult,

		[switch] $keepLogs
	)

	$dir = join-path $script:settings.tmp $pkg.repo ("{0}@{1}" -f $pkg.name, $pkg.version)
	script::empty-dir $dir

	$logfile = script::new-downloadlog $pkg
	$logdir = split-path $logfile

	$errStr = ""
	try {
		script::ensure-dir $logdir
		$errStr = "detailed logs can be found at $logfile"
	} catch {
		$errStr = "logs are not available due to an IO error creating/emptying the directory ${logdir}: $_"
	}

	$b = [UriBuilder]::new($res.url)
	$name, $url = if($b.fragment) {
		$b.fragment.substring(1)
		$b.fragment = ""
		$b
	} else {
		"", $b
	}

	switch ($res.url.scheme) {
		"http" {}
		"https" {
			# We're using curl for downloads as the powershell solution doesn't indicate file names
			info "downloading $pkg with curl"
			trace "downloading $url with curl"

			curl --disable -LO -J `
				--create-dirs --output-dir $dir `
				--retry 3 --retry-delay 1 `
				--trace $logfile $url

			assert-ok "curl exited with failure ($lastExitCode); $errStr"
			# Find the file we just downloaded
			$file = Get-ChildItem -lp $dir
			assert $file.count -ne 0 "The url $url doesn't seem to point to a file; $errStr"

			script::check-hash $res -path $file

			if($name -and $file.name -ne $name) {
				$old = $file
				$file = join-path $dir $name
				script::mv $old $file
			}

			$outResult.value = $file
			break
		}
		"sftp" {
			# Newer releases of Windows come with OpenSSH, which includes sftp.
			if(!$name) {
				$name = $url.uri.segments[-1]
			}

			$file = join-path $dir $name
			$configFlag = if($config = $script:settings.sshConfig) { "-F", $config } else { }
			$port = $url.port

			$host = if($user = $url.uri.UserInfo) {
				"{0}@{1}" -f $user, $url.host
			} else {
				$url.host
			}

			$remote = "${host}:$($url.uri.AbsolutePath)"

			$portFlag = if($port -lt 0) {
				trace "accessing $remote using sftp"
				$null
			} else {
				trace "accessing $remote  port $port with sftp"
				"-P", $port
			}

			info "downloading $name with sftp"
			sftp -fv $configFlag $portFlag $remote $file 2> $logfile

			assert-ok "sftp exited with failure ($lastExitCode); $errStr"

			if(script::exists -not $file) {
				err "downloaded file doesn't exist ($file); $errStr"
			}

			script::check-hash $res -path $file
			$outResult.value = $file
			break
		}
		"" { err "URL missing protocol: $url" }
		default { err "unsupported protocol in url: $($res.url)" }
	}

	if(!$keepLogs) {
		remove-item -ea ignore -recurse -lp $logdir
	}
}

function :extract {
	# Returns: Paths of the extracted files
	[CmdletBinding()]
	[OutputType([IO.FileSystemInfo])]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $path,
		[Parameter()]
		[string[]] $selectFiles
	)

	$name = $origName = split-path -leafbase $path
	$ext = split-path -extension $path
	if($ext -in ".exe", ".cmd", ".bat") {
		return $path
	}
	$isTar = $false
	if($ext -in ".xz", ".gz", ".zst", ".bz2", ".lz", ".z" -and $name -like "*.tar") {
		$name = split-path -leafbase $name
		$isTar = $true
	}
	$dir = join-path (split-path $path) $name
	$isTar = $isTar -or $ext -in ".txz", ".tgz", ".tlz", ".tz", ".tzst"

	if($isTar) {
		info "extracting $origName with tar"
		script::mkdir $dir
		# Prefer bsdtar over tar
		$tar = $null
		try {
			$tar = $script:settings.exec("bsdtar.exe")
		} catch {
			$tar = $script:settings.exec("tar.exe")
		}
		$out = &$tar -C $dir -xf $path "--" $selectFiles 2>&1
		assert-ok -ea stop "tar error: $out"
	} else {
		info "extracting $origName with 7zip"
		$sz = $script:settings.exec("7z.exe")
		$out = &$sz x -bso0 -bsp0 -aoa "-o$dir" "--" $path $selectFiles 2>&1
		assert-ok -ea stop "7zip error: $out"
	}

	# Validate that selected files exist
	if($selectFiles) {
		$selectFiles | foreach-object {
			$f = join-path $dir $_ | get-item -ea ignore -force
			if(!$f) {
				err -ea stop "manifest specifies '$_' but it does not exist"
			}
		}
	}

	get-childitem -lp $dir -force
}

function :new-downloadlog {
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(Mandatory, Position = 0)]
		[Package] $pkg
	)

	process {
		$date = get-date -uformat "%Y-%m-%dz(%H-%M-%S)"
		$name = "{0}_{1}@{2}.log" -f $pkg.repo, $pkg.name, $pkg.version
		join-path $script:settings.logs download $date $name
	}
}

function :check-hash {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[Resource] $resource,
		[Parameter(Mandatory)]
		[string] $path
	)

	if($resource.hash) {
		$algo, $expected = $resource.GetHash()
		info "checking the $algo hash of $(split-path -leaf $path)"
		$hash = Get-FileHash -ea stop -algo $algo -path $path
		assert $expected -eq $hash.hash "file hashes don't match: $path"
	}
}

function :run-actions {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[Package] $pkg,
		[Parameter(Mandatory, Position = 1)]
		[Resource] $resource,
		[Parameter(Mandatory)]
		[string] $dir,
		[Parameter(Mandatory)]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx
	)

	$actions = [Collections.Generic.List[PPKG.Action]]::new()

	if($resource.preInstall) {
		[void] $actions.AddRange($resource.preInstall)
	}
	if($pkg.preInstall) {
		[void] $actions.AddRange($pkg.preInstall)
	}

	if($actions.count -eq 0) {
		return
	}

	info "executing pre-install actions"
	$ctx = [PPKG.Context]::new($tx, $dir, $function:trace)
	foreach($a in $actions) {
		trace "executing action: $a"
		try {
			$a.run($ctx)
		} catch {
			err -ea stop "error executing action: $_`naction: $a"
		}
	}

	$ctx = $null
}

function Update-PPKGManifest {
	[CmdletBinding(DefaultParameterSetName = "path")]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, ParameterSetName = "path", HelpMessage = "Path to a PPKG manifest (supports glob)")]
		[object[]] $path,

		[Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "lp", HelpMessage = "Path to a PPKG manifest")]
		[Alias("lp")]
		[object[]] $literalPath,

		[Parameter(HelpMessage = "Do not update the files on disk")]
		[switch] $dry,
		[Parameter(HelpMessage = "Do not download fiels to update hashsums")]
		[switch] $noHash
	)

	begin {
		$ErrorActionPreference = "stop"
		$lp = $PSCmdlet.ParameterSetName -ceq "lp"
		$packages = [Collections.Generic.List[Package]]::new()
	}

	process {
		$fs = if($lp) {
			get-item -lp $literalPath
		} else {
			get-item $path
		}

		foreach($f in $fs) {
			if($f -isnot [IO.FileInfo]) {
				write-error "$f does not point to a PPKG manifest"
			}

			try {
				$pkg = [Package]::ParseFile($f, "-")
				[void] $packages.add($pkg)
			} catch {
				err "error parsing manifest at ${f}: $_"
			}
		}
	}

	end {
		assert $packages.count -ne 0 "no file found"
		foreach($pkg in $packages) {
			$name = $pkg.name

			try {
				$new = script::update-manifest $pkg -noHash:($noHash -or $dry)
			} catch {
				write-error -ea continue "error updating ${name}: $_"
				continue
			}

			if(!$new) {
				info "skipping $name"
				continue
			} elseif($new.version -eq $pkg.version) {
				info "no changes for $name"
				continue
			}
			info "{0}: v{1} -> v{2}" $name $pkg.version $new.version
			if($dry) {
				continue
			}

			$pkg.x32 = $new.x32
			$pkg.x64 = $new.x64
			$pkg.version = $new.version

			$json = $pkg.Json()
			try {
				$json | out-file -noNewLine -encoding utf8 $pkg.path
			} catch {
				write-error -ea continue "error writing changes to ${path}: $_"
			}
  }
	}
}

function :update-manifest {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[Package] $pkg,

		[switch] $noHash
	)

	$ErrorActionPreference = "stop"
	$name = $pkg.name
	$path = $pkg.path

	$url = $pkg.x32.githubPattern ?? $pkg.x64.githubPattern
	if(!$url) {
		return
	}

	if($url.host -cne "github.com" -or $url.segments.count -lt 3) {
		err "${name}: the URL $url does not point to a github repository ($path)"
	} elseif(!$url.OriginalString.contains('${version}')) {
		err "${name}: the URL $url does not contain a version pattern `${version} ($path)"
	}

	$apiUrl = $url.segments `
	| select-object -first 3 `
	| join-string -outputPrefix "https://api.github.com/repos" -outputSuffix "releases/latest"

	write-verbose "${name}: querying the github API"
	$resp = Invoke-RestMethod -method get -uri $apiUrl
	if($resp.tag_name) {
		try {
			$ver = [PVersion]::new($resp.tag_name)
		} catch {
			err "error parsing version string $($resp.tag_name): $_"
		}
	} else {
		err "${name}: could not determine the latest tag version"
	}


	if($ver -eq $pkg.version) {
		return $pkg
	}

	$new = @{ version = $ver }

	if($pkg.x32.githubPattern) {
		$new.x32 = @{
			url = $pkg.x32.githubPattern.OriginalString.replace('${version}', "$ver")
			hash = $null
			githubPattern = $pkg.x32.githubPattern
		}
	}

	if($pkg.x64.githubPattern) {
		$new.x64 = @{
			url = $pkg.x64.githubPattern.OriginalString.replace('${version}', "$ver")
			hash = $null
			githubPattern = $pkg.x64.githubPattern
		}
	}

	if($noHash) {
		return $new
	}

	if($url = $new.x32.url) {
		info "downloading $name.x32 to a temporary path"
		$temp = New-TemporaryFile
		remove-item -lp $temp
		Invoke-WebRequest $url -outFile $temp
		$h = Get-FileHash -lp $temp -algorithm SHA256
		$new.x32.hash = "SHA256:" + $h.hash
		remove-item -lp $temp
	}

	if($url = $new.x64.url) {
		info "downloading $name.x64 to a temporary path"
		$temp = New-TemporaryFile
		remove-item -lp $temp
		Invoke-WebRequest $url -outFile $temp
		$h = Get-FileHash -lp $temp -algorithm SHA256
		$new.x64.hash = "SHA256:" + $h.hash
		remove-item $temp
	}

	$new
}

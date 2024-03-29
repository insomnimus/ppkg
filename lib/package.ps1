enum Arch {
	X32
	X64
}

class Resource {
	[Uri] $url
	[Uri] $githubPattern
	[string[]] $files
	[string] $hash
	[PPKG.Action[]] $preInstall

	# Constructors
	Resource() {}
	Resource([string] $url) { $this.url = $url }

	[string] ToString() {
		return "$($this.url)"
	}

	[string] Validate() {
		if(!"$($this.url)") {
			return "missing url"
		}
		if($this.url.scheme -cnotin "https", "http", "sftp") {
			return "invalid scheme '$($this.url.scheme)'; must be one of https, http or sftp"
		}

		if($this.hash) {
			$hashes = "MD5", "SHA1", "SHA256", "SHA384", "SHA512"
			$algo, $h = $this.hash.split(":", 2) | foreach-object Trim
			if(!$null -eq $h -and $algo -notin $hashes) {
				return "unknown hash format ``$algo``; known algoritms are $($hashes -join ", ")"
			}
		}

		return ""
	}

	[string[]] GetHash() {
		if($this.hash) {
			$algo, $h = $this.hash.split(":", 2) | foreach-object Trim
			if($null -eq $h) {
				return "SHA256", $this.hash
			} else {
				return $algo, $h
			}
		}

		return "", ""
	}

	[object] ToJsonObject() {
		if(!$this.hash -and !$this.files -and !$this.preInstall -and !$this.githubPattern) {
			return $this.url
		}
		$x = [Ordered] @{
			url = $this.url
		}
		if($this.githubPattern) {
			$x.githubPattern = $this.githubPattern
		}
		if($this.hash) {
			$x.hash = $this.hash
		}
		if($this.files) {
			$x.files = $this.files
		}
		if($this.preInstall) {
			$x.preInstall = $this.preInstall | foreach-object ToString
		}

		return $x
	}
}

class PackageInfo {
	[string] $name
	[PVersion] $version
	[string] $description
	[string] $repo
	[string] $homepage
	[string] $license
	[string[]] $bin
	[Persist[]] $persist

	[string] ToString() {
		return "{0}@{1}" -f $this.name, $this.version
	}

	[string] InstallDir() {
		# Returns the path to which this package should be installed.
		return (join-path $script:settings.apps $this.repo $this.name $this.version)
	}

	[string] GetCacheManifestPath() {
		return $this.InstallDir() + ".json"
	}

	[string] InstalledManifestPath() {
		return (join-path $script:settings.installed $this.repo "$($this.name).json")
	}

	[bool] IsInstalled([bool] $thisVersion) {
		$p = $this.InstalledManifestPath()
		$yes = test-path -lp $p
		if($thisVersion) {
			try {
				$man = [InstallInfo]::ParseFile($p, $this.repo)
				return $man.version -eq $this.version
			} catch {
				script::warn "failed to parse install manifest at ${p}: $_"
				return $false
			}
		} else {
			return $yes
		}
	}

	[string[]] BinNames() {
		return ($this.bin | split-path -leaf)
	}

	[string] GetPersistDir() {
		return (join-path $script:settings.persist $this.repo $this.name)
	}
}

class Package: PackageInfo {
	hidden [string] $path
	[Resource] $x64
	[Resource] $x32
	[PPKG.Action[]] $preInstall

	static [Package] ParseFile([string] $path, [string] $repo) {
		$j = get-content -lp $path | convertfrom-json -asHashTable -depth 5
		$p = [Package] $j
		$p.repo = $repo
		$p.path = $path
		$p.name = split-path -leafbase $path
		$p.Validate()
		return $p
	}

	[void] Validate() {
		$checks = "description", "version", "bin", "license"
		foreach($key in $checks) {
			$val = $this | select-object -ea ignore -expand $key
			assert $val "the manifest at path $($this.path) is missing the property $key"
		}

		assert ($this.x64 -or $this.x32) "manifest at $($this.path) is missing any URL"
		if($this.x32) {
			$res = $this.x32.validate()
			assert $res -ceq "" "the manifest at $($this.path) has an invalid value for 'x32.url': $res"
		}
		if($this.x64) {
			$res = $this.x64.validate()
			assert $res -ceq "" "the manifest at $($this.path) has an invalid value for 'x64.url': $res"
		}

		# Validate binary names
		$names = [Collections.Generic.HashSet[string]]::new()
		foreach($b in $this.BinNames()) {
			if(!$names.add($b.ToUpper())) {
				throw "package declares multiple binaries with the same name: $b"
			}
		}

		# Validate persist values
		if($this.persist.length -gt 0) {
			$names = @{}
			$renames = @{}

			foreach($p in $this.persist) {
				if($null -ne $names[$p.name] -or $null -ne $renames[$p.rename]) {
					throw "the persist key has duplicates"
				}

				assert ($p.name -ne "" -and $p.rename -ne "") "invalid persist value"
				$names[$p.name] = $renames[$p.rename] = $true
			}
		}
	}

	[InstallInfo] CreateInstallInfo([Nullable[Arch]] $arch) {
		$x = $this | select-object -property name, version, repo, description, homepage, license, bin, persist
		$x = [InstallInfo] $x
		$x.archOverride = $arch
		return $x
	}

	[string] Json() {
		$x = $this | select-object -exclude name, path, repo, preInstall, x32, x64, persist
		$x.bin = $this.bin | write-output # This  makes single arrays into strings
		$x.version = $this.version.ToString()
		if($this.x32) {
			$x | add-member NoteProperty x32 $this.x32.ToJsonObject()
		}
		if($this.x64) {
			$x | add-member NoteProperty x64 $this.x64.ToJsonObject()
		}

		if($this.preInstall) {
			$x | add-member NoteProperty preInstall ($this.preInstall | foreach-object ToString) -memberType "string[]"
		}
		if($this.persist) {
			$x | add-member NoteProperty persist (this.persist | foreach-object ToString) -typeName "string[]"
		}

		return (ConvertTo-Json -depth 10 $x)
	}
}

class InstallInfo: PackageInfo {
	hidden [string] $path
	[Nullable[Arch]] $archOverride

	static [InstallInfo] ParseFile([string] $path, [string] $repo) {
		$data = get-content -raw -ea stop -lp $path
		$j = ConvertFrom-Json -ea stop -depth 5 -AsHashTable $data
		$j.repo = $repo
		$j.name = split-path -leafbase $path
		$j.path = $path
		return [InstallInfo] $j
	}

	[string] Json() {
		$x = $this | select-object -exclude name, repo, path, persist
		$x.version = $this.version.ToString()
		$x | add-member NoteProperty persist ($this.persist | foreach-object ToString) -typename "string[]"
		return (ConvertTo-Json -depth 5 -input $x -enumsAsStrings)
	}
}

function :resolve-arch {
	[CmdletBinding()]
	[OutputType([Resource])]
	param (
		[Parameter(Mandatory, Position = 0)]
		[Package] $pkg,
		[Parameter()]
		[Nullable[Arch]] $override
	)

	assert ($null -ne $pkg.x32 -or $null -ne $pkg.x64) "package provides no executables"

	switch($override) {
		"x32" {
			assert $null -ne $pkg.x32 "package does not provide an x32 binary"
			$pkg.x32
			break
		}
		"x64" {
			assert $null -ne $pkg.x64 "package does not provide an x64 binary"
			$pkg.x64
			break
		}
		$null {
			if($script:is64) {
				$pkg.x64 ?? $pkg.x32
			} else {
				assert $null -ne $pkg.x32 "package does not provide an x32 binary"
				$pkg.x32
			}
			break
		}
		default { throw "(internal error) unhandled switch case: $_" }
	}
}

class Persist {
	# The name used in `persist/repo/app/`.
	hidden [string] $name
	# The name used while creating the soft link.
	hidden [string] $rename

	Persist([string] $s) {
		$a, $b = $s.split(":", 2)
		if($null -eq $b) {
			$this.name = $this.rename = $s
		} else {
			$this.name = $a
			$this.rename = $b
		}
	}

	[string] ToString() {
		if($this.name -cne $this.rename) {
			return "{0}:{1}" -f $this.name, $this.rename
		} else {
			return $this.name
		}
	}
}

class PackageDisplay {
	[string] $name
	[string] $repo
	[PVersion] $version
	[string] $description
	[string] $homepage
	[string] $license
	[string] $bin
	[object] $installed

	PackageDisplay([PackageInfo] $p) {
		$this.name = $p.name
		$this.repo = $p.repo
		$this.version = $p.version
		$this.description = $p.description
		$this.license = $p.license
		$this.homepage = $p.homepage
		$this.bin = $p.BinNames()

		$path = $p.InstalledManifestPath()
		$query = [WildcardPattern]::escape($p.name)
		if($info = script::ppkg-list -ea ignore $query -repo $p.repo) {
			$this.installed = $info.version
			if($info.archOverride) {
				$this | add-member NoteProperty archOverride $info.archOverride
			}
		} else {
			$this.installed = $false
		}
	}
}

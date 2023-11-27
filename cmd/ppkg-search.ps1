function ppkg-search {
	[CmdletBinding(DefaultParameterSetName = "fuzzy")]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, ParameterSetName = "fuzzy", HelpMessage = "The package name or the name of an executable to search for (accepts glob)")]
		[string[]] $query,

		[Parameter(ParameterSetName = "not-fuzzy", HelpMessage = "Name of the package (accepts glob)")]
		[string[]] $package,

		[Parameter(ParameterSetName = "not-fuzzy", HelpMessage = "Name of an executable (accepts glob)")]
		[string[]] $bin,

		[Parameter(HelpMessage = "Specify a repository")]
		[string] $repo
	)

	try {
		script::ppkg-search -ea stop @PSBoundParameters
	} catch {
		write-error "$_"
	}
}

function ppkg-search {
	[CmdletBinding(DefaultParameterSetName = "fuzzy")]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, ParameterSetName = "fuzzy", HelpMessage = "The package name or the name of an executable to search for (accepts glob)")]
		[string[]] $query,

		[Parameter(ParameterSetName = "not-fuzzy", HelpMessage = "Name of the package (accepts glob)")]
		[string[]] $package,

		[Parameter(ParameterSetName = "not-fuzzy", HelpMessage = "Name of an executable (accepts glob)")]
		[string[]] $bin,

		[Parameter(HelpMessage = "Specify a repository")]
		[string] $repo
	)

	$ErrorActionPreference = "stop"
	if($query) {
		$bin = $query
		$package = $query
	}
	$bin = $bin | script::escape-invalidpattern
	$package = $package | script::escape-invalidpattern
	$repo = $repo | script::escape-invalidpattern

	get-childitem -lp $script:settings.repos `
	| where-object { !$repo -or $_.name -eq $repo } `
	| foreach-object {
		$r = $_.name
		get-childitem -recurse -lp $_ -filter *.json `
		| foreach-object {
			$path = $_

			foreach($name in $package) {
				if($_.basename -like $name -or $_.basename -eq $name) {
					try {
						$p = [Package]::ParseFile($path, $r)
						return $p
					} catch {
						warn "failed to parse manifest at ${path}: $_"
						return
					}
				}
			}

			if($bin) {
				try {
					$p = [Package]::ParseFile($path, $r)
					foreach($name in $p.bin | split-path -leaf) {
						$basename = split-path -leafbase $name
						foreach($b in $bin) {
							if($name -like $b -or $name -eq $b -or $basename -like $b -or $basename -eq $b) {
								return $p
							}
						}
					}
				} catch {
					warn "failed to parse manifest at ${path}: $_"
				}
			}
		}
	}
}

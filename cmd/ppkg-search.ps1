function ppkg-search {
	[CmdletBinding(DefaultParameterSetName = "fuzzy")]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, ParameterSetName = "fuzzy", HelpMessage = "The package name, a keyword or the name of an executable to search for (accepts glob)")]
		[string[]] $pattern,

		[Parameter(ParameterSetName = "not-fuzzy", HelpMessage = "Name of the package (accepts glob)")]
		[string[]] $package,

		[Parameter(ParameterSetName = "not-fuzzy", HelpMessage = "Name of an executable (accepts glob)")]
		[string[]] $bin,

		[Parameter(HelpMessage = "Specify a repository")]
		[string[]] $repo
	)

	try {
		script::ppkg-search -ea stop @PSBoundParameters
	} catch {
		write-error "$_"
	}
}

function :ppkg-search {
	[CmdletBinding(DefaultParameterSetName = "fuzzy")]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, ParameterSetName = "fuzzy", HelpMessage = "The package name, a keyword or the name of an executable to search for (accepts glob)")]
		[string[]] $pattern,

		[Parameter(ParameterSetName = "not-fuzzy", HelpMessage = "Name of the package (accepts glob)")]
		[string[]] $package,

		[Parameter(ParameterSetName = "not-fuzzy", HelpMessage = "Name of an executable (accepts glob)")]
		[string[]] $bin,

		[Parameter(HelpMessage = "Specify a repository")]
		[string[]] $repo
	)

	$ErrorActionPreference = "stop"
	$keywords = script::filter $pattern | foreach-object {
		$s = [Regex]::escape($_)
		$opts = [Text.RegularExpressions.RegexOptions]::Compiled -bor
		[Text.RegularExpressions.RegexOptions]::CultureInvariant -bor
		[Text.RegularExpressions.RegexOptions]::IgnoreCase -bor
		[Text.RegularExpressions.RegexOptions]::NonBacktracking

		[Regex]::new("\b${s}\b", $opts)
	}

	if($pattern) {
		$bin = $pattern
		$package = $pattern
	}

	$bin = script::filter $bin | foreach-object {
		$ext = split-path -extension $_
		if([WildcardPattern]::ContainsWildcardCharacters($ext)) {
			$_
		} else {
			split-path -leafBase $_
		}
	} | script::escape-invalidpattern

	$package = script::filter $package | script::escape-invalidpattern
	$repo = script::filter $repo | script::escape-invalidpattern

	get-childitem -lp $script:settings.repos `
	| where-object { !$repo -or $_.name -in $repo } `
	| foreach-object {
		$r = $_.name
		get-childitem -recurse -lp $_ -filter *.json `
		| foreach-object {
			$path = $_
			$doParse = $bin.count -ne 0 -or $keywords.count -ne 0
			$isMatch = $false

			foreach($name in $package) {
				if($_.basename -like $name -or $_.basename -eq $name) {
					$doParse = $isMatch = $true
					break
				}
			}

			if(!$doParse) {
				return
			}

			try {
				$pkg = [Package]::ParseFile($path, $r)
			} catch {
				warn "error parsing manifest at ${path}: $_"
				return
			}

			if($isMatch) {
				return $pkg
			}

			foreach($k in $keywords) {
				if($pkg.description -match $k) {
					return $pkg
				}
			}
			foreach($binName in $pkg.bin | split-path -leafBase) {
				foreach($b in $bin) {
					if($binName -like $b -or $binName -eq $b) {
						return $pkg
					}
				}
			}
  }
	}
}

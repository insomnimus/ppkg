function :ppkg-search {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, HelpMessage = "Name of the package (accepts glob)")]
		[string[]] $package,
		[Parameter(HelpMessage = "Specify a repository")]
		[string] $repo
	)

	$ErrorActionPreference = "stop"
	get-childitem -lp $script:settings.repos `
	| where-object { !$repo -or $_.name -eq $repo } `
	| foreach-object {
		$r = $_.name
		get-childitem -lp $_ -filter *.json `
		| where-object {
			if(!$package) { return $true }
			foreach($p in $package) {
				if($_.basename -like $p) {
					return $true
				}
			}
			$false
		} `
		| foreach-object {
			$path = $_.fullname
			try {
				[Package]::ParseFile($path, $r)
			} catch {
				write-warning "failed to parse manifest at ${path}: $_"
			}
		}
	}
}

function ppkg-search {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments, HelpMessage = "Name of the package (accepts glob)")]
		[string[]] $package,
		[Parameter(HelpMessage = "Specify a repository")]
		[string] $repo
	)

	try {
		script::ppkg-search -ea stop @PSBoundParameters
	} catch {
		write-error "error: $_"
	}
}

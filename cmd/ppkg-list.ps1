function :ppkg-list {
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ValueFromRemainingArguments, HelpMessage = "Filter results with a glob pattern")]
		[string[]] $pattern,
		[Parameter(HelpMessage = "Limit results to a repository or repositories")]
		[string[]] $repo
	)

	$ErrorActionPreference = "stop"
	$pattern = $pattern | foreach-object -memberName ToLower | select-object -unique
	$repo = $repo | foreach-object -memberName ToLower | select-object -unique

	get-childitem -directory -lp $script:settings.installed `
	| where-object { !$repo -or $_.name -in $repo } `
	| foreach-object {
		$r = $_.name
		get-childitem -file -filter *.json -lp $_ -recurse `
		| where-object {
			if(!$pattern) { return $true }
			foreach($p in $pattern) {
				if($_.basename -like $p -or $_.basename -eq $p) {
					return $true
				}
			}
			$false
		} `
		| foreach-object {
			$path = $_.fullname
			try {
				[InstallInfo]::ParseFile($path, $r)
			} catch {
				write-warning "warning: failed to parse manifest at ${path}: $_"
			}
		}
	} `
	| sort-object -property name
}

function ppkg-list {
	[CmdletBinding()]
	param (
		[Parameter(Position = 0, ValueFromRemainingArguments, HelpMessage = "Filter results with a glob pattern")]
		[string[]] $pattern,
		[Parameter(HelpMessage = "Limit results to a repository or repositories")]
		[string[]] $repo
	)

	try {
		script::ppkg-list -ea stop @PSBoundParameters
	} catch {
		write-error "$_"
	}
}

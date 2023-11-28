function :quote {
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(Position = 0, ValueFromPipeline)]
		[AllowEmptyString()]
		[string] $str
	)

	begin {
		$specials = [Collections.Generic.HashSet[char]] "{}()<>;,`$`"'@ `t`n|&".ToCharArray()
		function :should-escape([string] $s) {
			foreach($c in $s.GetEnumerator()) {
				if($specials.Contains($c)) {
					return $true
				}
			}
			$false
		}
	}

	process {
		if(!$str) {
			return
		}

		if(:should-escape $str) {
			$str = $str.replace("'", "''")
			"'$str'"
		} else {
			$str
		}
	}
}

function :normalize-buf([string] $buf) {
	if(!$buf) {
		return ""
	}
	if(($buf.StartsWith("'") -and $buf.EndsWith("'")) -or ($buf.StartsWith('"') -and $buf.EndsWith('"'))) {
		script::escape-invalidpattern $buf.Substring(1, $buf.length - 2)
	} else {
		script::escape-invalidpattern $buf
	}
}

function :completions::search-package {
	param (
		[Parameter(Position = 0)]
		[string] $buf,
		[Parameter(Mandatory)]
		[string] $dir,
		[Parameter()]
		[string[]] $repo
	)

	$buf = script::normalize-buf $buf
	$buf += "*"

	Get-ChildItem -ea ignore -lp $dir -directory `
	| where-object { !$repo -or $_.name -in $repo } `
	| foreach-object -parallel {
		foreach($f in Get-ChildItem -ea ignore -lp $_ -file -recurse -filter *.json) {
			$basename = $f.basename
			if($basename -like $using:buf) {
				$basename
			}
		}
	}
}

function :complete-package {
	param (
		[Parameter(Position = 0)]
		[string] $buf,
		[Parameter(Mandatory)]
		[string] $dir,
		[Parameter()]
		[string[]] $repo
	)

	script::completions::search-package $buf -repo:$repo -dir:$dir `
	| sort-object -unique `
	| script::quote
}

# Repo parameters
"info", "install", "search", "update" | foreach-object {
	Register-ArgumentCompleter -CommandName "ppkg-$_" -ParameterName repo -ScriptBlock {
		param($_a, $_b, $buf)
		$buf = script::normalize-buf $buf
		$buf += "*"

		Get-ChildItem -ea ignore -Name -Directory -lp $script:settings.repos `
		| where-object { $_ -like $buf } `
		| script::quote
	}
}

# installed repo completions
Register-ArgumentCompleter -CommandName ppkg-clean, ppkg-list -ParameterName repo -ScriptBlock {
	param($_a, $_b, $buf)
	$buf = script::normalize-buf $buf
	$buf += "*"

	Get-ChildItem -ea ignore -Name -Directory -lp $script:settings.installed `
	| where-object { $_ -like $buf } `
	| script::quote
}

# package completions
Register-ArgumentCompleter -CommandName ppkg-info, ppkg-search -ParameterName package -ScriptBlock {
	param($_a, $_b, $buf, $_d, $params)
	$repo = $params["repo"]
	script::complete-package $buf -repo:$repo -dir $script:settings.repos
}


# installed package completions
Register-ArgumentCompleter -CommandName ppkg-clean, ppkg-remove, ppkg-update -ParameterName package -ScriptBlock {
	param($_a, $_b, $buf, $_d, $params)
	$repo = $params["repo"]
	script::complete-package $buf -repo:$repo -dir $script:settings.installed
}

Register-ArgumentCompleter -CommandName ppkg-list, ppkg-search -ParameterName pattern -ScriptBlock {
	param($_a, $_b, $buf, $_d, $params)
	$repo = $params["repo"]
	script::complete-package $buf -repo:$repo -dir $script:settings.installed
}

# not installed package completions
Register-ArgumentCompleter -CommandName ppkg-install -ParameterName package -ScriptBlock {
	param($_a, $_b, $buf, $_d, $params)

	$repo = $params["repo"]
	$installed = [Collections.Generic.HashSet[string]]::new()

	foreach($p in script::completions::search-package $buf -repo:$repo -dir $script:settings.installed) {
		[void] $installed.add($p.ToUpperInvariant())
	}

	script::completions::search-package $buf -repo:$repo -dir $script:settings.repos `
	| where-object { $installed.add($_.ToUpperInvariant()) } `
	| sort-object `
	| script::quote
}

Register-ArgumentCompleter -CommandName ppkg-where -ParameterName shim -ScriptBlock {
	param($_a, $_b, $buf)
	$buf = script::normalize-buf $buf
	if($buf -notlike "*.exe") {
		$buf += "*"
	}

	Get-ChildItem -ea ignore -name -file -filter *.exe -lp $script:settings.bin `
	| where-object { $_ -like $buf } `
	| script::quote
}

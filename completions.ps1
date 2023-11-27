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

function :complete-package {
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
		param($name)
		foreach($f in Get-ChildItem -ea ignore -lp $_ -file -recurse -filter *.json) {
			$basename = $f.basename
			if($basename -like $using:buf) {
				$basename
			}
		}
	} `
	| sort-object -unique `
	| script::quote
}

# Repo parameters
"clean", "info", "install", "list", "remove", "search", "update" | foreach-object {
	Register-ArgumentCompleter -CommandName "ppkg-$_" -ParameterName repo -ScriptBlock {
		param($_a, $_b, $buf)
		$buf = script::normalize-buf $buf
		$buf += "*"

		Get-ChildItem -ea ignore -Name -Directory -lp $script:settings.repos `
		| where-object { $_ -like $buf } `
		| script::quote
	}
}

# package completions
"info", "install", "search" | foreach-object {
	Register-ArgumentCompleter -CommandName "ppkg-$_" -ParameterName package -ScriptBlock {
		param($_a, $_b, $buf, $_d, $params)
		$repo = $params["repo"]
		script::complete-package $buf -repo:$repo -dir $script:settings.repos
	}
}

# installed package completions
"clean", "remove", "update" | foreach-object {
	Register-ArgumentCompleter -CommandName "ppkg-$_" -ParameterName package -ScriptBlock {
		param($_a, $_b, $buf, $_d, $params)
		$repo = $params["repo"]
		script::complete-package $buf -repo:$repo -dir $script:settings.installed
	}
}

Register-ArgumentCompleter -CommandName ppkg-list -ParameterName pattern -ScriptBlock {
	param($_a, $_b, $buf, $_d, $params)
	$repo = $params["repo"]
	script::complete-package $buf -repo:$repo -dir $script:settings.installed
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

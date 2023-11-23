function :ppkg-where {
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(
			Mandatory, Position = 0,
			ValueFromPipeline, ValueFromRemainingArguments,
			HelpMessage = "The name of a shim"
		)]
		[string[]] $shim
	)

	begin {
		$ErrorActionPreference = "stop"
	}

	process {
		foreach($s in $shim) {
			if($s -notlike "*.exe") {
				$s = "$s.exe"
			}
			$p = join-path $script:settings.bin $s
			if(test-path -lp $p -type leaf) {
				$out = cmdc -i $p 2>&1
				if($LastExitCode -ne 0) {
					write-error "${s}: not a known shim"
				} else {
					$out = join-string -input $out -separator "`n"
					[PPKG.CommandString]::CommandlineToArgs($out) | select-object -last 1
				}
			} else {
				write-error "${s}: not found"
			}
		}
	}
}

function ppkg-where {
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(
			Mandatory, Position = 0,
			ValueFromPipeline, ValueFromRemainingArguments,
			HelpMessage = "The name of a shim"
		)]
		[string[]] $shim
	)

	try {
		script::ppkg-where -ea stop @PSBoundParameters
	} catch {
		write-error "error: $_"
	}
}

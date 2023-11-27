function err {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg,

		[switch] $log,

		[Parameter(Position = 1, ValueFromRemainingArguments)]
		[object[]] $argv
	)

	if($argv) {
		$msg = $msg -f $argv
	}

	if($log) {
		$null = New-Event -SourceIdentifier PPKG.Log -MessageData @{ level = "error"; message = $msg }
	}
	Write-Error $msg
}

function info {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg,

		[Parameter(Position = 1, ValueFromRemainingArguments)]
		[object[]] $argv
	)

	if($argv) {
		$msg = $msg -f $argv
	}

	$null = New-Event -SourceIdentifier PPKG.Log -MessageData @{ level = "info"; message = $msg }
	write-information -infa continue $msg
}

function say {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg,

		[Parameter(Position = 1, ValueFromRemainingArguments)]
		[object[]] $argv
	)

	if($argv) {
		$msg = $msg -f $argv
	}

	write-information -infa continue $msg
}

function trace {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg,

		[Parameter(Position = 1, ValueFromRemainingArguments)]
		[object[]] $argv
	)

	if($argv) {
		$msg = $msg -f $argv
	}

	$null = New-Event -SourceIdentifier PPKG.Log -MessageData @{ level = "trace"; message = $msg }
	write-verbose $msg
}

function warn {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg,


		[switch] $noLog,

		[Parameter(Position = 1, ValueFromRemainingArguments)]
		[object[]] $argv
	)

	if($argv) {
		$msg = $msg -f $argv
	}

	if(!$noLog) {
		$null = New-Event -SourceIdentifier PPKG.Log -MessageData @{ level = "warning"; message = $msg }
	}

	write-warning $msg
}

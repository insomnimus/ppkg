function err {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg,

		[Parameter(Position = 1, ValueFromRemainingArguments)]
		[object[]] $argv
	)

	# TODO: Write to a log aggregator if configured
	if($argv) {
		write-error ($msg -f $argv)
	} else {
		write-error $msg
	}
}

function info {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg,

		[Parameter(Position = 1, ValueFromRemainingArguments)]
		[object[]] $argv
	)

	# TODO: Write to a log aggregator if configured
	if($argv) {
		write-information -infa continue ($msg -f $argv)
	} else {
		write-information -infa continue $msg
	}
}

function trace {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg,

		[Parameter(Position = 1, ValueFromRemainingArguments)]
		[object[]] $argv
	)

	# TODO: Write to a log aggregator if configured
	if($argv) {
		write-verbose ($msg -f $argv)
	} else {
		write-verbose $msg
	}
}

function warn {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg,

		[Parameter(Position = 1, ValueFromRemainingArguments)]
		[object[]] $argv
	)

	# TODO: Write to a log aggregator if configured
	if($argv) {
		write-warning ($msg -f $argv)
	} else {
		write-warning $msg
	}
}

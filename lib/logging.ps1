function err {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg,

		[Parameter(Position = 1, ValueFromRemainingArguments)]
		[object[]] $argv
	)

	# TODO: Write to a log aggregator if configured
	write-error ($msg -f $argv)
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
	write-information -infa continue ($msg -f $argv)
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
	write-verbose ($msg -f $argv)
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
	write-warning ($msg -f $argv)
}

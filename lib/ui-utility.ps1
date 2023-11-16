function :prompt {
	[CmdletBinding()]
	[OutputType([bool])]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg
	)

	$answer = read-host "$msg [y/n]"
	$answer -eq "y"
}

function :plural {
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(Mandatory, Position = 0)]
		[int] $n,
		[Parameter(Mandatory, Position = 1)]
		[string] $str,

		[Parameter(Position = 2)]
		[string] $plural
	)

	if($n -eq 1) {
		"$n $str"
	} elseif($plural) {
		"$n $plural"
	} else {
		"$n ${str}s"
	}
}

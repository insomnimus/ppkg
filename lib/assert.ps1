function assert {
	[CmdletBinding(DefaultParameterSetName = "truthy")]
	param (
		[Parameter(Mandatory, Position = 0)]
		[AllowNull()] [AllowEmptyString()]
		[object] $val,

		[Parameter(Mandatory, Position = 1)]
		[string] $msg,

		[Parameter(ParameterSetName = "truthy")][switch]
		$truthy = $true,

		[Parameter(ParameterSetName = "eq")] [object]
		$eq,
		[Parameter(ParameterSetName = "ceq")] [object]
		$ceq,
		[Parameter(ParameterSetName = "ne")] [object]
		$ne,
		[Parameter(ParameterSetName = "cne")] [object]
		$cne,
		[Parameter(ParameterSetName = "lt")] [object]
		$lt,
		[Parameter(ParameterSetName = "clt")] [object]
		$clt,
		[Parameter(ParameterSetName = "le")] [object]
		$le,
		[Parameter(ParameterSetName = "cle")] [object]
		$cle,
		[Parameter(ParameterSetName = "gt")] [object]
		$gt,
		[Parameter(ParameterSetName = "cgt")] [object]
		$cgt,
		[Parameter(ParameterSetName = "ge")] [object]
		$ge,
		[Parameter(ParameterSetName = "cge")] [object]
		$cge,

		[Parameter(ParameterSetName = "like")] [string]
		$like,
		[Parameter(ParameterSetName = "clike")] [string]
		$clike,
		[Parameter(ParameterSetName = "notlike")] [string]
		$notlike,
		[Parameter(ParameterSetName = "cnotlike")] [string]
		$cnotlike,

		[Parameter(ParameterSetName = "match")] [string]
		$match,
		[Parameter(ParameterSetName = "cmatch")] [string]
		$cmatch,
		[Parameter(ParameterSetName = "notmatch")] [string]
		$notmatch,
		[Parameter(ParameterSetName = "cnotmatch")] [string]
		$cnotmatch,

		[Parameter(ParameterSetName = "in")] [object[]]
		$in,
		[Parameter(ParameterSetName = "cin")] [object[]]
		$cin,
		[Parameter(ParameterSetName = "notin")] [object[]]
		$notin,
		[Parameter(ParameterSetName = "cnotin")] [object[]]
		$cnotin,

		[Parameter(ParameterSetName = "contains")] [object]
		$contains,
		[Parameter(ParameterSetName = "ccontains")] [object]
		$ccontains,
		[Parameter(ParameterSetName = "notcontains")] [object]
		$notcontains,
		[Parameter(ParameterSetName = "cnotcontains")] [object]
		$cnotcontains
	)

	$good = switch -CaseSensitive ($PSCmdlet.ParameterSetName) {
		"truthy" { !!$val; break }

		"eq" { $val -eq $eq; break }
		"ceq" { $val -ceq $ceq; break }
		"ne" { $val -ne $ne; break }
		"cne" { $val -cne $cne; break }
		"lt" { $val -lt $lt; break }
		"clt" { $val -clt $clt; break }
		"le" { $val -le $le; break }
		"cle" { $val -cle $cle; break }
		"gt" { $val -gt $gt; break }
		"cgt" { $val -cgt $cgt; break }
		"ge" { $val -ge $ge; break }
		"cge" { $val -cge $cge; break }

		"like" { $val -like $like; break }
		"clike" { $val -clike $clike; break }
		"notlike" { $val -notlike $notlike; break }
		"cnotlike" { $val -cnotlike $cnotlike; break }

		"match" { $val -match $match; break }
		"cmatch" { $val -cmatch $cmatch; break }
		"notmatch" { $val -notmatch $notmatch; break }
		"cnotmatch" { $val -cnotmatch $cnotmatch; break }

		"in" { $val -in $in; break }
		"cin" { $val -cin $cin; break }
		"notin" { $val -notin $notin; break }
		"cnotin" { $val -cnotin $cnotin; break }

		"contains" { $val -contains $contains; break }
		"ccontains" { $val -ccontains $ccontains; break }
		"notcontains" { $val -notcontains $notcontains; break }
		"cnotcontains" { $val -cnotcontains $cnotcontains; break }

		default { throw "internal error: unhandled switch case $_" }
	}

	if(!$good) {
		write-error $msg
	}
}

function assert-ok {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0)]
		[string] $msg
	)

	assert $LastExitCode -eq 0 $msg
}

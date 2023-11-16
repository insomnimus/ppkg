class Bytes {
	hidden [int64] $n = 0

	hidden $__init__ = {
		$this | add-member AliasProperty bytes n -typeName int64
	}.invoke()

	Bytes() {}
	Bytes([int64] $n) { $this.n = $n }
	Bytes([uint64] $n) { $this.n = $n }
	Bytes([int32] $n) { $this.n = $n }
	Bytes([uint32] $n) { $this.n = $n }
	Bytes([float] $n) { $this.n = $n }
	Bytes([double] $n) { $this.n = $n }
	Bytes([decimal] $n) { $this.n = $n }

	[string] ToString() {
		$x = [math]::abs([decimal] $this.n)
		$amount, $unit = if($x -gt 1e12l) {
	($x / 1dtb), "TiB"
		} elseif($x -gt 1e9l) {
	($x / 1dgb), "GiB"
		} elseif($x -gt 1e6l) {
	($x / 1dmb), "MiB"
		} elseif($x -gt 1e3l) {
	($x / 1dkb), "KiB"
		} else {
			return "$($this.n)B"
		}

		$s = $amount.ToString("0.00").TrimEnd("0").TrimEnd(".")
		$sign = $this.n -lt 0 ? "-" : ""
		return "$sign$s$unit"
	}

	static [Bytes] op_addition([Bytes] $a, [bytes] $b) {
		return [Bytes]::new($a.n + $b.n)
	}

	static [Bytes] op_subtraction([Bytes] $a, [bytes] $b) {
		return [Bytes]::new($a.n - $b.n)
	}

	static [Bytes] op_multiply([Bytes] $a, [bytes] $b) {
		return [Bytes]::new($a.n * $b.n)
	}

	static [Bytes] op_multiply([Bytes] $a, [decimal] $b) {
		return [Bytes]::new($a.n * $b)
	}

	static [Bytes] op_multiply([Bytes] $a, [double] $b) {
		return [Bytes]::new($a.n * $b)
	}

	static [Bytes] op_division([Bytes] $a, [bytes] $b) {
		return [Bytes]::new($a.n / $b.n)
	}

	static [Bytes] op_division([Bytes] $a, [decimal] $b) {
		return [Bytes]::new($a.n / $b)
	}

	static [Bytes] op_division([Bytes] $a, [double] $b) {
		return [Bytes]::new($a.n / $b)
	}
}

function :size {
	[CmdletBinding()]
	[OutputType([Bytes])]
	param (
		[Parameter(Position = 0, ValueFromPipeline)]
		[object[]] $path
	)

	begin {
		[Bytes] $n = 0
	}

	process {
		foreach($p in $path) {
			if($null -eq $p) {
				continue
			}

			if($p -is [IO.DirectoryInfo]) {
				if($null -eq $p.LinkTarget) {
					$n += Get-ChildItem -lp $p -recurse -file -force | script::size
				}
			} elseif($p -is [IO.FileSystemInfo]) {
				if($null -eq $p.LinkTarget) {
					$n += $p.length
				}
			} else {
				$n += get-item -lp $p -force | script::size
			}
		}
	}

	end {
		$n
	}
}

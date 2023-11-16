# Named this way so it doesn't conflict with System.Version.
class PVersion: System.IComparable, IEquatable[object] {
	[uint] $major
	[uint] $minor
	[uint] $patch
	[string] $pre

	PVersion([string] $str) {
		if($str -match '^v?(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(?:\-(?<pre>[a-zA-Z0-9\.\-]+))?$') {
			$this.major = $matches.major
			$this.minor = $matches.minor
			$this.patch = $matches.patch
			if($matches.pre) {
				$this.pre = $matches.pre
			} else {
				$this.pre = ""
			}
		} else {
			throw "invalid version syntax"
		}
	}

	static [PVersion] Parse([string] $s) {
		return [PVersion]::new($s)
	}

	[string] ToString() {
		if($this.pre) {
			return ("{0}.{1}.{2}-{3}" -f $this.major, $this.minor, $this.patch, $this.pre)
		} else {
			return ($this.major, $this.minor, $this.patch -join ".")
		}
	}

	[bool] Equals([object] $rhs) {
		if($null -eq $rhs) { return $null -eq $this }
		if($rhs -isnot [PVersion]) { throw "can't compare Version with $($rhs.GetType())" }
		return $this.CompareTo($rhs) -eq 0
	}

	[int] CompareTo([object] $rhs) {
		if($rhs -isnot [PVersion]) {
			throw "can't compare Version with $($rhs.GetType())"
		}
		if($null -eq $rhs) {
			throw "can't compare Version with null"
		}
		if(($cmp = $this.major.CompareTo($rhs.major)) -ne 0) {
			return $cmp
		} elseif(($cmp = $this.minor.CompareTo($rhs.minor)) -ne 0) {
			return $cmp
		} elseif(($cmp = $this.patch.CompareTo($rhs.patch)) -ne 0) {
			return $cmp
		}

		# Only difference is in the `pre` field which is a bit tricky
		if($this.pre -eq "" -and $rhs.pre -eq "") { return 0 }
		elseif($this.pre -eq "") { return 1 } # If it has a pre-release tag it's considered behind
		elseif($rhs.pre -eq "") { return -1 }
		else { return $this.pre.CompareTo($rhs.pre) }
	}
}

<#
# Uncomment if testing this script
while($true) {
	$left, $right = (read-host "enter").trim() -split "\s+"
	try {
		$a = [PVersion] $left
		$b = [PVersion] $right
		"comparison: $($a.CompareTo($b))"
		"==: $($a -eq $b)"
		"<=: $($a -le $b)"
		"<: $($a -lt $b)"
		">=: $($a -ge $b)"
		">: $($a -gt $b)"
	} catch {
		"error: $_"
	}
}
#>

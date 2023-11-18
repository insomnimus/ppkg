function :shim::write {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[string] $path,

		[Parameter()]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx
	)

	begin {
		$ErrorActionPreference = "stop"
		$cmdc = $script:settings.exec("cmdc.exe")
		$arch = switch (Get-CimInstance win32_operatingsystem | select-object -expand OsArchitecture) {
			"64-bit" { "x64"; break }
			"32-bit" { "x32"; break }
			default { err "ppkg does not support $_ architectures" }
		}
	}

	process {
		$name = (split-path -leafbase $path) + ".exe"
		$dest = join-path $script:settings.bin $name
		if($tx) {
			# Powershell translates pipeline data into unicode strings so we have to do it manually here.
			$data = script::exec -ea stop $cmdc "-o-" "--arch=x64" "--" $path
			# [Alphaleonis.Win32.Filesystem.File]::WriteAllBytesTransacted($tx, $dest, $data)
			script::write-file -path $dest -data $data -tx $tx
		} else {
			$null = &$cmdc --arch x64 -o $dest -- $path
			assert $LastExitCode -eq 0 "failed to create shim $dest -> $path"
		}
	}
}

# Runs a program and returns its stdout output as a byte list.
# This is necessary because Powershells pipelines are string encoded; this breaks binary output.
function :exec {
	[CmdletBinding()]
	[OutputType([Collections.Generic.List[byte]])]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromRemainingArguments)]
		[string[]] $command
	)

	$si = [System.Diagnostics.ProcessStartInfo] @{
		FileName = $command[0]
		useShellExecute = $false
		CreateNoWindow = $true
		RedirectStandardOutput = $true
		LoadUserProfile = $false # We don't need this
	}

	foreach($a in $command[1 .. $command.length]) {
		[void] $si.ArgumentList.Add($a)
	}

	try {
		$p = [System.Diagnostics.Process]::start($si)
	} catch {
		err -ea stop "error spawning process $($command[0]): $_"
	}

	$out = [Collections.Generic.List[byte]]::new(96kb)
	$buf = [byte[]]::new(4kb)

	# Read stdout.
	try {
		for(
			$read = $p.StandardOutput.BaseStream.Read($buf, 0, $buf.length)
			$read -gt 0
			$read = $p.StandardOutput.BaseStream.Read($buf, 0, $buf.length)
		) {
			# Append what we've read.
			for($i = 0; $i -lt $read; $i++) {
				[void] $out.Add($buf[$i])
			}
		}
		$p.WaitForExit()
		$p.Dispose()
		write-output -noEnumerate $out
	} catch {
		err "error reading output stream from the child process: $_"
	}
}

function :shim::conflicts {
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[string[]] $shim,

		[Parameter()]
		[Alphaleonis.Win32.Filesystem.KernelTransaction] $tx
	)

	begin {
		$list = [Collections.Generic.List[string]]::new()
	}

	process {
		foreach($s in $shim) {
			$name = split-path -leaf $s
			if(join-path $script:settings.bin $name | script::exists -tx:$tx ) {
				[void] $list.Add($name)
			}
		}
	}

	end {
		$list
	}
}

function :shim::is-running {
	[CmdletBinding()]
	[OutputType([string])]
	param (
		[Parameter(Mandatory, Position = 0, ValueFromPipeline)]
		[string[]] $shim
	)

	begin {
		$list = [Collections.Generic.List[string]]::new()
		$procs = get-process
	}

	process {
		foreach($s in $shim) {
			$name = split-path -leaf $s
			$path = join-path $script:settings.bin $name
			foreach($p in $procs) {
				if($p.path -eq $path) {
					[void] $list.add($path)
					break
				}
			}
		}
	}

	end {
		$list
	}
}
